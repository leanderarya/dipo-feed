import '../../../data/models/hasil_kecukupan_pakan.dart';
import '../../../data/models/hasil_pakan_terpilih.dart';
import '../../../data/models/profil_sapi.dart';

class PerhitunganKecukupanPakan {
  static double hitungPersenBkBerdasarkanTahap(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.keringKandang:
        return 2.0;
      case TahapLaktasi.awalLaktasiMinggu0sampai4:
        return 3.0;
      case TahapLaktasi.awalLaktasiMinggu4sampai16:
        return 4.0;
      case TahapLaktasi.tengahLaktasiMinggu16sampai30:
        return 3.5;
      case TahapLaktasi.akhirLaktasiMinggu30sampai44:
        return 3.0;
    }
  }

  static double hitungKebutuhanBkKg(ProfilSapi sapi) {
    final persenBk = hitungPersenBkBerdasarkanTahap(sapi.tahapLaktasi);
    return (persenBk / 100) * sapi.beratBadan;
  }

  static double hitungEnergiHidupPokok(ProfilSapi sapi) {
    return 0.11 * sapi.beratBadan;
  }

  static double hitungEnergiProduksiSusu(ProfilSapi sapi) {
    return sapi.produksiSusu * 7.5;
  }

  static double hitungEnergiKebuntingan(ProfilSapi sapi) {
    if (sapi.statusKebuntingan == StatusKebuntingan.tidakBunting) {
      return 0;
    }

    if (sapi.bulanBunting < 6) return 0;
    if (sapi.bulanBunting == 6) return 6;
    if (sapi.bulanBunting == 7) return 8;
    if (sapi.bulanBunting == 8) return 15;
    if (sapi.bulanBunting >= 9) return 27;

    return 0;
  }

  static double hitungKebutuhanMe(ProfilSapi sapi) {
    return hitungEnergiHidupPokok(sapi) +
        hitungEnergiProduksiSusu(sapi) +
        hitungEnergiKebuntingan(sapi);
  }

  static double hitungKebutuhanProtein(ProfilSapi sapi) {
    return hitungKebutuhanBkKg(sapi) * 0.12;
  }

  static double hitungKebutuhanTdn(ProfilSapi sapi) {
    return hitungKebutuhanBkKg(sapi) * 0.65;
  }

  static KebutuhanNutrisiSapi hitungKebutuhan(ProfilSapi sapi) {
    return KebutuhanNutrisiSapi(
      kebutuhanBkKg: hitungKebutuhanBkKg(sapi),
      kebutuhanMe: hitungKebutuhanMe(sapi),
      kebutuhanProtein: hitungKebutuhanProtein(sapi),
      kebutuhanTdn: hitungKebutuhanTdn(sapi),
    );
  }

  static HasilEvaluasiKecukupan evaluasiManual({
    required ProfilSapi sapi,
    required double bkPemberianKg,
    required double proteinPemberianKg,
    required double tdnPemberianKg,
    required double mePemberian,
  }) {
    final kebutuhan = hitungKebutuhan(sapi);

    return HasilEvaluasiKecukupan(
      bk: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanBkKg,
        pemberian: bkPemberianKg,
        selisih: bkPemberianKg - kebutuhan.kebutuhanBkKg,
      ),
      protein: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanProtein,
        pemberian: proteinPemberianKg,
        selisih: proteinPemberianKg - kebutuhan.kebutuhanProtein,
      ),
      tdn: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanTdn,
        pemberian: tdnPemberianKg,
        selisih: tdnPemberianKg - kebutuhan.kebutuhanTdn,
      ),
      me: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanMe,
        pemberian: mePemberian,
        selisih: mePemberian - kebutuhan.kebutuhanMe,
      ),
    );
  }

  static HasilEvaluasiKecukupan evaluasiDariHasilPakan({
    required ProfilSapi sapi,
    required HasilPakanTerpilih hasilPakan,
  }) {
    final kebutuhan = hitungKebutuhan(sapi);

    return HasilEvaluasiKecukupan(
      bk: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanBkKg,
        pemberian: hasilPakan.bkKg,
        selisih: hasilPakan.bkKg - kebutuhan.kebutuhanBkKg,
      ),
      protein: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanProtein,
        pemberian: hasilPakan.proteinKg,
        selisih: hasilPakan.proteinKg - kebutuhan.kebutuhanProtein,
      ),
      tdn: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanTdn,
        pemberian: hasilPakan.tdnKg,
        selisih: hasilPakan.tdnKg - kebutuhan.kebutuhanTdn,
      ),
      me: DetailEvaluasiNutrisi(
        kebutuhan: kebutuhan.kebutuhanMe,
        pemberian: hasilPakan.meTotal,
        selisih: hasilPakan.meTotal - kebutuhan.kebutuhanMe,
      ),
    );
  }
}