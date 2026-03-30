enum StatusKebuntingan { tidakBunting, bunting }

enum TahapLaktasi {
  laktasiAwal,
  laktasiTengah,
  laktasiAkhir,
  keringKandang,
  dara,
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