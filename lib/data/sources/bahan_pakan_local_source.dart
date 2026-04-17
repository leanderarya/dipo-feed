import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bahan_pakan.dart';

class BahanPakanLocalSource {
  static const _storageKey = 'master_bahan_pakan_v1';

  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_storageKey);

    if (storedJson != null && storedJson.isNotEmpty) {
      return _parseJsonList(storedJson);
    }

    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
    return initialData;
  }

  Future<List<BahanPakan>> ambilBahanPakanAwal() async {
    final jsonString =
        await rootBundle.loadString('assets/data/bahan_pakan.json');
    return _parseJsonList(jsonString);
  }

  Future<void> simpanSemuaBahanPakan(List<BahanPakan> daftarBahan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(
      daftarBahan.map((bahan) => bahan.toJson()).toList(),
    );
    await prefs.setString(_storageKey, jsonString);
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
