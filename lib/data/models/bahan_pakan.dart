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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'bk': bk,
      'abu': abu,
      'lemak': lemak,
      'serat': serat,
      'protein': protein,
      'betn': betn,
      'tdn': tdn,
      'me': me,
      'hargaDefault': hargaDefault,
      'isActive': isActive,
    };
  }

  BahanPakan copyWith({
    int? id,
    String? nama,
    String? kategori,
    double? bk,
    double? abu,
    double? lemak,
    double? serat,
    double? protein,
    double? betn,
    double? tdn,
    double? me,
    double? hargaDefault,
    bool? isActive,
  }) {
    return BahanPakan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      kategori: kategori ?? this.kategori,
      bk: bk ?? this.bk,
      abu: abu ?? this.abu,
      lemak: lemak ?? this.lemak,
      serat: serat ?? this.serat,
      protein: protein ?? this.protein,
      betn: betn ?? this.betn,
      tdn: tdn ?? this.tdn,
      me: me ?? this.me,
      hargaDefault: hargaDefault ?? this.hargaDefault,
      isActive: isActive ?? this.isActive,
    );
  }
}
