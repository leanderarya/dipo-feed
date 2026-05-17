import '../../../data/models/fisiologi_sapi.dart';

class StandarNutrienPakan {
  final String nama;
  final double proteinTarget;
  final double lemakMaks;
  final double caMin;
  final double caMax;
  final double pMin;
  final double pMax;
  final double tdnMin;
  final double bkMaks;

  const StandarNutrienPakan({
    required this.nama,
    required this.proteinTarget,
    required this.lemakMaks,
    required this.caMin,
    required this.caMax,
    required this.pMin,
    required this.pMax,
    required this.tdnMin,
    required this.bkMaks,
  });
}

class StandarNutrienHelper {
  static const StandarNutrienPakan _laktasiTengah = StandarNutrienPakan(
    nama: 'Laktasi',
    proteinTarget: 16,
    lemakMaks: 7,
    caMin: 0.6,
    caMax: 1.2,
    pMin: 0.4,
    pMax: 0.8,
    tdnMin: 68,
    bkMaks: 86,
  );

  static const StandarNutrienPakan _keringKandang = StandarNutrienPakan(
    nama: 'Kering Kandang',
    proteinTarget: 16,
    lemakMaks: 7,
    caMin: 0.8,
    caMax: 1.3,
    pMin: 0.4,
    pMax: 0.8,
    tdnMin: 68,
    bkMaks: 86,
  );

  static const StandarNutrienPakan _dara = StandarNutrienPakan(
    nama: 'Dara',
    proteinTarget: 15,
    lemakMaks: 7,
    caMin: 0.6,
    caMax: 1.0,
    pMin: 0.4,
    pMax: 0.8,
    tdnMin: 70,
    bkMaks: 86,
  );

  static StandarNutrienPakan getByFisiologi(FisiologiSapi fisiologi) {
    switch (fisiologi) {
      case FisiologiSapi.dara:
        return _dara;
      case FisiologiSapi.laktasi:
        return _laktasiTengah;
      case FisiologiSapi.keringKandang:
        return _keringKandang;
    }
  }
}
