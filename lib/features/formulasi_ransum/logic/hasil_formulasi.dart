import '../../../data/models/hasil_kecukupan_pakan.dart';

class RekomendasiPakanItem {
  final String namaBahan;
  final double jumlahKg;
  final String kategori;

  const RekomendasiPakanItem({
    required this.namaBahan,
    required this.jumlahKg,
    required this.kategori,
  });
}

class HasilFormulasi {
  final double persentaseHijauan;
  final double persentaseKonsentrat;
  final double bkRansumPersen;
  final List<RekomendasiPakanItem> rekomendasiPakan;
  final HasilEvaluasiKecukupan evaluasi;

  const HasilFormulasi({
    required this.persentaseHijauan,
    required this.persentaseKonsentrat,
    required this.bkRansumPersen,
    required this.rekomendasiPakan,
    required this.evaluasi,
  });
}
