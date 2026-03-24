class BahanPakan {
  final int id;
  final String nama;
  final String kategori;
  final double bk;
  final double abu;
  final double lemak;
  final double serat;
  final double protein;
  final double betn;
  final double tdn;
  final double me;
  final double hargaDefault;
  final bool isActive;

  const BahanPakan({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.bk,
    required this.abu,
    required this.lemak,
    required this.serat,
    required this.protein,
    required this.betn,
    required this.tdn,
    required this.me,
    required this.hargaDefault,
    required this.isActive,
  });

  factory BahanPakan.fromJson(Map<String, dynamic> json) {
    return BahanPakan(
      id: json['id'] as int,
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      bk: (json['bk'] as num).toDouble(),
      abu: (json['abu'] as num).toDouble(),
      lemak: (json['lemak'] as num).toDouble(),
      serat: (json['serat'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      betn: (json['betn'] as num).toDouble(),
      tdn: (json['tdn'] as num).toDouble(),
      me: (json['me'] as num).toDouble(),
      hargaDefault: (json['hargaDefault'] as num).toDouble(),
      isActive: json['isActive'] as bool,
    );
  }
}