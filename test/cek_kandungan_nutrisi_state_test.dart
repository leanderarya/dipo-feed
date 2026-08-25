import 'dart:async';

import 'package:dipo_feed/core/theme/app_theme.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/models/hasil_pakan_terpilih.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_repository.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import 'package:dipo_feed/features/master_pakan/master_pakan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySource extends BahanPakanLocalSource {
  _MemorySource(this.data);

  final List<BahanPakan> data;

  @override
  Future<List<BahanPakan>> ambilSemuaBahanPakan() async => List.of(data);

  @override
  Future<List<BahanPakan>> ambilDataTersimpan() async => List.of(data);
}

class _MutableSource extends BahanPakanLocalSource {
  _MutableSource(this.data);

  List<BahanPakan> data;

  @override
  Future<List<BahanPakan>> ambilSemuaBahanPakan() async => List.of(data);

  @override
  Future<List<BahanPakan>> ambilDataTersimpan() async => List.of(data);
}

class _BlockingSource extends BahanPakanLocalSource {
  final Completer<List<BahanPakan>> result = Completer<List<BahanPakan>>();

  @override
  Future<List<BahanPakan>> ambilSemuaBahanPakan() => result.future;

  @override
  Future<List<BahanPakan>> ambilDataTersimpan() => result.future;
}

const _bahan = BahanPakan(
  id: 1,
  nama: 'Rumput Gajah',
  kategori: 'hijauan',
  bk: 29.24,
  abu: 17.90,
  lemak: 1.27,
  serat: 31.21,
  protein: 9.35,
  betn: 40.27,
  tdn: 54.58,
  me: 8.24,
  hargaDefault: 500,
  isActive: true,
);

const _bahanKedua = BahanPakan(
  id: 2,
  nama: 'Rumput Odot',
  kategori: 'hijauan',
  bk: 22.10,
  abu: 22.18,
  lemak: 3.11,
  serat: 21.93,
  protein: 16.90,
  betn: 35.88,
  tdn: 65.01,
  me: 9.82,
  hargaDefault: 2000,
  isActive: true,
);

BahanPakanRepository createRepository({
  BahanPakanLocalSource? source,
  Iterable<BahanPakan> data = const [_bahan, _bahanKedua],
}) {
  return BahanPakanRepository.forTesting(
    source ?? _MemorySource(data.toList()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool modePilihUntukEvaluasi = false,
    BahanPakanRepository? repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CekKandunganNutrisiScreen(
          modePilihUntukEvaluasi: modePilihUntukEvaluasi,
          repository: repository ?? createRepository(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> enterDraftValue(
    WidgetTester tester,
    int fieldIndex,
    String value,
  ) async {
    final field = find.byType(TextFormField).at(fieldIndex);
    await tester.scrollUntilVisible(
      field,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final textFinder = find.text(text);
    final buttonFinder = find.ancestor(
      of: textFinder,
      matching: find.byType(FilledButton),
    );
    final target = buttonFinder.evaluate().isNotEmpty
        ? buttonFinder
        : textFinder;
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(target);
    await tester.pump();
  }

  Future<void> addFeedAndSetWeight(WidgetTester tester, String weight) async {
    await tapText(tester, 'Susun Pakan');
    await tester.pumpAndSettle();
    final firstFeed = find.text('Rumput Gajah').last;
    if (firstFeed.evaluate().isNotEmpty) {
      await tester.tap(firstFeed);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextFormField).first, weight);
    await tester.pump();
  }

  testWidgets('starts in belumDihitung state', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(
      find.text('Tekan Hitung untuk menghitung kandungan campuran.'),
      findsOneWidget,
    );
  });

  testWidgets('empty calculation sets gagal with specific message', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(find.text('Tambahkan minimal satu bahan pakan.'), findsWidgets);
  });

  testWidgets('zero total calculation sets gagal with specific message', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tapText(tester, 'Susun Pakan');
    await tester.pumpAndSettle();
    final firstFeed = find.text('Rumput Gajah').last;
    if (firstFeed.evaluate().isNotEmpty) {
      await tester.tap(firstFeed);
      await tester.pumpAndSettle();
    }

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.text('Total campuran pakan harus lebih dari 0 kg.'),
      findsWidgets,
    );
  });

  testWidgets('invalid input calculation sets gagal with specific message', (
    tester,
  ) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, 'abc');

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(find.text('Jumlah atau harga pakan tidak valid.'), findsWidgets);
  });

  testWidgets('successful Hitung creates snapshot and shows evaluation', (
    tester,
  ) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsOneWidget);
  });

  testWidgets('rejects selected feed with negative persisted nutrient', (
    tester,
  ) async {
    final invalidFeed = _bahan.copyWith(abu: -1);
    await pumpScreen(tester, repository: createRepository(data: [invalidFeed]));
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.text('Data bahan pakan yang dipilih tidak valid.'),
      findsWidgets,
    );
  });

  testWidgets('rejects selected feed at formatter magnitude limit', (
    tester,
  ) async {
    final invalidFeed = _bahan.copyWith(bk: 1e21);
    await pumpScreen(tester, repository: createRepository(data: [invalidFeed]));
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.text('Data bahan pakan yang dipilih tidak valid.'),
      findsWidgets,
    );
  });

  testWidgets('rejects selected feed price at formatter magnitude limit', (
    tester,
  ) async {
    final invalidFeed = _bahan.copyWith(hargaDefault: 1e21);
    await pumpScreen(tester, repository: createRepository(data: [invalidFeed]));
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.text('Data bahan pakan yang dipilih tidak valid.'),
      findsWidgets,
    );
  });

  testWidgets('accepts grouped Indonesian quantity input', (tester) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '1.234,50');

    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsOneWidget);
  });

  for (final value in ['-1', 'NaN', 'Infinity']) {
    testWidgets('rejects invalid quantity $value', (tester) async {
      await pumpScreen(tester);
      await addFeedAndSetWeight(tester, value);

      await tapText(tester, 'Hitung');

      expect(find.text('Gagal menghitung'), findsOneWidget);
      expect(find.text('Jumlah atau harga pakan tidak valid.'), findsWidgets);
    });
  }

  for (final value in ['-1', 'NaN', 'Infinity']) {
    testWidgets('rejects invalid price $value', (tester) async {
      await pumpScreen(tester);
      await addFeedAndSetWeight(tester, '10');
      await enterDraftValue(tester, 1, value);

      await tapText(tester, 'Hitung');

      expect(find.text('Gagal menghitung'), findsOneWidget);
      expect(find.text('Jumlah atau harga pakan tidak valid.'), findsWidgets);
    });
  }

  testWidgets('add mutation invalidates successful snapshot', (tester) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    await tapText(tester, 'Tambah Bahan Pakan');
    await tester.pumpAndSettle();
    final secondFeed = find.text('Rumput Odot').last;
    if (secondFeed.evaluate().isNotEmpty) {
      await tester.tap(secondFeed);
      await tester.pumpAndSettle();
    }

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('remove mutation invalidates successful snapshot', (
    tester,
  ) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    final closeButton = find.byIcon(Icons.close);
    await tester.scrollUntilVisible(
      closeButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(closeButton);
    await tester.pump();

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('feed replacement invalidates successful snapshot', (
    tester,
  ) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    final feedTile = find.text('Rumput Gajah').first;
    await tester.scrollUntilVisible(
      feedTile,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(feedTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rumput Odot').last);
    await tester.pumpAndSettle();

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('price mutation invalidates successful snapshot', (tester) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    await enterDraftValue(tester, 1, '600');

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('draft evaluation action rejects without current snapshot', (
    tester,
  ) async {
    await pumpScreen(tester, modePilihUntukEvaluasi: true);
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Gunakan untuk Evaluasi');

    expect(
      find.text('Hitung campuran pakan sebelum digunakan untuk evaluasi.'),
      findsOneWidget,
    );
  });

  testWidgets('draft evaluation action rejects after mutation', (tester) async {
    await pumpScreen(tester, modePilihUntukEvaluasi: true);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    await enterDraftValue(tester, 0, '5');
    await tapText(tester, 'Gunakan untuk Evaluasi');

    expect(
      find.text('Hitung campuran pakan sebelum digunakan untuk evaluasi.'),
      findsOneWidget,
    );
  });

  testWidgets('draft mutation invalidates successful snapshot', (tester) async {
    await pumpScreen(tester);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    expect(find.text('Perhitungan berhasil'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.pump();

    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('load completion after unmount does not update state', (
    tester,
  ) async {
    final source = _BlockingSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CekKandunganNutrisiScreen(
          repository: createRepository(source: source),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    source.result.complete([_bahan]);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('master screen accepts injected repository', (tester) async {
    final repository = createRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MasterPakanScreen(repository: repository),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Rumput Gajah'), findsOneWidget);
    expect(find.text('Rumput Odot'), findsOneWidget);
  });

  testWidgets('master refresh remaps draft feeds by ID', (tester) async {
    final source = _MutableSource([_bahan, _bahanKedua]);
    final repository = createRepository(source: source);
    await pumpScreen(tester, repository: repository);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    source.data = [_bahan.copyWith(nama: 'Rumput Gajah Segar'), _bahanKedua];
    await tester.tap(find.byTooltip('Database Pakan'));
    await tester.pump(const Duration(seconds: 1));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Rumput Gajah Segar'), findsOneWidget);
    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('master refresh removes draft feed deleted by ID', (
    tester,
  ) async {
    final source = _MutableSource([_bahan, _bahanKedua]);
    final repository = createRepository(source: source);
    await pumpScreen(tester, repository: repository);
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');

    source.data = [_bahanKedua];
    await tester.tap(find.byTooltip('Database Pakan'));
    await tester.pump(const Duration(seconds: 1));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Rumput Gajah'), findsNothing);
    expect(find.text('Belum dihitung'), findsOneWidget);
    expect(find.text('Kandungan Campuran Pakan'), findsNothing);
  });

  testWidgets('non-finite aggregate result sets gagal', (tester) async {
    final invalidFeed = _bahan.copyWith(protein: double.nan);
    await pumpScreen(tester, repository: createRepository(data: [invalidFeed]));
    await addFeedAndSetWeight(tester, '10');

    await tapText(tester, 'Hitung');

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.text('Data bahan pakan yang dipilih tidak valid.'),
      findsWidgets,
    );
  });

  testWidgets('evaluation mode returns latest successful snapshot', (
    tester,
  ) async {
    final result = Completer<Object?>();
    final repository = createRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            Future<void>.microtask(() async {
              final value = await Navigator.push<HasilPakanTerpilih>(
                context,
                MaterialPageRoute(
                  builder: (_) => CekKandunganNutrisiScreen(
                    modePilihUntukEvaluasi: true,
                    repository: repository,
                  ),
                ),
              );
              result.complete(value);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await addFeedAndSetWeight(tester, '10');
    await tapText(tester, 'Hitung');
    await tapText(tester, 'Gunakan untuk Evaluasi');

    final value = await result.future;
    expect(value, isA<HasilPakanTerpilih>());
    expect((value! as HasilPakanTerpilih).totalBeratKg, 10);
  });
}
