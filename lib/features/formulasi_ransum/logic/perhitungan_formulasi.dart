import '../../../data/models/campuran_pakan_item.dart';
import '../../../data/models/profil_sapi.dart';
import '../../cek_kecukupan_pakan/logic/perhitungan_kecukupan_pakan.dart';
import 'hasil_formulasi.dart';

class PerhitunganFormulasi {
  static HasilFormulasi hitungFormulasi({
    required ProfilSapi sapi,
    required List<CampuranPakanItem> daftarBahan,
  }) {
    double totalBkHijauan = 0;
    double totalBkKonsentrat = 0;
    
    double totalBk = 0;
    double totalProtein = 0;
    double totalTdn = 0;
    double totalMe = 0;
    double totalFreshWeight = 0;
    for (var item in daftarBahan) {
      final pakan = item.bahan;
      final beratKg = item.jumlahKg;
      
      totalFreshWeight += beratKg;

      // Hitung Nutrisi
      final bkItem = (pakan.bk / 100) * beratKg;
      final proteinItem = (pakan.protein / 100) * bkItem;
      final tdnItem = (pakan.tdn / 100) * bkItem;
      final meItem = pakan.me * bkItem;
      
      totalBk += bkItem;
      totalProtein += proteinItem;
      totalTdn += tdnItem;
      totalMe += meItem;

      // Hitung Imbangan berdasar kategori
      final isHijauan = pakan.kategori.toLowerCase() == 'hijauan' || pakan.kategori.toLowerCase() == 'limbah';
      
      if (isHijauan) {
        totalBkHijauan += bkItem;
      } else {
        totalBkKonsentrat += bkItem;
      }
    }

    double bkRansumPersen = 0;
    if (totalFreshWeight > 0) {
      bkRansumPersen = (totalBk / totalFreshWeight) * 100;
    }
    
    // Limit max di angka 86 (pastikan hasil tidak melebihi angka ini)
    if (bkRansumPersen > 86) {
      bkRansumPersen = 86;
    }

    final evaluasi = PerhitunganKecukupanPakan.evaluasiManual(
      sapi: sapi,
      bkPemberianKg: totalBk,
      proteinPemberianKg: totalProtein,
      tdnPemberianKg: totalTdn,
      mePemberian: totalMe,
    );

    double persentaseHijauan = 0;
    double persentaseKonsentrat = 0;

    if (totalBk > 0) {
      persentaseHijauan = (totalBkHijauan / totalBk) * 100;
      persentaseKonsentrat = (totalBkKonsentrat / totalBk) * 100;
    }

    return HasilFormulasi(
      daftarBahan: daftarBahan,
      evaluasi: evaluasi,
      persentaseHijauan: persentaseHijauan,
      persentaseKonsentrat: persentaseKonsentrat,
      totalBkHijauan: totalBkHijauan,
      totalBkKonsentrat: totalBkKonsentrat,
      bkRansumPersen: bkRansumPersen,
    );
  }
}
