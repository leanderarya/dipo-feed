import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/bahan_pakan.dart';

class BahanPakanLocalSource {
  static const _boxName = 'bahan_pakan_box';

  Box<BahanPakan> get _box => Hive.box<BahanPakan>(_boxName);

  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    if (_box.isNotEmpty) {
      return _box.values.toList();
    }

    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
    return initialData;
  }

  Future<List<BahanPakan>> ambilBahanPakanAwal() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/bahan_pakan.json');
      return _parseJsonList(jsonString);
    } catch (e) {
      return [];
    }
  }

  Future<void> simpanSemuaBahanPakan(List<BahanPakan> daftarBahan) async {
    await _box.clear();
    await _box.addAll(daftarBahan);
  }

  Future<void> resetKeDataAwal() async {
    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
  }

  List<BahanPakan> _parseJsonList(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    return jsonList
        .map((item) => BahanPakan.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
