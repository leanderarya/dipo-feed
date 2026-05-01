import '../../../data/models/bahan_pakan.dart';
import '../../../data/models/kebutuhan_nutrien_sapi.dart';

class TargetNutrien {
  final double bkKg;
  final double pkKg;
  final double tdnKg;
  final double caGram;
  final double pGram;

  const TargetNutrien({
    required this.bkKg,
    required this.pkKg,
    required this.tdnKg,
    required this.caGram,
    required this.pGram,
  });

  factory TargetNutrien.fromKebutuhan(KebutuhanNutrienSapi kebutuhan) {
    return TargetNutrien(
      bkKg: kebutuhan.kebutuhanBkKg,
      pkKg: kebutuhan.kebutuhanProteinKg,
      tdnKg: kebutuhan.kebutuhanTdnKg,
      caGram: kebutuhan.kebutuhanCaGram,
      pGram: kebutuhan.kebutuhanPGram,
    );
  }
}

class KontribusiNutrien {
  final double bkKg;
  final double pkKg;
  final double tdnKg;
  final double caGram;
  final double pGram;
  final double abuKg;
  final double lkKg;
  final double skKg;
  final double betnKg;

  const KontribusiNutrien({
    required this.bkKg,
    required this.pkKg,
    required this.tdnKg,
    required this.caGram,
    required this.pGram,
    required this.abuKg,
    required this.lkKg,
    required this.skKg,
    required this.betnKg,
  });

  const KontribusiNutrien.zero()
      : bkKg = 0,
        pkKg = 0,
        tdnKg = 0,
        caGram = 0,
        pGram = 0,
        abuKg = 0,
        lkKg = 0,
        skKg = 0,
        betnKg = 0;

  KontribusiNutrien operator +(KontribusiNutrien other) {
    return KontribusiNutrien(
      bkKg: bkKg + other.bkKg,
      pkKg: pkKg + other.pkKg,
      tdnKg: tdnKg + other.tdnKg,
      caGram: caGram + other.caGram,
      pGram: pGram + other.pGram,
      abuKg: abuKg + other.abuKg,
      lkKg: lkKg + other.lkKg,
      skKg: skKg + other.skKg,
      betnKg: betnKg + other.betnKg,
    );
  }
}

class RekomendasiPakanItem {
  final BahanPakan bahan;
  final double asFedKg;
  final double bkKg;
  final KontribusiNutrien kontribusi;

  const RekomendasiPakanItem({
    required this.bahan,
    required this.asFedKg,
    required this.bkKg,
    required this.kontribusi,
  });
}

class HasilRekomendasiPakan {
  final TargetNutrien kebutuhan;
  final double targetBkHijauan;
  final double targetBkKonsentrat;
  final List<RekomendasiPakanItem> rekomendasiHijauan;
  final List<RekomendasiPakanItem> rekomendasiKonsentrat;
  final KontribusiNutrien totalHijauan;
  final KontribusiNutrien totalKonsentrat;
  final KontribusiNutrien totalGabungan;
  final double lkPersenDariBk;
  final bool isLkAman;
  final String kesimpulan;
  final bool hasCaData;
  final bool hasPData;

  const HasilRekomendasiPakan({
    required this.kebutuhan,
    required this.targetBkHijauan,
    required this.targetBkKonsentrat,
    required this.rekomendasiHijauan,
    required this.rekomendasiKonsentrat,
    required this.totalHijauan,
    required this.totalKonsentrat,
    required this.totalGabungan,
    required this.lkPersenDariBk,
    required this.isLkAman,
    required this.kesimpulan,
    required this.hasCaData,
    required this.hasPData,
  });

  KontribusiNutrien get totalKontribusi => totalGabungan;
}
