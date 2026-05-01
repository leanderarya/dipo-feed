import '../../../data/models/bahan_pakan.dart';
import 'hasil_rekomendasi_pakan.dart';

class NutrienHelper {
  static KontribusiNutrien hitungKontribusi({
    required BahanPakan bahan,
    required double asFedKg,
  }) {
    final bkKg = asFedKg * (bahan.bk / 100);
    // Kandungan nutrien bahan dibaca sebagai basis BK,
    // jadi seluruh kontribusi selain BK dihitung dari BK aktual bahan.
    final pkKg = bkKg * (bahan.protein / 100);
    final tdnKg = bkKg * (bahan.tdn / 100);
    final abuKg = bkKg * (bahan.abu / 100);
    // TODO: Saat data Ca/P bahan sudah dipastikan standar satuannya,
    // sesuaikan rumus ini bila tidak memakai basis persen BK.
    final caGram = bkKg * (bahan.ca / 100) * 1000;
    final pGram = bkKg * (bahan.p / 100) * 1000;
    final lkKg = bkKg * (bahan.lemak / 100);
    final skKg = bkKg * (bahan.serat / 100);
    final betnKg = bkKg * (bahan.betn / 100);

    return KontribusiNutrien(
      bkKg: bkKg,
      pkKg: pkKg,
      tdnKg: tdnKg,
      caGram: caGram,
      pGram: pGram,
      abuKg: abuKg,
      lkKg: lkKg,
      skKg: skKg,
      betnKg: betnKg,
    );
  }

  static double hitungLkPersenDariBk(KontribusiNutrien kontribusi) {
    if (kontribusi.bkKg <= 0) return 0;
    return (kontribusi.lkKg / kontribusi.bkKg) * 100;
  }

  static double hitungErrorRelatif(double hasil, double target) {
    final denominator = target == 0 ? 1 : target.abs();
    return (hasil - target).abs() / denominator;
  }

  static String statusNutrien({
    required double hasil,
    required double target,
  }) {
    if (target == 0) return 'Pas';
    final selisihRelatif = (hasil - target) / target;
    if (selisihRelatif.abs() <= 0.05) return 'Pas';
    return hasil < target ? 'Kurang' : 'Berlebih';
  }
}
