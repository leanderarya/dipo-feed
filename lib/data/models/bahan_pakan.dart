import 'package:hive/hive.dart';

part 'bahan_pakan.g.dart';

@HiveType(typeId: 0)
class BahanPakan {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String nama;
  @HiveField(2)
  final String kategori;
  @HiveField(3)
  final double bk;
  @HiveField(4)
  final double abu;
  @HiveField(5)
  final double lemak;
  @HiveField(6)
  final double serat;
  @HiveField(7)
  final double protein;
  @HiveField(8)
  final double betn;
  @HiveField(9)
  final double tdn;
  @HiveField(10)
  final double me;
  @HiveField(11)
  final double hargaDefault;
  @HiveField(12)
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
