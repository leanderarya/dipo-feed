import '../../../data/models/fisiologi_sapi.dart';
import 'narasi_evaluasi_standar.dart';
import 'perhitungan_nutrisi.dart';
import 'standar_nutrien_pakan.dart';

enum StatusStandarNutrien { kurang, sesuai, berlebih }

class EvaluasiStandarNutrienItem {
  final String label;
  final double hasil;
  final String standar;
  final StatusStandarNutrien status;

  const EvaluasiStandarNutrienItem({
    required this.label,
    required this.hasil,
    required this.standar,
    required this.status,
  });
}

class HasilEvaluasiStandarNutrien {
  final StandarNutrienPakan standar;
  final List<EvaluasiStandarNutrienItem> items;
  final List<String> narasi;
  final String kesimpulan;

  const HasilEvaluasiStandarNutrien({
    required this.standar,
    required this.items,
    required this.narasi,
    required this.kesimpulan,
  });
}

class EvaluasiStandarNutrienHelper {
  static const _proteinTolerance = 1.0;
  static const _tdnToleranceAtas = 4.0;

  static HasilEvaluasiStandarNutrien evaluasi({
    required HasilPerhitunganNutrisi hasil,
    required FisiologiSapi fisiologi,
  }) {
    final standar = StandarNutrienHelper.getByFisiologi(fisiologi);

    final items = [
      EvaluasiStandarNutrienItem(
        label: 'BK',
        hasil: hasil.bk,
        standar: 'maks ${standar.bkMaks.toStringAsFixed(0)}%',
        status: hasil.bk > standar.bkMaks
            ? StatusStandarNutrien.berlebih
            : StatusStandarNutrien.sesuai,
      ),
      EvaluasiStandarNutrienItem(
        label: 'Protein',
        hasil: hasil.protein,
        standar: '${standar.proteinTarget.toStringAsFixed(0)}%',
        status: _nilaiTarget(
          hasil.protein,
          target: standar.proteinTarget,
          tolerance: _proteinTolerance,
        ),
      ),
      EvaluasiStandarNutrienItem(
        label: 'Lemak',
        hasil: hasil.lemak,
        standar: 'maks ${standar.lemakMaks.toStringAsFixed(0)}%',
        status: hasil.lemak > standar.lemakMaks
            ? StatusStandarNutrien.berlebih
            : StatusStandarNutrien.sesuai,
      ),
      EvaluasiStandarNutrienItem(
        label: 'TDN',
        hasil: hasil.tdn,
        standar: 'min ${standar.tdnMin.toStringAsFixed(0)}%',
        status: _nilaiMinimum(
          hasil.tdn,
          min: standar.tdnMin,
          maxSesuai: standar.tdnMin + _tdnToleranceAtas,
        ),
      ),
      EvaluasiStandarNutrienItem(
        label: 'Ca',
        hasil: hasil.ca,
        standar:
            '${standar.caMin.toStringAsFixed(1)}–${standar.caMax.toStringAsFixed(1)}%',
        status: _nilaiRentang(
          hasil.ca,
          min: standar.caMin,
          max: standar.caMax,
        ),
      ),
      EvaluasiStandarNutrienItem(
        label: 'P',
        hasil: hasil.p,
        standar:
            '${standar.pMin.toStringAsFixed(1)}–${standar.pMax.toStringAsFixed(1)}%',
        status: _nilaiRentang(
          hasil.p,
          min: standar.pMin,
          max: standar.pMax,
        ),
      ),
    ];

    return HasilEvaluasiStandarNutrien(
      standar: standar,
      items: items,
      narasi: NarasiEvaluasiStandarGenerator.buatNarasi(
        fisiologi: fisiologi,
        items: items,
      ),
      kesimpulan: NarasiEvaluasiStandarGenerator.buatKesimpulan(
        fisiologi: fisiologi,
        items: items,
      ),
    );
  }

  static StatusStandarNutrien _nilaiTarget(
    double nilai, {
    required double target,
    required double tolerance,
  }) {
    if (nilai < target - tolerance) return StatusStandarNutrien.kurang;
    if (nilai > target + tolerance) return StatusStandarNutrien.berlebih;
    return StatusStandarNutrien.sesuai;
  }

  static StatusStandarNutrien _nilaiMinimum(
    double nilai, {
    required double min,
    required double maxSesuai,
  }) {
    if (nilai < min) return StatusStandarNutrien.kurang;
    if (nilai > maxSesuai) return StatusStandarNutrien.berlebih;
    return StatusStandarNutrien.sesuai;
  }

  static StatusStandarNutrien _nilaiRentang(
    double nilai, {
    required double min,
    required double max,
  }) {
    if (nilai < min) return StatusStandarNutrien.kurang;
    if (nilai > max) return StatusStandarNutrien.berlebih;
    return StatusStandarNutrien.sesuai;
  }
}
