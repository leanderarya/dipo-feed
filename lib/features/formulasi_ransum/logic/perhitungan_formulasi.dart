import '../../../data/models/campuran_pakan_item.dart';
import '../../../data/models/hasil_kecukupan_pakan.dart';
import '../../../data/models/profil_sapi.dart';
import 'hasil_formulasi.dart';

class PerhitunganFormulasi {
  static HasilFormulasi hitungFormulasi({
    required ProfilSapi sapi,
    required List<CampuranPakanItem> daftarBahanTerpilih,
  }) {
    final targetHijauan = sapi.produksiSusu >= 15 ? 60.0 : 70.0;
    final targetKonsentrat = 100.0 - targetHijauan;

    final List<RekomendasiPakanItem> rekomendasi = [];

    for (final item in daftarBahanTerpilih) {
      if (item.bahan.bk <= 0) continue;
      rekomendasi.add(RekomendasiPakanItem(
        namaBahan: item.bahan.nama,
        jumlahKg: 0,
        kategori: 'konsentrat',
      ));
    }

    return HasilFormulasi(
      persentaseHijauan: targetHijauan,
      persentaseKonsentrat: targetKonsentrat,
      bkRansumPersen: 100,
      rekomendasiPakan: rekomendasi,
      evaluasi: const HasilEvaluasiKecukupan(
        bk: DetailEvaluasiNutrisi(kebutuhan: 10, pemberian: 10, selisih: 0),
        protein: DetailEvaluasiNutrisi(kebutuhan: 1, pemberian: 1, selisih: 0),
        tdn: DetailEvaluasiNutrisi(kebutuhan: 6, pemberian: 6, selisih: 0),
        me: DetailEvaluasiNutrisi(kebutuhan: 60, pemberian: 60, selisih: 0),
      ),
    );
  }
}