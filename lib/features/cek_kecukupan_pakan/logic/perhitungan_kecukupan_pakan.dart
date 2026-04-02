import '../../../data/models/hasil_kecukupan_pakan.dart';
import '../../../data/models/profil_sapi.dart';

class PerhitunganKecukupanPakan {
  // ===============================
  // BK BERDASARKAN FASE FISIOLOGIS
  // ===============================
  static double hitungPersenBkBerdasarkanTahap(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.dara:
        return 2.5;
      case TahapLaktasi.keringKandang:
        return 2.0;
      case TahapLaktasi.laktasi0Sampai4Minggu:
        return 3.0;
      case TahapLaktasi.laktasi4Sampai16Minggu:
        return 4.0;
      case TahapLaktasi.laktasi16Sampai30Minggu:
        return 3.5;
      case TahapLaktasi.laktasi30Sampai44Minggu:
        return 3.0;
    }
  }

  // ===============================
  // STANDAR PROTEIN BERDASARKAN FASE
  // ===============================
  static double getPersentaseProteinStandar(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.dara:
        return 0.15; // 15% dari BK
      case TahapLaktasi.keringKandang:
        return 0.16; // 16% dari BK
      case TahapLaktasi.laktasi0Sampai4Minggu:
        return 0.18; // 18% dari BK
      case TahapLaktasi.laktasi4Sampai16Minggu:
        return 0.18; // 18% dari BK
      case TahapLaktasi.laktasi16Sampai30Minggu:
        return 0.16; // 16% dari BK
      case TahapLaktasi.laktasi30Sampai44Minggu:
        return 0.14; // 14% dari BK
    }
  }

  // ===============================
  // STANDAR TDN BERDASARKAN FASE
  // ===============================
  static double getPersentaseTdnStandar(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.dara:
        return 0.70; // 70% dari BK
      case TahapLaktasi.keringKandang:
        return 0.68; // 68% dari BK
      case TahapLaktasi.laktasi0Sampai4Minggu:
        return 0.68;
      case TahapLaktasi.laktasi4Sampai16Minggu:
        return 0.68;
      case TahapLaktasi.laktasi16Sampai30Minggu:
        return 0.68;
      case TahapLaktasi.laktasi30Sampai44Minggu:
        return 0.68;
    }
  }

  // ===============================
  // KEBUTUHAN BK
  // ===============================
  static double hitungKebutuhanBkKg(ProfilSapi sapi) {
    final persenBk = hitungPersenBkBerdasarkanTahap(sapi.tahapLaktasi);
    return (persenBk / 100) * sapi.beratBadan;
  }

  // ===============================
  // KEBUTUHAN ENERGI HIDUP POKOK
  // ===============================
  static double hitungEnergiHidupPokok(ProfilSapi sapi) {
    return 0.11 * sapi.beratBadan;
  }

  // ===============================
  // KEBUTUHAN ENERGI PRODUKSI SUSU
  // ===============================
  static double hitungEnergiProduksiSusu(ProfilSapi sapi) {
    return sapi.produksiSusu * 7.5;
  }

  // ===============================
  // KEBUTUHAN ENERGI KEBUNTINGAN
  // ===============================
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

  // ===============================
  // TOTAL KEBUTUHAN ME
  // ===============================
  static double hitungKebutuhanMe(ProfilSapi sapi) {
    return hitungEnergiHidupPokok(sapi) +
        hitungEnergiProduksiSusu(sapi) +
        hitungEnergiKebuntingan(sapi);
  }

  // ===============================
  // KEBUTUHAN PROTEIN
  // pendekatan: % standar protein x kebutuhan BK
  // ===============================
  static double hitungKebutuhanProtein(ProfilSapi sapi) {
    final persenProtein = getPersentaseProteinStandar(sapi.tahapLaktasi);
    return hitungKebutuhanBkKg(sapi) * persenProtein;
  }

  // ===============================
  // KEBUTUHAN TDN
  // pendekatan: % standar TDN x kebutuhan BK
  // ===============================
  static double hitungKebutuhanTdn(ProfilSapi sapi) {
    final persenTdn = getPersentaseTdnStandar(sapi.tahapLaktasi);
    return hitungKebutuhanBkKg(sapi) * persenTdn;
  }

  // ===============================
  // RINGKASAN KEBUTUHAN
  // ===============================
  static KebutuhanNutrisiSapi hitungKebutuhan(ProfilSapi sapi) {
    return KebutuhanNutrisiSapi(
      kebutuhanBkKg: hitungKebutuhanBkKg(sapi),
      kebutuhanMe: hitungKebutuhanMe(sapi),
      kebutuhanProtein: hitungKebutuhanProtein(sapi),
      kebutuhanTdn: hitungKebutuhanTdn(sapi),
    );
  }

  // ===============================
  // EVALUASI MANUAL
  // ===============================
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
}