import '../../../data/models/bahan_pakan.dart';
import 'hasil_rekomendasi_pakan.dart';

bool isBahanHijauan(BahanPakan bahan, Set<int> hijauanIds) =>
    hijauanIds.contains(bahan.id);

bool isBahanKonsentrat(BahanPakan bahan, Set<int> hijauanIds) =>
    !hijauanIds.contains(bahan.id);

/// Helper untuk perhitungan nutrien di algoritma rekomendasi pakan.
class NutrienHelper {
  static double hitungLkPersenDariBk(KontribusiNutrien kontribusi) {
    if (kontribusi.bkKg <= 0) return 0;
    return (kontribusi.lkKg / kontribusi.bkKg) * 100;
  }

  static KontribusiNutrien hitungKontribusi({
    required BahanPakan bahan,
    required double asFedKg,
  }) {
    final bkPct = bahan.bk / 100;
    final bkKg = asFedKg * bkPct;
    return KontribusiNutrien(
      bkKg: bkKg,
      pkKg: bkKg * (bahan.protein / 100),
      tdnKg: bkKg * (bahan.tdn / 100),
      caGram: bkKg * (bahan.ca / 100) * 1000,
      pGram: bkKg * (bahan.p / 100) * 1000,
      lkKg: bkKg * (bahan.lemak / 100),
      abuKg: bkKg * (bahan.abu / 100),
      skKg: bkKg * (bahan.serat / 100),
      betnKg: bkKg * (bahan.betn / 100),
    );
  }

  static double hitungErrorRelatif(double hasil, double target) {
    if (target <= 0) return hasil <= 0 ? 0 : 1;
    return ((hasil - target) / target).abs();
  }

  static String statusNutrien({
    required double hasil,
    required double target,
  }) {
    if (target <= 0) return hasil <= 0 ? 'Sesuai' : 'Sesuai';
    final rasio = hasil / target;
    if (rasio < 0.9) return 'Kurang';
    if (rasio > 1.1) return 'Lebih';
    return 'Sesuai';
  }
}