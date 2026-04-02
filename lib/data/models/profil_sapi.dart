enum StatusKebuntingan { tidakBunting, bunting }

enum TahapLaktasi {
  dara,
  keringKandang,
  laktasi0Sampai4Minggu,
  laktasi4Sampai16Minggu,
  laktasi16Sampai30Minggu,
  laktasi30Sampai44Minggu,
}

class ProfilSapi {
  final double beratBadan;
  final double produksiSusu;
  final double persenLemakSusu;
  final int paritas;
  final TahapLaktasi tahapLaktasi;
  final StatusKebuntingan statusKebuntingan;
  final int bulanBunting;

  const ProfilSapi({
    required this.beratBadan,
    required this.produksiSusu,
    required this.persenLemakSusu,
    required this.paritas,
    required this.tahapLaktasi,
    required this.statusKebuntingan,
    required this.bulanBunting,
  });
}