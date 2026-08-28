import 'dart:async';

import 'package:dipo_feed/data/csv/bahan_pakan_csv_codec.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySource extends BahanPakanLocalSource {
  _MemorySource(Iterable<BahanPakan> initial, {this.seedWhenEmpty = false})
    : persisted = List.of(initial);

  List<BahanPakan> persisted;
  final bool seedWhenEmpty;
  var saveCalls = 0;
  var failNextSave = false;
  var failRollback = false;
  Completer<void>? blockNextSave;
  var saveInProgress = 0;
  var maxConcurrentSaves = 0;

  @override
  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    if (persisted.isEmpty && seedWhenEmpty) {
      await simpanSemuaBahanPakan([bahan(id: 99, nama: 'Seed')]);
    }
    return List.of(persisted);
  }

  @override
  Future<List<BahanPakan>> ambilDataTersimpan() async {
    return List.of(persisted);
  }

  @override
  Future<void> simpanSemuaBahanPakan(List<BahanPakan> daftarBahan) async {
    saveCalls++;
    saveInProgress++;
    maxConcurrentSaves = maxConcurrentSaves < saveInProgress
        ? saveInProgress
        : maxConcurrentSaves;
    try {
      if (blockNextSave != null) {
        final block = blockNextSave!;
        blockNextSave = null;
        await block.future;
      }
      if (failNextSave) {
        failNextSave = false;
        persisted = List.of(daftarBahan);
        throw StateError('original save failed');
      }
      if (failRollback) {
        failRollback = false;
        throw StateError('rollback save failed');
      }
      persisted = List.of(daftarBahan);
    } finally {
      saveInProgress--;
    }
  }
}

BahanPakan bahan({
  required int id,
  required String nama,
  String kategori = 'hijauan',
  double bk = 1,
  double harga = 100,
  bool isActive = true,
}) {
  return BahanPakan(
    id: id,
    nama: nama,
    kategori: kategori,
    bk: bk,
    abu: 2,
    lemak: 3,
    serat: 4,
    protein: 5,
    betn: 6,
    tdn: 7,
    me: 8,
    hargaDefault: harga,
    isActive: isActive,
  );
}

String row({
  required String nama,
  String harga = '100',
  String kategori = 'hijauan',
  String bk = '1,00',
}) {
  return [
    nama,
    harga,
    kategori,
    bk,
    '2,00',
    '3,00',
    '4,00',
    '5,00',
    '6,00',
    '7,00',
    '8,00',
    '0,00',
    '0,00',
  ].join(';');
}

String csv(Iterable<String> rows) {
  return '${BahanPakanCsvCodec.header}\n${rows.join('\n')}\n';
}

List<Map<String, dynamic>> snapshot(Iterable<BahanPakan> data) {
  return data.map((item) => item.toJson()).toList();
}

void main() {
  test(
    'add rejects duplicate names after trim and lowercase normalization',
    () async {
      final source = _MemorySource([bahan(id: 1, nama: 'Rumput Gajah')]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();

      await expectLater(
        repository.addBahan(bahan(id: 2, nama: '  RUMPUT GAJAH  ')),
        throwsArgumentError,
      );

      expect(source.saveCalls, 0);
      expect(snapshot(repository.semuaData), snapshot(source.persisted));
    },
  );

  test('add rejects duplicate IDs', () async {
    final source = _MemorySource([bahan(id: 1, nama: 'Rumput Gajah')]);
    final repository = BahanPakanRepository.forTesting(source);

    await repository.initialize();

    await expectLater(
      repository.addBahan(bahan(id: 1, nama: 'Daun Singkong')),
      throwsArgumentError,
    );

    expect(source.saveCalls, 0);
  });

  test('add and update reject formula-leading names', () async {
    final source = _MemorySource([bahan(id: 1, nama: 'Rumput Gajah')]);
    final repository = BahanPakanRepository.forTesting(source);

    await repository.initialize();

    for (final prefix in ['=', '+', '-', '@']) {
      await expectLater(
        repository.addBahan(bahan(id: 10 + prefix.codeUnitAt(0), nama: '$prefix Bahaya')),
        throwsArgumentError,
      );
      await expectLater(
        repository.updateBahan(1, bahan(id: 1, nama: '$prefix Bahaya')),
        throwsArgumentError,
      );
    }

    expect(source.saveCalls, 0);
  });

  test(
    'update preserves target ID when updated value has another ID',
    () async {
      final source = _MemorySource([bahan(id: 1, nama: 'Rumput Gajah')]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();
      await repository.updateBahan(
        1,
        bahan(id: 99, nama: 'Rumput Gajah', bk: 2),
      );

      expect(repository.semuaData.single.id, 1);
      expect(source.persisted.single.id, 1);
      expect(repository.semuaData.single.bk, 2);
    },
  );

  test('serializes concurrent repository operations', () async {
    final source = _MemorySource([]);
    final repository = BahanPakanRepository.forTesting(source);
    final block = Completer<void>();
    source.blockNextSave = block;

    final first = repository.addBahan(bahan(id: 1, nama: 'Pertama'));
    await Future<void>.delayed(Duration.zero);
    final second = repository.addBahan(bahan(id: 2, nama: 'Kedua'));
    await Future<void>.delayed(Duration.zero);

    expect(source.saveCalls, 1);
    expect(source.maxConcurrentSaves, 1);

    block.complete();
    await Future.wait([first, second]);

    expect(source.saveCalls, 2);
    expect(source.maxConcurrentSaves, 1);
    expect(repository.semuaData.map((item) => item.id), [1, 2]);
  });

  test('preserves original persistence error when rollback fails', () async {
    final source = _MemorySource([bahan(id: 1, nama: 'Lama')]);
    final repository = BahanPakanRepository.forTesting(source);

    await repository.initialize();
    source.failNextSave = true;
    source.failRollback = true;

    await expectLater(
      repository.replaceFromCsv(csv([row(nama: 'Baru')])),
      throwsA(
        predicate(
          (Object error) =>
              error.toString().contains('original save failed') &&
              error.toString().contains('rollback save failed'),
        ),
      ),
    );
  });

  test(
    'update allows same record name but rejects another record name',
    () async {
      final source = _MemorySource([
        bahan(id: 1, nama: 'Rumput Gajah'),
        bahan(id: 2, nama: 'Daun Singkong'),
      ]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();
      await repository.updateBahan(
        1,
        bahan(id: 1, nama: '  RUMPUT GAJAH  ', bk: 2),
      );

      expect(repository.semuaData.singleWhere((item) => item.id == 1).bk, 2);
      expect(source.saveCalls, 1);

      await expectLater(
        repository.updateBahan(2, bahan(id: 2, nama: ' rumput gajah ')),
        throwsArgumentError,
      );

      expect(source.saveCalls, 1);
      expect(
        repository.semuaData.singleWhere((item) => item.id == 2).nama,
        'Daun Singkong',
      );
    },
  );

  test(
    'CSV replacement preserves matching IDs, assigns IDs above max, deletes absent records, and activates imports',
    () async {
      final source = _MemorySource([
        bahan(id: 3, nama: 'Rumput Gajah', bk: 1, isActive: false),
        bahan(id: 9, nama: 'Daun Singkong'),
        bahan(id: 15, nama: 'Data Lama'),
      ]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();
      final result = await repository.replaceFromCsv(
        csv([
          row(nama: '  RUMPUT GAJAH  ', bk: '2,00'),
          row(nama: 'Ampas Tahu', kategori: 'lainnya', harga: '250'),
        ]),
      );

      expect(result.ditambah, 1);
      expect(result.diperbarui, 1);
      expect(result.dihapus, 2);
      expect(result.barisDiproses, 2);
      expect(repository.semuaData.map((item) => item.id), [3, 16]);
      expect(repository.semuaData.map((item) => item.nama), [
        'RUMPUT GAJAH',
        'Ampas Tahu',
      ]);
      expect(repository.semuaData.every((item) => item.isActive), isTrue);
      expect(source.persisted.map((item) => item.id), [3, 16]);
      expect(source.saveCalls, 1);
    },
  );

  test(
    'uninitialized empty CSV replacement persists imported data once with IDs from 1',
    () async {
      final source = _MemorySource([], seedWhenEmpty: true);
      final repository = BahanPakanRepository.forTesting(source);

      final result = await repository.replaceFromCsv(
        csv([row(nama: 'Data Baru')]),
      );

      expect(result.ditambah, 1);
      expect(repository.semuaData.single.id, 1);
      expect(source.persisted.single.id, 1);
      expect(source.saveCalls, 1);
    },
  );

  test(
    'CSV deletion count includes every existing ID absent from replacement',
    () async {
      final source = _MemorySource([
        bahan(id: 1, nama: 'Duplikat'),
        bahan(id: 2, nama: ' duplikat '),
        bahan(id: 3, nama: 'Data Lama'),
      ]);
      final repository = BahanPakanRepository.forTesting(source);

      final result = await repository.replaceFromCsv(
        csv([row(nama: 'Duplikat')]),
      );

      expect(result.diperbarui, 1);
      expect(result.dihapus, 2);
    },
  );

  test('CSV duplicate normalized names use last row', () async {
    final source = _MemorySource([bahan(id: 4, nama: 'Rumput Gajah')]);
    final repository = BahanPakanRepository.forTesting(source);

    await repository.initialize();
    final result = await repository.replaceFromCsv(
      csv([
        row(nama: 'Rumput Gajah', bk: '2,00'),
        row(nama: ' rumput gajah ', bk: '3,00'),
      ]),
    );

    expect(result.barisDiproses, 1);
    expect(repository.semuaData.single.bk, 3);
    expect(repository.semuaData.single.id, 4);
  });

  test(
    'invalid CSV performs no persistence and keeps repository data',
    () async {
      final source = _MemorySource([bahan(id: 1, nama: 'Rumput Gajah')]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();
      final before = snapshot(repository.semuaData);

      await expectLater(
        repository.replaceFromCsv(
          csv([row(nama: 'Data Baru', bk: 'not-a-number')]),
        ),
        throwsFormatException,
      );

      expect(source.saveCalls, 0);
      expect(snapshot(repository.semuaData), before);
      expect(snapshot(source.persisted), before);
    },
  );

  test(
    'persistence failure rolls back repository and persisted data',
    () async {
      final source = _MemorySource([
        bahan(id: 1, nama: 'Rumput Gajah'),
        bahan(id: 2, nama: 'Daun Singkong'),
      ]);
      final repository = BahanPakanRepository.forTesting(source);

      await repository.initialize();
      final before = snapshot(repository.semuaData);
      source.failNextSave = true;

      await expectLater(
        repository.replaceFromCsv(csv([row(nama: 'Data Baru')])),
        throwsStateError,
      );

      expect(snapshot(repository.semuaData), before);
      expect(snapshot(source.persisted), before);
      expect(source.saveCalls, 2);
    },
  );
}
