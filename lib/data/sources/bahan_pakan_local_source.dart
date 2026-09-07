import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../csv/bahan_pakan_csv_codec.dart';
import '../models/bahan_pakan.dart';

typedef BahanPakanWriteOperation = Future<void> Function(List<BahanPakan> data);

class BahanPakanPersistenceError implements Exception {
  const BahanPakanPersistenceError({
    required this.originalError,
    required this.originalStackTrace,
    required this.rollbackError,
    required this.rollbackStackTrace,
  });

  final Object originalError;
  final StackTrace originalStackTrace;
  final Object rollbackError;
  final StackTrace rollbackStackTrace;

  @override
  String toString() =>
      'Persistence failed: $originalError; rollback failed: $rollbackError';
}

class BahanPakanLocalSource {
  BahanPakanLocalSource({BahanPakanWriteOperation? writeOperation})
    : _writeOperation = writeOperation;

  static const _boxName = 'bahan_pakan_box';

  final BahanPakanWriteOperation? _writeOperation;

  Box<BahanPakan> get _box => Hive.box<BahanPakan>(_boxName);

  Future<List<BahanPakan>> ambilDataTersimpan() async {
    return _box.values.toList();
  }

  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    if (_box.isNotEmpty) {
      return ambilDataTersimpan();
    }

    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
    return initialData;
  }

  Future<List<BahanPakan>> ambilBahanPakanAwal() async {
    final csvString =
        await rootBundle.loadString('assets/data/bahan_pakan.csv');
    final rows = BahanPakanCsvCodec.parse(csvString);
    final data = <BahanPakan>[];
    for (var i = 0; i < rows.length; i++) {
      data.add(BahanPakan(
        id: i + 1,
        nama: rows[i].nama,
        bk: rows[i].bk,
        abu: rows[i].abu,
        lemak: rows[i].lemak,
        serat: rows[i].serat,
        protein: rows[i].protein,
        betn: rows[i].betn,
        tdn: rows[i].tdn,
        me: rows[i].me,
        hargaDefault: rows[i].harga,
        isActive: true,
        ca: rows[i].ca,
        p: rows[i].p,
      ));
    }
    return List.unmodifiable(data);
  }

  Future<void> simpanSemuaBahanPakan(List<BahanPakan> daftarBahan) async {
    final immutableData = List<BahanPakan>.unmodifiable(daftarBahan);
    if (_writeOperation != null) {
      await _writeOperation!(immutableData);
      return;
    }

    final box = _box;
    final backup = box.values.toList();
    try {
      await box.clear();
      for (final data in immutableData) {
        await box.add(data);
      }
    } catch (_) {
      // rollback
      await box.clear();
      for (final data in backup) {
        await box.add(data);
      }
      rethrow;
    }
  }

  Future<void> resetKeDataAwal() async {
    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
  }
}