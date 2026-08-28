import 'dart:async';
import 'dart:convert';

import 'package:dipo_feed/core/theme/app_theme.dart';
import 'package:dipo_feed/core/utils/indonesian_number_formatter.dart';
import 'package:dipo_feed/data/csv/bahan_pakan_csv_codec.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_repository.dart';
import 'package:dipo_feed/features/master_pakan/master_pakan_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

class _MemorySource extends BahanPakanLocalSource {
  _MemorySource(this.data);

  List<BahanPakan> data;
  bool failWrites = false;
  int readCalls = 0;

  @override
  Future<List<BahanPakan>> ambilSemuaBahanPakan() async {
    readCalls++;
    return List.of(data);
  }

  @override
  Future<List<BahanPakan>> ambilDataTersimpan() async => List.of(data);

  @override
  Future<void> simpanSemuaBahanPakan(List<BahanPakan> data) async {
    if (failWrites) throw StateError('write failed');
    this.data = List.of(data);
  }
}

const _activeFeed = BahanPakan(
  id: 1,
  nama: 'Rumput Gajah',
  kategori: 'hijauan',
  bk: 29.24,
  abu: 17.9,
  lemak: 1.27,
  serat: 31.21,
  protein: 9.35,
  betn: 40.27,
  tdn: 54.58,
  me: 8.24,
  hargaDefault: 500,
  isActive: true,
);

const _inactiveFeed = BahanPakan(
  id: 2,
  nama: 'Feed Inactive',
  kategori: 'lainnya',
  bk: 1,
  abu: 2,
  lemak: 3,
  serat: 4,
  protein: 5,
  betn: 6,
  tdn: 7,
  me: 8,
  hargaDefault: 9,
  isActive: false,
);

Future<void> _pumpMaster(
  WidgetTester tester, {
  required BahanPakanRepository repository,
  required Future<PlatformFile?> Function() pickCsv,
  required Future<ShareResult> Function(
    Iterable<BahanPakan> data,
    Rect sharePositionOrigin,
  )
  shareCsv,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MasterPakanScreen(
        repository: repository,
        pickCsv: pickCsv,
        shareCsv: shareCsv,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

PlatformFile _csvFile(String csv) {
  final bytes = utf8.encode(csv);
  return PlatformFile(
    name: 'import.csv',
    size: bytes.length,
    bytes: Uint8List.fromList(bytes),
  );
}

PlatformFile _csvStreamFile(String csv) {
  final bytes = utf8.encode(csv);
  return PlatformFile(
    name: 'import.csv',
    size: bytes.length,
    readStream: Stream<List<int>>.value(bytes),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'CSV codec accepts optional UTF-8 BOM and preserves no-BOM behavior',
    () {
      final csv = BahanPakanCsvCodec.serialize([_activeFeed]);

      expect(BahanPakanCsvCodec.parse('\uFEFF$csv'), hasLength(1));
      expect(BahanPakanCsvCodec.parse(csv), hasLength(1));
    },
  );

  test('rejects formula-leading feed names on parse', () {
    for (final prefix in ['=', '+', '-', '@']) {
      final csv = BahanPakanCsvCodec.serialize([
        _activeFeed,
      ]).replaceFirst(_activeFeed.nama, ' $prefix danger ');

      expect(
        () => BahanPakanCsvCodec.parse(csv),
        throwsFormatException,
        reason: prefix,
      );
    }
  });

  test('rejects formula-leading feed names on serialize', () {
    for (final prefix in ['=', '+', '-', '@']) {
      expect(
        () => BahanPakanCsvCodec.serialize([
          _activeFeed.copyWith(nama: ' $prefix danger '),
        ]),
        throwsArgumentError,
        reason: prefix,
      );
    }
  });

  testWidgets('Database Pakan exposes CSV import and export actions', (
    tester,
  ) async {
    final repository = BahanPakanRepository.forTesting(
      _MemorySource([_activeFeed]),
    );

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    expect(find.byTooltip('Impor CSV'), findsOneWidget);
    expect(find.byTooltip('Ekspor CSV'), findsOneWidget);
  });

  testWidgets('feed category options exclude legacy categories', (
    tester,
  ) async {
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(_MemorySource([_activeFeed])),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.text('Hijauan'), findsOneWidget);
    expect(find.text('Konsentrat'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
    expect(find.text('Limbah'), findsNothing);
    expect(find.text('Energi'), findsNothing);
  });

  testWidgets('form rejects formula-leading feed names', (tester) async {
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(_MemorySource([_activeFeed])),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, ' =Bahaya');
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah Bahan'));
    await tester.pumpAndSettle();

    expect(find.text('Nama tidak boleh diawali karakter formula'), findsOneWidget);
    expect(find.text('Tambah Bahan Baru'), findsOneWidget);
  });

  test('form numeric parser supports Indonesian grouped values', () {
    expect(IndonesianNumberFormatter.tryParse('4.500'), 4500);
    expect(IndonesianNumberFormatter.tryParse('1.234,50'), 1234.5);
  });

  testWidgets('rejects malformed and negative numeric form values', (
    tester,
  ) async {
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(_MemorySource([_activeFeed])),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijauan').last);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Bahan Invalid');
    await tester.enterText(fields.at(1), 'NaN');
    await tester.enterText(fields.at(2), '-1');
    await tester.enterText(fields.at(3), 'Infinity');
    await tester.enterText(fields.at(4), 'not-a-number');
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah Bahan'));
    await tester.pumpAndSettle();

    expect(find.text('Angka tidak valid'), findsNWidgets(3));
    expect(find.text('Tidak boleh negatif'), findsOneWidget);
    expect(find.text('Tambah Bahan Baru'), findsOneWidget);
  });

  testWidgets('saves Indonesian grouped numeric values from form', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(source),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijauan').last);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Grouped Values');
    await tester.enterText(fields.at(1), '4.500');
    await tester.enterText(fields.at(2), '1.234,50');
    await tester.enterText(fields.at(3), '2');
    await tester.enterText(fields.at(4), '3.000');
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah Bahan'));
    await tester.pumpAndSettle();

    final saved = source.data.singleWhere(
      (bahan) => bahan.nama == 'Grouped Values',
    );
    expect(saved.bk, 4500);
    expect(saved.protein, 1234.5);
    expect(saved.tdn, 2);
    expect(saved.hargaDefault, 3000);
  });

  testWidgets(
    'initializes existing decimal values with Indonesian separators',
    (tester) async {
      await _pumpMaster(
        tester,
        repository: BahanPakanRepository.forTesting(
          _MemorySource([_activeFeed]),
        ),
        pickCsv: () async => null,
        shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        '29,24',
      );
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller!.text,
        '9,35',
      );
      expect(
        tester.widget<TextFormField>(fields.at(3)).controller!.text,
        '54,58',
      );
      expect(
        tester.widget<TextFormField>(fields.at(4)).controller!.text,
        '500',
      );
    },
  );

  testWidgets('shows readable errors for CRUD persistence failures', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(source),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );
    source.failWrites = true;

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gagal mengubah status'), findsOneWidget);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pump();

    await tester.tap(find.byTooltip('Reset Data'));
    await tester.pumpAndSettle();
    expect(find.text('Reset master pakan'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gagal mereset'), findsOneWidget);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pump();

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Gagal menghapus'), findsOneWidget);
  });

  testWidgets('shows readable add error when persistence fails', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(source),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.text('Tambah Bahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijauan').last);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Will Fail');
    await tester.enterText(fields.at(1), '1');
    await tester.enterText(fields.at(2), '1');
    await tester.enterText(fields.at(3), '1');
    await tester.enterText(fields.at(4), '1');
    source.failWrites = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Tambah Bahan'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal menyimpan'), findsOneWidget);
  });

  testWidgets('hides export action on Linux', (tester) async {
    final previousTarget = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await _pumpMaster(
      tester,
      repository: BahanPakanRepository.forTesting(_MemorySource([_activeFeed])),
      pickCsv: () async => null,
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    expect(find.byTooltip('Ekspor CSV'), findsNothing);
    debugDefaultTargetPlatformOverride = previousTarget;
  });

  testWidgets('canceling destructive import does not replace records', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    final repository = BahanPakanRepository.forTesting(source);
    var replaceCalled = false;

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => _csvFile(BahanPakanCsvCodec.serialize([])),
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.byTooltip('Impor CSV'));
    await tester.pumpAndSettle();
    expect(find.textContaining('permanen'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    replaceCalled = source.data.isEmpty;
    expect(replaceCalled, isFalse);
    expect(find.text('Rumput Gajah'), findsOneWidget);
  });

  testWidgets('successful import shows counts and refreshed records', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed, _inactiveFeed]);
    final repository = BahanPakanRepository.forTesting(source);
    final imported = BahanPakanCsvCodec.serialize([
      _activeFeed.copyWith(bk: 30),
      _activeFeed.copyWith(id: 3, nama: 'Dedak Baru Á'),
    ]);
    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => _csvFile(imported),
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );
    final readsAfterLoad = source.readCalls;

    await tester.tap(find.byTooltip('Impor CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impor dan Ganti'));
    await tester.pumpAndSettle();

    expect(source.readCalls, readsAfterLoad);
    expect(find.textContaining('Ditambah: 1'), findsOneWidget);
    expect(find.textContaining('Diperbarui: 1'), findsOneWidget);
    expect(find.textContaining('Dihapus: 1'), findsOneWidget);
    expect(find.text('Dedak Baru Á'), findsOneWidget);
    expect(source.data, hasLength(2));
  });

  testWidgets('invalid import shows validation error before confirmation', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    final repository = BahanPakanRepository.forTesting(source);
    final invalidCsv = '${BahanPakanCsvCodec.header}\ninvalid;invalid;bad';

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => _csvFile(invalidCsv),
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.byTooltip('Impor CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal mengimpor CSV'), findsOneWidget);
    expect(find.text('Impor dan Ganti'), findsNothing);
    expect(source.data, hasLength(1));
  });

  testWidgets(
    'invalid UTF-8 import shows readable error without confirmation',
    (tester) async {
      final source = _MemorySource([_activeFeed]);
      final repository = BahanPakanRepository.forTesting(source);

      await _pumpMaster(
        tester,
        repository: repository,
        pickCsv: () async => PlatformFile(
          name: 'import.csv',
          size: 1,
          bytes: Uint8List.fromList([0xC3]),
        ),
        shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
      );

      await tester.tap(find.byTooltip('Impor CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal mengimpor CSV'), findsOneWidget);
      expect(find.text('Impor dan Ganti'), findsNothing);
      expect(source.data, hasLength(1));
    },
  );

  testWidgets(
    'unreadable picker file shows readable error without confirmation',
    (tester) async {
      final source = _MemorySource([_activeFeed]);
      final repository = BahanPakanRepository.forTesting(source);

      await _pumpMaster(
        tester,
        repository: repository,
        pickCsv: () async => PlatformFile(name: 'import.csv', size: 0),
        shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
      );

      await tester.tap(find.byTooltip('Impor CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal mengimpor CSV'), findsOneWidget);
      expect(find.text('Impor dan Ganti'), findsNothing);
      expect(source.data, hasLength(1));
    },
  );

  testWidgets('reads CSV from picker stream when bytes are unavailable', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    final repository = BahanPakanRepository.forTesting(source);
    final imported = BahanPakanCsvCodec.serialize([
      _activeFeed.copyWith(nama: 'Pakan Stream'),
    ]);

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => _csvStreamFile(imported),
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.byTooltip('Impor CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impor dan Ganti'));
    await tester.pumpAndSettle();

    expect(find.text('Pakan Stream'), findsOneWidget);
  });

  testWidgets(
    'processing disables all mutation actions until picker completes',
    (tester) async {
      final source = _MemorySource([_activeFeed]);
      final repository = BahanPakanRepository.forTesting(source);
      final picker = Completer<PlatformFile?>();

      await _pumpMaster(
        tester,
        repository: repository,
        pickCsv: () => picker.future,
        shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
      );

      await tester.tap(find.byTooltip('Impor CSV'));
      await tester.pump();

      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Ekspor CSV',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is IconButton && widget.tooltip == 'Reset Data',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.ancestor(
                of: find.text('Edit'),
                matching: find.byWidgetPredicate(
                  (widget) => widget is ButtonStyleButton,
                ),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.ancestor(
                of: find.text('Hapus'),
                matching: find.byWidgetPredicate(
                  (widget) => widget is ButtonStyleButton,
                ),
              ),
            )
            .onPressed,
        isNull,
      );

      picker.complete(null);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('persistence failure shows error and preserves existing list', (
    tester,
  ) async {
    final source = _MemorySource([_activeFeed]);
    final repository = BahanPakanRepository.forTesting(source);
    source.failWrites = true;
    final imported = BahanPakanCsvCodec.serialize([
      _activeFeed.copyWith(bk: 30),
    ]);

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => _csvFile(imported),
      shareCsv: (_, _) async => ShareResult('', ShareResultStatus.dismissed),
    );

    await tester.tap(find.byTooltip('Impor CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Impor dan Ganti'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal mengimpor CSV'), findsOneWidget);
    expect(find.text('Rumput Gajah'), findsOneWidget);
    expect(source.data.single.bk, _activeFeed.bk);
  });

  testWidgets('export shares serialized active records and ignores dismissal', (
    tester,
  ) async {
    final repository = BahanPakanRepository.forTesting(
      _MemorySource([_activeFeed, _inactiveFeed]),
    );
    String? sharedCsv;
    Rect? sharePositionOrigin;

    await _pumpMaster(
      tester,
      repository: repository,
      pickCsv: () async => null,
      shareCsv: (data, origin) async {
        sharedCsv = BahanPakanCsvCodec.serialize(data);
        sharePositionOrigin = origin;
        return ShareResult('', ShareResultStatus.dismissed);
      },
    );

    await tester.tap(find.byTooltip('Ekspor CSV'));
    await tester.pumpAndSettle();

    expect(sharedCsv, BahanPakanCsvCodec.serialize([_activeFeed]));
    expect(sharedCsv, isNot(contains('Feed Inactive')));
    expect(sharePositionOrigin, isNotNull);
  });
}
