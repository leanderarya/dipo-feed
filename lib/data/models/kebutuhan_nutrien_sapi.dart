class DetailKebutuhanNutrienSapi {
  final double? kgSusu;
  final double? fcm4;
  final double? bkPersenBb;
  final double? tdnHidupPokokKg;
  final double? proteinHidupPokokGram;
  final double? caHidupPokokGram;
  final double? pHidupPokokGram;
  final double? tdnProduksiKg;
  final double? proteinProduksiGram;
  final double? caProduksiGram;
  final double? pProduksiGram;

  const DetailKebutuhanNutrienSapi({
    this.kgSusu,
    this.fcm4,
    this.bkPersenBb,
    this.tdnHidupPokokKg,
    this.proteinHidupPokokGram,
    this.caHidupPokokGram,
    this.pHidupPokokGram,
    this.tdnProduksiKg,
    this.proteinProduksiGram,
    this.caProduksiGram,
    this.pProduksiGram,
  });
}

class KebutuhanNutrienSapi {
  final double kebutuhanBkKg;
  final double kebutuhanProteinKg;
  final double kebutuhanTdnKg;
  final double kebutuhanCaGram;
  final double kebutuhanPGram;
  final DetailKebutuhanNutrienSapi? detail;
  final List<String> catatan;

  const KebutuhanNutrienSapi({
    required this.kebutuhanBkKg,
    required this.kebutuhanProteinKg,
    required this.kebutuhanTdnKg,
    required this.kebutuhanCaGram,
    required this.kebutuhanPGram,
    this.detail,
    this.catatan = const [],
  });
}
