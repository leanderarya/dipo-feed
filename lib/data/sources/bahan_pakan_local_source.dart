import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bahan_pakan.dart';

class BahanPakanLocalSource {
  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    final jsonString =
        await rootBundle.loadString('assets/data/bahan_pakan.json');

    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    return jsonList
        .map((item) => BahanPakan.fromJson(item as Map<String, dynamic>))
        .where((item) => item.isActive)
        .toList();
  }
}