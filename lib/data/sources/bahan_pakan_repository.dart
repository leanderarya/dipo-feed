import '../csv/bahan_pakan_csv_codec.dart';
import '../csv/hasil_import_bahan_pakan.dart';
import '../models/bahan_pakan.dart';
import 'bahan_pakan_local_source.dart';

class BahanPakanRepository {
  static final BahanPakanRepository _instance =
      BahanPakanRepository._internal();
  factory BahanPakanRepository() => _instance;
  BahanPakanRepository._internal() : _source = BahanPakanLocalSource();
  BahanPakanRepository.forTesting(BahanPakanLocalSource source)
    : _source = source;

  final List<BahanPakan> _bahanPakan = [];
  final BahanPakanLocalSource _source;
  Future<void> _operationTail = Future<void>.value();
  bool _isInitialized = false;

  List<BahanPakan> get dataAktif =>
      List.unmodifiable(_bahanPakan.where((bahan) => bahan.isActive));
  List<BahanPakan> get data => dataAktif;
  List<BahanPakan> get semuaData => List.unmodifiable(_bahanPakan);

  Future<void> initialize() => _serialized(_initializeUnsafe);

  Future<void> _initializeUnsafe() async {
    if (_isInitialized) return;

    final data = await _source.ambilSemuaBahanPakan();
    _restoreMemory(data);
    _isInitialized = true;
  }

  Future<void> refresh() => _serialized(_refreshUnsafe);

  Future<void> _refreshUnsafe() async {
    final data = await _source.ambilSemuaBahanPakan();
    _restoreMemory(data);
    _isInitialized = true;
  }

  Future<void> addBahan(BahanPakan bahan) => _serialized(() async {
    await _initializeUnsafe();
    if (BahanPakanCsvCodec.isFormulaLeadingName(bahan.nama)) {
      throw ArgumentError('Nama bahan pakan tidak boleh diawali karakter formula');
    }
    if (_bahanPakan.any((item) => item.id == bahan.id)) {
      throw ArgumentError('Bahan pakan dengan ID tersebut sudah ada');
    }
    if (_bahanPakan.any((item) => _namaSama(item.nama, bahan.nama))) {
      throw ArgumentError('Bahan pakan dengan nama tersebut sudah ada');
    }
    await _commitUnsafe([..._bahanPakan, bahan]);
  });

  Future<void> updateBahan(int id, BahanPakan updatedBahan) =>
      _serialized(() async {
        await _initializeUnsafe();
        final index = _bahanPakan.indexWhere((bahan) => bahan.id == id);
        if (index == -1) return;
        if (BahanPakanCsvCodec.isFormulaLeadingName(updatedBahan.nama)) {
          throw ArgumentError('Nama bahan pakan tidak boleh diawali karakter formula');
        }

        final duplicate = _bahanPakan.indexWhere(
          (bahan) => bahan.id != id && _namaSama(bahan.nama, updatedBahan.nama),
        );
        if (duplicate != -1) {
          throw ArgumentError('Bahan pakan dengan nama tersebut sudah ada');
        }

        final replacement = List<BahanPakan>.of(_bahanPakan)
          ..[index] = updatedBahan.copyWith(id: id);
        await _commitUnsafe(replacement);
      });

  Future<void> removeBahan(int id) => _serialized(() async {
    await _initializeUnsafe();
    await _commitUnsafe(_bahanPakan.where((bahan) => bahan.id != id).toList());
  });

  Future<HasilImportBahanPakan> replaceFromCsv(String csv) =>
      _serialized(() => _replaceFromCsvUnsafe(csv));

  Future<HasilImportBahanPakan> _replaceFromCsvUnsafe(String csv) async {
    final rows = BahanPakanCsvCodec.parse(csv);
    if (!_isInitialized) {
      final data = await _source.ambilDataTersimpan();
      _restoreMemory(data);
      _isInitialized = true;
    }

    final existingByName = <String, BahanPakan>{
      for (final bahan in _bahanPakan) _namaNormalisasi(bahan.nama): bahan,
    };
    final replacement = <BahanPakan>[];
    var added = 0;
    var updated = 0;
    var next = nextId();

    for (final row in rows) {
      final existing = existingByName[row.namaNormalisasi];
      if (existing == null) {
        added++;
        replacement.add(_fromCsvRow(row, next++));
      } else {
        updated++;
        replacement.add(_fromCsvRow(row, existing.id));
      }
    }

    final replacementIds = replacement.map((bahan) => bahan.id).toSet();
    final deleted = _bahanPakan
        .where((bahan) => !replacementIds.contains(bahan.id))
        .length;
    await _commitUnsafe(replacement);

    return HasilImportBahanPakan(
      ditambah: added,
      diperbarui: updated,
      dihapus: deleted,
      barisDiproses: rows.length,
    );
  }

  Future<void> resetKeDataAwal() => _serialized(() async {
    await _source.resetKeDataAwal();
    await _refreshUnsafe();
  });

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _operationTail.then((_) => operation());
    _operationTail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }

  int nextId() {
    if (_bahanPakan.isEmpty) return 1;
    return _bahanPakan
            .map((bahan) => bahan.id)
            .reduce((current, next) => current > next ? current : next) +
        1;
  }

  static String _namaNormalisasi(String nama) => nama.trim().toLowerCase();

  static bool _namaSama(String first, String second) =>
      _namaNormalisasi(first) == _namaNormalisasi(second);

  static BahanPakan _fromCsvRow(BahanPakanCsvRow row, int id) {
    return BahanPakan(
      id: id,
      nama: row.nama,
      bk: row.bk,
      abu: row.abu,
      lemak: row.lemak,
      serat: row.serat,
      protein: row.protein,
      betn: row.betn,
      tdn: row.tdn,
      me: row.me,
      hargaDefault: row.harga,
      isActive: true,
      ca: row.ca,
      p: row.p,
    );
  }

  Future<void> _commitUnsafe(List<BahanPakan> replacement) async {
    final previous = List<BahanPakan>.of(_bahanPakan);
    try {
      await _source.simpanSemuaBahanPakan(replacement);
    } catch (error, stackTrace) {
      try {
        await _source.simpanSemuaBahanPakan(previous);
      } catch (rollbackError, rollbackStackTrace) {
        _restoreMemory(previous);
        Error.throwWithStackTrace(
          BahanPakanPersistenceError(
            originalError: error,
            originalStackTrace: stackTrace,
            rollbackError: rollbackError,
            rollbackStackTrace: rollbackStackTrace,
          ),
          stackTrace,
        );
      }
      _restoreMemory(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
    _restoreMemory(replacement);
  }

  void _restoreMemory(Iterable<BahanPakan> data) {
    _bahanPakan
      ..clear()
      ..addAll(data);
  }
}
