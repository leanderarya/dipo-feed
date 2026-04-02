import '../../../data/models/campuran_pakan_item.dart';
import '../../../data/models/profil_sapi.dart';
import '../../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import '../../cek_kecukupan_pakan/logic/perhitungan_kecukupan_pakan.dart';
import 'hasil_formulasi.dart';

class PerhitunganFormulasi {
  static HasilFormulasi hitungFormulasi({
    required ProfilSapi sapi,
    required List<CampuranPakanItem> daftarBahanTerpilih,
  }) {
    final kebutuhan = PerhitunganKecukupanPakan.hitungKebutuhan(sapi);

    final bahanHijauan = daftarBahanTerpilih
        .where((item) => _isHijauan(item.bahan.kategori))
        .toList();

    final bahanKonsentrat = daftarBahanTerpilih
        .where((item) => _isKonsentrat(item.bahan.kategori))
        .toList();

    final targetHijauan = sapi.produksiSusu >= 15 ? 60.0 : 70.0;
    final targetKonsentrat = 100.0 - targetHijauan;

    final targetBkHijauan = kebutuhan.kebutuhanBkKg * (targetHijauan / 100);
    final targetBkKonsentrat =
        kebutuhan.kebutuhanBkKg * (targetKonsentrat / 100);

    final List<CampuranPakanItem> hasilCampuran = [];
    final List<RekomendasiPakanItem> rekomendasi = [];

    if (bahanHijauan.isNotEmpty) {
      final bkPerHijauan = targetBkHijauan / bahanHijauan.length;

      for (final item in bahanHijauan) {
        final double bkBahan = item.bahan.bk / 100.0;
        final double jumlahSegar = bkBahan == 0 ? 0.0 : bkPerHijauan / bkBahan;

        hasilCampuran.add(
          CampuranPakanItem(
            bahan: item.bahan,
            jumlahKg: jumlahSegar,
            hargaPerKg: item.bahan.hargaDefault,
          ),
        );

        rekomendasi.add(
          RekomendasiPakanItem(
            namaBahan: item.bahan.nama,
            jumlahKg: jumlahSegar,
            kategori: item.bahan.kategori,
          ),
        );
      }
    }

    if (bahanKonsentrat.isNotEmpty) {
      final bkPerKonsentrat = targetBkKonsentrat / bahanKonsentrat.length;

      for (final item in bahanKonsentrat) {
        final double bkBahan = item.bahan.bk / 100.0;
        final double jumlahSegar = bkBahan == 0
            ? 0.0
            : bkPerKonsentrat / bkBahan;

        hasilCampuran.add(
          CampuranPakanItem(
            bahan: item.bahan,
            jumlahKg: jumlahSegar,
            hargaPerKg: item.bahan.hargaDefault,
          ),
        );

        rekomendasi.add(
          RekomendasiPakanItem(
            namaBahan: item.bahan.nama,
            jumlahKg: jumlahSegar,
            kategori: item.bahan.kategori,
          ),
        );
      }
    }

    final hasilNutrisi = PerhitunganNutrisi.hitungSemua(hasilCampuran);

    final bkPemberianKg = hasilNutrisi.totalBerat * (hasilNutrisi.bk / 100);
    final proteinPemberianKg =
        hasilNutrisi.totalBerat * (hasilNutrisi.protein / 100);
    final tdnPemberianKg = hasilNutrisi.totalBerat * (hasilNutrisi.tdn / 100);
    final mePemberian = hasilNutrisi.totalBerat * hasilNutrisi.me;

    final evaluasi = PerhitunganKecukupanPakan.evaluasiManual(
      sapi: sapi,
      bkPemberianKg: bkPemberianKg,
      proteinPemberianKg: proteinPemberianKg,
      tdnPemberianKg: tdnPemberianKg,
      mePemberian: mePemberian,
    );

    return HasilFormulasi(
      persentaseHijauan: targetHijauan,
      persentaseKonsentrat: targetKonsentrat,
      bkRansumPersen: hasilNutrisi.bk,
      rekomendasiPakan: rekomendasi,
      evaluasi: evaluasi,
    );
  }

  static bool _isHijauan(String kategori) {
    final kategoriLower = kategori.toLowerCase();
    return kategoriLower.contains('hijauan') ||
        kategoriLower.contains('forage') ||
        kategoriLower.contains('rumput');
  }

  static bool _isKonsentrat(String kategori) {
    final kategoriLower = kategori.toLowerCase();
    return kategoriLower.contains('konsentrat') ||
        kategoriLower.contains('konsentrat/protein') ||
        kategoriLower.contains('energi') ||
        kategoriLower.contains('protein');
  }
}
