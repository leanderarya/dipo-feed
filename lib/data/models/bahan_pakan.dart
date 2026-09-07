import 'package:dipo_feed/core/utils/indonesian_number_formatter.dart';
import 'package:hive/hive.dart';

part 'bahan_pakan.g.dart';

@HiveType(typeId: 0)
class BahanPakan {
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String nama;
  @HiveField(2)
  final double bk;
  @HiveField(3)
  final double abu;
  @HiveField(4)
  final double lemak;
  @HiveField(5)
  final double serat;
  @HiveField(6)
  final double protein;
  @HiveField(7)
  final double betn;
  @HiveField(8)
  final double tdn;
  @HiveField(9)
  final double me;
  @HiveField(10)
  final double hargaDefault;
  @HiveField(11)
  final bool isActive;
  @HiveField(12)
  final double ca;
  @HiveField(13)
  final double p;

  const BahanPakan({
    required this.id,
    required this.nama,
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
    this.ca = 0,
    this.p = 0,
  });

  factory BahanPakan.fromJson(Map<String, dynamic> json) {
    return BahanPakan(
      id: json['id'] as int,
      nama: json['nama'] as String,
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
      ca: (json['ca'] as num?)?.toDouble() ?? 0,
      p: (json['p'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
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
      'ca': ca,
      'p': p,
    };
  }

  bool isValidForCalculation({bool requirePositiveBk = false}) {
    final values = [
      bk,
      abu,
      lemak,
      serat,
      protein,
      betn,
      tdn,
      me,
      hargaDefault,
      ca,
      p,
    ];
    return values.every(
          (value) =>
              IndonesianNumberFormatter.isSupportedMagnitude(value) &&
              value >= 0,
        ) &&
        (!requirePositiveBk || bk > 0);
  }

  BahanPakan copyWith({
    int? id,
    String? nama,
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
    double? ca,
    double? p,
  }) {
    return BahanPakan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
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
      ca: ca ?? this.ca,
      p: p ?? this.p,
    );
  }
}