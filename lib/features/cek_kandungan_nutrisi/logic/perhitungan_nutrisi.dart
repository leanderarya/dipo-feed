import '../../../data/models/campuran_pakan_item.dart';

class HasilPerhitunganNutrisi {
  final double totalBerat;
  final double totalBiaya;
  final double hargaRataRata;
  final double bk;
  final double abu;
  final double lemak;
  final double serat;
  final double protein;
  final double tdn;
  final double me;

  const HasilPerhitunganNutrisi({
    required this.totalBerat,
    required this.totalBiaya,
    required this.hargaRataRata,
    required this.bk,
    required this.abu,
    required this.lemak,
    required this.serat,
    required this.protein,
    required this.tdn,
    required this.me,
  });
}

class PerhitunganNutrisi {
  static double hitungTotalBerat(List<CampuranPakanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.jumlahKg);
  }

  static double hitungTotalBiaya(List<CampuranPakanItem> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.jumlahKg * item.hargaPerKg),
    );
  }

  static double hitungHargaRataRata(List<CampuranPakanItem> items) {
    final totalBerat = hitungTotalBerat(items);
    if (totalBerat == 0) return 0;
    return hitungTotalBiaya(items) / totalBerat;
  }

  static double hitungPersentaseBahan(double jumlahKg, double totalBerat) {
    if (totalBerat == 0) return 0;
    return (jumlahKg / totalBerat) * 100;
  }

  static double hitungNutrisiCampuran(
    List<CampuranPakanItem> items,
    double Function(CampuranPakanItem item) selector,
  ) {
    final totalBerat = hitungTotalBerat(items);
    if (totalBerat == 0) return 0;

    double hasil = 0;
    for (final item in items) {
      final persentase = hitungPersentaseBahan(item.jumlahKg, totalBerat);
      hasil += (persentase * selector(item)) / 100;
    }
    return hasil;
  }

  static HasilPerhitunganNutrisi hitungSemua(List<CampuranPakanItem> items) {
    return HasilPerhitunganNutrisi(
      totalBerat: hitungTotalBerat(items),
      totalBiaya: hitungTotalBiaya(items),
      hargaRataRata: hitungHargaRataRata(items),
      bk: hitungNutrisiCampuran(items, (item) => item.bahan.bk),
      abu: hitungNutrisiCampuran(items, (item) => item.bahan.abu),
      lemak: hitungNutrisiCampuran(items, (item) => item.bahan.lemak),
      serat: hitungNutrisiCampuran(items, (item) => item.bahan.serat),
      protein: hitungNutrisiCampuran(items, (item) => item.bahan.protein),
      tdn: hitungNutrisiCampuran(items, (item) => item.bahan.tdn),
      me: hitungNutrisiCampuran(items, (item) => item.bahan.me),
    );
  }
}