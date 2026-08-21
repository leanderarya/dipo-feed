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
    final storedData = _box.values.toList();
    final normalizedData = _normalisasiKategoriLegacy(storedData);
    if (!_samaData(storedData, normalizedData)) {
      await simpanSemuaBahanPakan(normalizedData);
    }
    return normalizedData;
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
    final csvString = await rootBundle.loadString(
      'assets/data/bahan_pakan.csv',
    );
    final rows = BahanPakanCsvCodec.parse(csvString);
    if (rows.isEmpty) {
      throw const FormatException('CSV seed must contain at least one row');
    }
    return [
      for (var index = 0; index < rows.length; index++)
        BahanPakan(
          id: index + 1,
          nama: rows[index].nama,
          kategori: rows[index].kategori,
          bk: rows[index].bk,
          abu: rows[index].abu,
          lemak: rows[index].lemak,
          serat: rows[index].serat,
          protein: rows[index].protein,
          betn: rows[index].betn,
          tdn: rows[index].tdn,
          me: rows[index].me,
          hargaDefault: rows[index].harga,
          isActive: true,
          ca: rows[index].ca,
          p: rows[index].p,
        ),
    ];
  }

  static List<BahanPakan> _normalisasiKategoriLegacy(
    Iterable<BahanPakan> data,
  ) {
    return [
      for (final bahan in data)
        bahan.kategori.trim().toLowerCase() == 'energi' ||
                bahan.kategori.trim().toLowerCase() == 'limbah'
            ? bahan.copyWith(kategori: 'lainnya')
            : bahan,
    ];
  }

  static bool _samaData(List<BahanPakan> first, List<BahanPakan> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].toJson().toString() !=
          second[index].toJson().toString()) {
        return false;
      }
    }
    return true;
  }

  Future<void> simpanSemuaBahanPakan(List<BahanPakan> daftarBahan) async {
    final snapshot = _box.values.toList(growable: false);
    try {
      if (_writeOperation == null) {
        await _box.clear();
        await _box.addAll(daftarBahan);
      } else {
        await _writeOperation(List.unmodifiable(daftarBahan));
      }
    } catch (error, stackTrace) {
      try {
        await _box.clear();
        await _box.addAll(snapshot);
      } catch (restoreError, restoreStackTrace) {
        Error.throwWithStackTrace(
          BahanPakanPersistenceError(
            originalError: error,
            originalStackTrace: stackTrace,
            rollbackError: restoreError,
            rollbackStackTrace: restoreStackTrace,
          ),
          stackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> resetKeDataAwal() async {
    final initialData = await ambilBahanPakanAwal();
    await simpanSemuaBahanPakan(initialData);
  }
}
