import '../../../data/models/bahan_pakan.dart';
import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import 'hasil_rekomendasi_pakan.dart';
import 'nutrien_helper.dart';

class PerhitunganRekomendasiPakan {
  static const _bobotBk = 2.5;
  static const _bobotPk = 3.0;
  static const _bobotTdn = 2.0;
  static const _bobotCa = 1.0;
  static const _bobotP = 1.0;
  static const _batasLkPersen = 5.0;
  static const _penaltiBkKurangBerat = 25.0;
  static const List<double> _multipliers = [
    0,
    0.4,
    0.6,
    0.8,
    1.0,
    1.2,
    1.4,
    1.6,
  ];

  static HasilRekomendasiPakan hitung({
    required KebutuhanNutrienSapi kebutuhan,
    required List<BahanPakan> bahanHijauan,
    required List<BahanPakan> bahanKonsentrat,
  }) {
    final target = TargetNutrien.fromKebutuhan(kebutuhan);
    final targetBkHijauan = target.bkKg * 0.60;
    final targetBkKonsentrat = target.bkKg * 0.40;

    final hasilHijauan = _cariKombinasiTerbaik(
      bahan: bahanHijauan,
      targetKelompok: TargetNutrien(
        bkKg: targetBkHijauan,
        pkKg: target.pkKg * 0.60,
        tdnKg: target.tdnKg * 0.60,
        caGram: target.caGram * 0.60,
        pGram: target.pGram * 0.60,
      ),
      stepKg: 0.5,
      existingKontribusi: const KontribusiNutrien.zero(),
      enforceLkConstraint: false,
      wajibPakaiSemuaBahan: bahanHijauan.length > 1,
    );

    final hasilKonsentrat = _cariKombinasiTerbaik(
      bahan: bahanKonsentrat,
      targetKelompok: TargetNutrien(
        bkKg: targetBkKonsentrat,
        pkKg: target.pkKg * 0.40,
        tdnKg: target.tdnKg * 0.40,
        caGram: target.caGram * 0.40,
        pGram: target.pGram * 0.40,
      ),
      stepKg: 0.25,
      existingKontribusi: hasilHijauan.kontribusi,
      enforceLkConstraint: true,
      wajibPakaiSemuaBahan: bahanKonsentrat.length > 1,
    );

    final totalHijauan = hasilHijauan.kontribusi;
    final totalKonsentrat = hasilKonsentrat.kontribusi;
    final totalGabungan = totalHijauan + totalKonsentrat;
    final lkPersenDariBk = NutrienHelper.hitungLkPersenDariBk(totalGabungan);
    final isLkAman = lkPersenDariBk <= _batasLkPersen;

    final semuaBahan = [...bahanHijauan, ...bahanKonsentrat];
    final hasCaData = semuaBahan.any((item) => item.ca > 0);
    final hasPData = semuaBahan.any((item) => item.p > 0);

    return HasilRekomendasiPakan(
      kebutuhan: target,
      targetBkHijauan: targetBkHijauan,
      targetBkKonsentrat: targetBkKonsentrat,
      rekomendasiHijauan: hasilHijauan.items
          .where((item) => item.asFedKg > 0)
          .toList(),
      rekomendasiKonsentrat: hasilKonsentrat.items
          .where((item) => item.asFedKg > 0)
          .toList(),
      totalHijauan: totalHijauan,
      totalKonsentrat: totalKonsentrat,
      totalGabungan: totalGabungan,
      lkPersenDariBk: lkPersenDariBk,
      isLkAman: isLkAman,
      hasCaData: hasCaData,
      hasPData: hasPData,
      kesimpulan: _buildKesimpulan(
        kebutuhan: target,
        total: totalGabungan,
        lkPersenDariBk: lkPersenDariBk,
      ),
    );
  }

  static _HasilKombinasi _cariKombinasiTerbaik({
    required List<BahanPakan> bahan,
    required TargetNutrien targetKelompok,
    required double stepKg,
    required KontribusiNutrien existingKontribusi,
    required bool enforceLkConstraint,
    required bool wajibPakaiSemuaBahan,
  }) {
    if (bahan.length == 1) {
      final item = _hitungItemLangsung(
        bahan: bahan.first,
        targetBkKg: targetKelompok.bkKg,
        stepKg: stepKg,
      );
      final kontribusi = item.kontribusi;
      final kombinasiTotal = existingKontribusi + kontribusi;
      return _HasilKombinasi(
        items: [item],
        kontribusi: kontribusi,
        score: _hitungScore(
          hasilKelompok: kontribusi,
          targetKelompok: targetKelompok,
        ),
        isLkAman:
            NutrienHelper.hitungLkPersenDariBk(kombinasiTotal) <=
            _batasLkPersen,
      );
    }

    final kandidatPerBahan = bahan.map((item) {
      final estimasiBkPerBahan = targetKelompok.bkKg / bahan.length;
      final estimasiAsFed = item.bk <= 0
          ? 0.0
          : estimasiBkPerBahan / (item.bk / 100);
      return _bangunKandidat(
        estimasiAsFed: estimasiAsFed,
        stepKg: stepKg,
        allowZero: !wajibPakaiSemuaBahan,
      );
    }).toList();

    _HasilKombinasi? terbaikAman;
    _HasilKombinasi? terbaikFallback;

    void telusuri(int index, List<double> pilihan) {
      if (index == bahan.length) {
        final items = <RekomendasiPakanItem>[];
        var kontribusi = const KontribusiNutrien.zero();

        for (var i = 0; i < bahan.length; i++) {
          final asFedKg = pilihan[i];
          final item = _buildItem(bahan: bahan[i], asFedKg: asFedKg);
          items.add(item);
          kontribusi = kontribusi + item.kontribusi;
        }

        final kombinasiTotal = existingKontribusi + kontribusi;
        final isLkAman = NutrienHelper.hitungLkPersenDariBk(kombinasiTotal) <=
            _batasLkPersen;
        final score = _hitungScore(
          hasilKelompok: kontribusi,
          targetKelompok: targetKelompok,
        );
        final hasil = _HasilKombinasi(
          items: items,
          kontribusi: kontribusi,
          score: score,
          isLkAman: isLkAman,
        );

        if (isLkAman || !enforceLkConstraint) {
          if (terbaikAman == null || score < terbaikAman!.score) {
            terbaikAman = hasil;
          }
        }

        if (terbaikFallback == null || score < terbaikFallback!.score) {
          terbaikFallback = hasil;
        }
        return;
      }

      for (final kandidat in kandidatPerBahan[index]) {
        telusuri(index + 1, [...pilihan, kandidat]);
      }
    }

    telusuri(0, []);

    if (terbaikAman != null) return terbaikAman!;
    return terbaikFallback!;
  }

  static List<double> _bangunKandidat({
    required double estimasiAsFed,
    required double stepKg,
    required bool allowZero,
  }) {
    final multipliers = allowZero ? _multipliers : _multipliers.where((item) => item > 0);
    final kandidat = multipliers.map((multiplier) {
      final nilai = estimasiAsFed * multiplier;
      return _bulatkanKeStep(nilai, stepKg);
    }).toSet().toList()
      ..sort();

    if (allowZero && !kandidat.contains(0)) {
      kandidat.insert(0, 0);
    }
    return kandidat;
  }

  static RekomendasiPakanItem _hitungItemLangsung({
    required BahanPakan bahan,
    required double targetBkKg,
    required double stepKg,
  }) {
    if (bahan.bk <= 0) {
      return _buildItem(bahan: bahan, asFedKg: 0);
    }

    final asFedKg = _bulatkanKeStep(targetBkKg / (bahan.bk / 100), stepKg);
    return _buildItem(bahan: bahan, asFedKg: asFedKg);
  }

  static RekomendasiPakanItem _buildItem({
    required BahanPakan bahan,
    required double asFedKg,
  }) {
    final kontribusi = NutrienHelper.hitungKontribusi(
      bahan: bahan,
      asFedKg: asFedKg,
    );
    return RekomendasiPakanItem(
      bahan: bahan,
      asFedKg: asFedKg,
      bkKg: kontribusi.bkKg,
      kontribusi: kontribusi,
    );
  }

  static double _hitungScore({
    required KontribusiNutrien hasilKelompok,
    required TargetNutrien targetKelompok,
  }) {
    final errorBk = NutrienHelper.hitungErrorRelatif(
      hasilKelompok.bkKg,
      targetKelompok.bkKg,
    );
    final errorPk = NutrienHelper.hitungErrorRelatif(
      hasilKelompok.pkKg,
      targetKelompok.pkKg,
    );
    final errorTdn = NutrienHelper.hitungErrorRelatif(
      hasilKelompok.tdnKg,
      targetKelompok.tdnKg,
    );
    final errorCa = NutrienHelper.hitungErrorRelatif(
      hasilKelompok.caGram,
      targetKelompok.caGram,
    );
    final errorP = NutrienHelper.hitungErrorRelatif(
      hasilKelompok.pGram,
      targetKelompok.pGram,
    );

    var score = (_bobotBk * errorBk) +
        (_bobotPk * errorPk) +
        (_bobotTdn * errorTdn) +
        (_bobotCa * errorCa) +
        (_bobotP * errorP);

    if (targetKelompok.bkKg > 0) {
      final rasioCapaianBk = hasilKelompok.bkKg / targetKelompok.bkKg;
      if (rasioCapaianBk <= 0) {
        score += _penaltiBkKurangBerat;
      } else if (rasioCapaianBk < 0.85) {
        score += (0.85 - rasioCapaianBk) * _penaltiBkKurangBerat;
      }
    }

    return score;
  }

  static double _bulatkanKeStep(double nilai, double stepKg) {
    if (stepKg <= 0) return nilai;
    return (nilai / stepKg).round() * stepKg;
  }

  static String _buildKesimpulan({
    required TargetNutrien kebutuhan,
    required KontribusiNutrien total,
    required double lkPersenDariBk,
  }) {
    final statusPk = NutrienHelper.statusNutrien(
      hasil: total.pkKg,
      target: kebutuhan.pkKg,
    );
    final statusTdn = NutrienHelper.statusNutrien(
      hasil: total.tdnKg,
      target: kebutuhan.tdnKg,
    );

    if (statusPk == 'Kurang') {
      return 'Protein masih belum mencukupi kebutuhan. Pertimbangkan menambah bahan konsentrat tinggi protein.';
    }

    if (statusTdn == 'Kurang') {
      return 'Energi pakan masih belum optimal. Pertimbangkan menambah konsentrat sumber energi.';
    }

    if (lkPersenDariBk > _batasLkPersen) {
      return 'Lemak kasar melebihi batas 5% BK. Pertimbangkan mengurangi bahan berlemak tinggi.';
    }

    return 'Rekomendasi pakan sudah mendekati kebutuhan nutrien sapi berdasarkan bahan yang dipilih.';
  }
}

class _HasilKombinasi {
  final List<RekomendasiPakanItem> items;
  final KontribusiNutrien kontribusi;
  final double score;
  final bool isLkAman;

  const _HasilKombinasi({
    required this.items,
    required this.kontribusi,
    required this.score,
    required this.isLkAman,
  });
}
