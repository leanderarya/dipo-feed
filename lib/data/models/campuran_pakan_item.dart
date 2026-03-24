import 'bahan_pakan.dart';

class CampuranPakanItem {
  final BahanPakan bahan;
  double jumlahKg;
  double hargaPerKg;

  CampuranPakanItem({
    required this.bahan,
    required this.jumlahKg,
    required this.hargaPerKg,
  });

  CampuranPakanItem copyWith({
    BahanPakan? bahan,
    double? jumlahKg,
    double? hargaPerKg,
  }) {
    return CampuranPakanItem(
      bahan: bahan ?? this.bahan,
      jumlahKg: jumlahKg ?? this.jumlahKg,
      hargaPerKg: hargaPerKg ?? this.hargaPerKg,
    );
  }
}