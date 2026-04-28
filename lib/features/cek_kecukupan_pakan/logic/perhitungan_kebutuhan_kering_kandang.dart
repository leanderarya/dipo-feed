import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import 'interpolasi_linear.dart';

class DataKebutuhanKeringKandang {
  final double bb;
  final double tdnKg;
  final double proteinGram;
  final double caGram;
  final double pGram;

  const DataKebutuhanKeringKandang({
    required this.bb,
    required this.tdnKg,
    required this.proteinGram,
    required this.caGram,
    required this.pGram,
  });
}

class PerhitunganKebutuhanKeringKandang {
  static const List<DataKebutuhanKeringKandang> _tabel = [
    DataKebutuhanKeringKandang(
      bb: 300,
      tdnKg: 3.39,
      proteinGram: 769,
      caGram: 18,
      pGram: 12,
    ),
    DataKebutuhanKeringKandang(
      bb: 350,
      tdnKg: 3.77,
      proteinGram: 822,
      caGram: 22,
      pGram: 14,
    ),
    DataKebutuhanKeringKandang(
      bb: 400,
      tdnKg: 4.15,
      proteinGram: 875,
      caGram: 26,
      pGram: 16,
    ),
    DataKebutuhanKeringKandang(
      bb: 450,
      tdnKg: 4.53,
      proteinGram: 928,
      caGram: 30,
      pGram: 18,
    ),
    DataKebutuhanKeringKandang(
      bb: 500,
      tdnKg: 4.90,
      proteinGram: 978,
      caGram: 33,
      pGram: 20,
    ),
    DataKebutuhanKeringKandang(
      bb: 550,
      tdnKg: 5.27,
      proteinGram: 1027,
      caGram: 36,
      pGram: 22,
    ),
  ];

  static KebutuhanNutrienSapi hitungKebutuhanKeringKandang(double bb) {
    // BK kering kandang tidak berasal dari tabel; nilainya tetap 2% dari BB.
    final kebutuhanBkKg = 0.02 * bb;
    final titik = _pilihTitikReferensi(bb);
    final bawah = titik.$1;
    final atas = titik.$2;

    if (bb == bawah.bb) {
      return _mapKeModel(data: bawah, kebutuhanBkKg: kebutuhanBkKg);
    }

    if (bb == atas.bb) {
      return _mapKeModel(data: atas, kebutuhanBkKg: kebutuhanBkKg);
    }

    final tdnKg = interpolasiLinear(
      x: bb,
      x1: bawah.bb,
      y1: bawah.tdnKg,
      x2: atas.bb,
      y2: atas.tdnKg,
    );
    final proteinGram = interpolasiLinear(
      x: bb,
      x1: bawah.bb,
      y1: bawah.proteinGram,
      x2: atas.bb,
      y2: atas.proteinGram,
    );
    final caGram = interpolasiLinear(
      x: bb,
      x1: bawah.bb,
      y1: bawah.caGram,
      x2: atas.bb,
      y2: atas.caGram,
    );
    final pGram = interpolasiLinear(
      x: bb,
      x1: bawah.bb,
      y1: bawah.pGram,
      x2: atas.bb,
      y2: atas.pGram,
    );

    return KebutuhanNutrienSapi(
      kebutuhanBkKg: kebutuhanBkKg,
      kebutuhanProteinKg: proteinGram / 1000,
      kebutuhanTdnKg: tdnKg,
      kebutuhanCaGram: caGram,
      kebutuhanPGram: pGram,
    );
  }

  static (DataKebutuhanKeringKandang, DataKebutuhanKeringKandang)
      _pilihTitikReferensi(double bb) {
    if (bb <= _tabel.first.bb) {
      return (_tabel[0], _tabel[1]);
    }

    if (bb >= _tabel.last.bb) {
      return (_tabel[_tabel.length - 2], _tabel.last);
    }

    for (var i = 0; i < _tabel.length - 1; i++) {
      final bawah = _tabel[i];
      final atas = _tabel[i + 1];

      if (bb >= bawah.bb && bb <= atas.bb) {
        return (bawah, atas);
      }
    }

    return (_tabel[0], _tabel[1]);
  }

  static KebutuhanNutrienSapi _mapKeModel({
    required DataKebutuhanKeringKandang data,
    required double kebutuhanBkKg,
  }) {
    return KebutuhanNutrienSapi(
      kebutuhanBkKg: kebutuhanBkKg,
      kebutuhanProteinKg: data.proteinGram / 1000,
      kebutuhanTdnKg: data.tdnKg,
      kebutuhanCaGram: data.caGram,
      kebutuhanPGram: data.pGram,
    );
  }
}
