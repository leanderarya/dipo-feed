import '../../../data/models/campuran_pakan_item.dart';
import '../../../data/models/hasil_kecukupan_pakan.dart';

class HasilFormulasi {
  final List<CampuranPakanItem> daftarBahan;
  final HasilEvaluasiKecukupan evaluasi;
  final double persentaseHijauan;
  final double persentaseKonsentrat;
  final double totalBkHijauan;
  final double totalBkKonsentrat;
  final double bkRansumPersen;

  const HasilFormulasi({
    required this.daftarBahan,
    required this.evaluasi,
    required this.persentaseHijauan,
    required this.persentaseKonsentrat,
    required this.totalBkHijauan,
    required this.totalBkKonsentrat,
    required this.bkRansumPersen,
  });
}
