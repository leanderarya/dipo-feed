class HasilPakanTerpilih {
  final double totalBeratKg;
  final double bkPersen;
  final double proteinPersen;
  final double tdnPersen;
  final double me;

  const HasilPakanTerpilih({
    required this.totalBeratKg,
    required this.bkPersen,
    required this.proteinPersen,
    required this.tdnPersen,
    required this.me,
  });

  double get bkKg => totalBeratKg * (bkPersen / 100);
  double get proteinKg => totalBeratKg * (proteinPersen / 100);
  double get tdnKg => totalBeratKg * (tdnPersen / 100);
  double get meTotal => totalBeratKg * me;
}