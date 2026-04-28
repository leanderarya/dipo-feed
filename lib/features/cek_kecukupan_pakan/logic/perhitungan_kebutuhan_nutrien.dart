import '../../../data/models/fisiologi_sapi.dart';
import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import 'interpolasi_linear.dart';
import 'perhitungan_kebutuhan_kering_kandang.dart';
import 'perhitungan_kebutuhan_laktasi_nrc_1988.dart';
import 'tabel_kebutuhan_dara_nrc_1978.dart';

class PerhitunganKebutuhanNutrien {
  static KebutuhanNutrienSapi? hitungKebutuhan({
    required FisiologiSapi fisiologi,
    required double beratBadan,
    double? produksiSusuLiter,
    double? lemakSusuPersen,
  }) {
    switch (fisiologi) {
      case FisiologiSapi.dara:
        return hitungKebutuhanDaraNrc1978(beratBadan);
      case FisiologiSapi.laktasi:
        if (produksiSusuLiter == null || lemakSusuPersen == null) {
          return null;
        }
        return PerhitunganKebutuhanLaktasiNrc1988.hitung(
          beratBadan: beratBadan,
          produksiSusuLiter: produksiSusuLiter,
          lemakSusuPersen: lemakSusuPersen,
        );
      case FisiologiSapi.keringKandang:
        return PerhitunganKebutuhanKeringKandang
            .hitungKebutuhanKeringKandang(beratBadan);
    }
  }

  static KebutuhanNutrienSapi hitungKebutuhanDaraNrc1978(double bb) {
    final titik = _pilihTitikReferensi(bb);
    final titikBawah = titik.$1;
    final titikAtas = titik.$2;

    if (bb == titikBawah.bb) {
      return _mapKeModel(titikBawah);
    }

    if (bb == titikAtas.bb) {
      return _mapKeModel(titikAtas);
    }

    final bkKg = _interpolasi(
      x: bb,
      x1: titikBawah.bb,
      y1: titikBawah.bkKg,
      x2: titikAtas.bb,
      y2: titikAtas.bkKg,
    );
    final tdnKg = _interpolasi(
      x: bb,
      x1: titikBawah.bb,
      y1: titikBawah.tdnKg,
      x2: titikAtas.bb,
      y2: titikAtas.tdnKg,
    );
    final pkGram = _interpolasi(
      x: bb,
      x1: titikBawah.bb,
      y1: titikBawah.pkGram,
      x2: titikAtas.bb,
      y2: titikAtas.pkGram,
    );
    final caGram = _interpolasi(
      x: bb,
      x1: titikBawah.bb,
      y1: titikBawah.caGram,
      x2: titikAtas.bb,
      y2: titikAtas.caGram,
    );
    final pGram = _interpolasi(
      x: bb,
      x1: titikBawah.bb,
      y1: titikBawah.pGram,
      x2: titikAtas.bb,
      y2: titikAtas.pGram,
    );

    return KebutuhanNutrienSapi(
      kebutuhanBkKg: bkKg,
      kebutuhanProteinKg: pkGram / 1000,
      kebutuhanTdnKg: tdnKg,
      kebutuhanCaGram: caGram,
      kebutuhanPGram: pGram,
    );
  }

  static (DataKebutuhanDara, DataKebutuhanDara) _pilihTitikReferensi(
    double bb,
  ) {
    if (bb <= tabelKebutuhanDaraNrc1978.first.bb) {
      return (
        tabelKebutuhanDaraNrc1978[0],
        tabelKebutuhanDaraNrc1978[1],
      );
    }

    if (bb >= tabelKebutuhanDaraNrc1978.last.bb) {
      return (
        tabelKebutuhanDaraNrc1978[tabelKebutuhanDaraNrc1978.length - 2],
        tabelKebutuhanDaraNrc1978.last,
      );
    }

    for (var i = 0; i < tabelKebutuhanDaraNrc1978.length - 1; i++) {
      final bawah = tabelKebutuhanDaraNrc1978[i];
      final atas = tabelKebutuhanDaraNrc1978[i + 1];

      if (bb >= bawah.bb && bb <= atas.bb) {
        return (bawah, atas);
      }
    }

    return (
      tabelKebutuhanDaraNrc1978[0],
      tabelKebutuhanDaraNrc1978[1],
    );
  }

  static KebutuhanNutrienSapi _mapKeModel(DataKebutuhanDara data) {
    return KebutuhanNutrienSapi(
      kebutuhanBkKg: data.bkKg,
      kebutuhanProteinKg: data.pkGram / 1000,
      kebutuhanTdnKg: data.tdnKg,
      kebutuhanCaGram: data.caGram,
      kebutuhanPGram: data.pGram,
    );
  }

  static double _interpolasi({
    required double x,
    required double x1,
    required double y1,
    required double x2,
    required double y2,
  }) {
    return interpolasiLinear(
      x: x,
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
    );
  }
}
