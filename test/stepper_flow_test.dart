import 'package:dipo_feed/core/theme/app_theme.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_repository.dart';
import 'package:dipo_feed/core/widgets/app_sliver_header.dart';
import 'package:dipo_feed/core/widgets/app_text_field.dart';
import 'package:dipo_feed/features/cek_kecukupan_pakan/cek_kecukupan_pakan_screen.dart';
import 'package:dipo_feed/features/rekomendasi_pakan/rekomendasi_pakan_screen.dart';
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
  nama: 'Dedak Padi',
  kategori: 'konsentrat',
  bk: 88.0,
  abu: 8.0,
  lemak: 4.0,
  serat: 10.0,
  protein: 12.0,
  betn: 66.0,
  tdn: 70.0,
  me: 10.0,
  hargaDefault: 2000,
  isActive: true,
);

const _bahanHijauanKedua = BahanPakan(
  id: 3,
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
  bool twoFeeds = false,
  bool twoForages = false,
}) {
  final data = twoForages
      ? [_bahan, _bahanHijauanKedua]
      : twoFeeds
      ? [_bahan, _bahanKedua]
      : [_bahan];
  return BahanPakanRepository.forTesting(_MemorySource(data));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester, {bool twoFeeds = false}) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CekKecukupanPakanScreen(
          repository: createRepository(twoFeeds: twoFeeds),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    if (label == 'Lanjut' ||
        label == 'Lanjut ke Komposisi Pakan' ||
        label == 'Lanjut ke Pemberian Pakan' ||
        label == 'Hitung & Evaluasi') {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> tapHeaderBack(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pump();
  }

  Future<void> pumpRecommendationScreen(
    WidgetTester tester, {
    bool twoForages = false,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RekomendasiPakanScreen(
          repository: createRepository(
            twoFeeds: !twoForages,
            twoForages: twoForages,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> tapRecommendationFeed(
    WidgetTester tester,
    String addLabel,
    String feedLabel,
  ) async {
    await tapButton(tester, addLabel);
    final dropdowns = find.byType(DropdownButtonFormField<BahanPakan>);
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(feedLabel).last);
    await tester.pump();
  }

  Future<void> tapFeedAdd(WidgetTester tester) async {
    final target = find.ancestor(
      of: find.text('Tambah Bahan Pakan'),
      matching: find.byType(OutlinedButton),
    );
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(target);
    await tester.pumpAndSettle();
    final availableItems = find.byWidgetPredicate(
      (w) => w is ListTile && w.enabled == true,
    );
    if (availableItems.evaluate().isNotEmpty) {
      await tester.tap(availableItems.first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('starts at Data Sapi stage', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(AppSliverHeader), findsOneWidget);
    expect(find.text('Cek Kecukupan Pakan'), findsNWidgets(2));
    expect(find.text('Data Sapi'), findsNWidgets(2));
    expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
    expect(find.textContaining('Data Sapi & Kebutuhan Nutrien'), findsOneWidget);
    expect(find.text('Hasil Evaluasi Nutrisi'), findsNothing);
    expect(find.text('Lanjut ke Komposisi Pakan'), findsOneWidget);
    expect(find.text('Kembali'), findsNothing);
  });

  testWidgets('blocks stage one until profile is valid', (tester) async {
    await pumpScreen(tester);

    await tapButton(tester, 'Lanjut ke Komposisi Pakan');

    expect(find.text('BB wajib diisi'), findsOneWidget);
    expect(find.text('Pemberian Pakan'), findsNothing);
  });

  testWidgets('valid profile opens nutrient and feed stage', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.pump();

    // In Step 1, Kebutuhan Nutrien card is visible realtime
    expect(find.text('Kebutuhan Nutrien'), findsOneWidget);

    await tapButton(tester, 'Lanjut ke Komposisi Pakan');

    expect(find.byType(AppSliverHeader), findsNothing);
    expect(find.text('Cek Kecukupan Pakan'), findsOneWidget);
    expect(find.textContaining('Tahap 2 dari 3'), findsOneWidget);
    expect(find.text('Pemberian Pakan'), findsOneWidget);
    expect(find.text('Tambah Bahan Pakan'), findsOneWidget);
  });

  testWidgets('accepts grouped Indonesian profile input', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '1.234,50');
    await tester.pump();

    expect(find.text('Kebutuhan Nutrien'), findsOneWidget);

    await tapButton(tester, 'Lanjut ke Komposisi Pakan');
    expect(find.text('Pemberian Pakan'), findsOneWidget);
  });

  testWidgets('rejects finite overflowed requirement targets', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byType(DropdownButtonFormField<FisiologiSapi>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laktasi').last);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.enterText(find.byType(TextFormField).at(1), '1e308');
    await tester.enterText(find.byType(TextFormField).at(2), '1e308');
    await tester.pump();

    expect(find.text('Infinity'), findsNothing);
    expect(find.text('Standar: Laktasi (NRC 1988)'), findsNothing);
    await tapButton(tester, 'Lanjut ke Komposisi Pakan');

    expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
    expect(find.text('Pemberian Pakan'), findsNothing);
  });

  testWidgets('stage two header back returns to stage one', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut ke Komposisi Pakan');

    expect(find.textContaining('Tahap 2 dari 3'), findsOneWidget);
    await tapHeaderBack(tester);

    expect(find.text('Data Sapi'), findsNWidgets(2));
    expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
  });

  testWidgets('back navigation preserves profile data', (tester) async {
    await pumpScreen(tester);
    final weightField = find.byType(TextFormField).first;
    await tester.enterText(weightField, '500');
    await tapButton(tester, 'Lanjut ke Komposisi Pakan');
    await tapHeaderBack(tester);

    expect(find.text('Data Sapi'), findsNWidgets(2));
    expect(find.byType(TextFormField).first, findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '500',
    );
  });

  testWidgets(
    'valid feed and calculate button opens stage 3 evaluation card with expand option',
    (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextFormField).first, '500');
      await tapButton(tester, 'Lanjut ke Komposisi Pakan');
      await tapFeedAdd(tester);
      await tester.enterText(find.byType(TextField).first, '1.234,50');
      await tester.pumpAndSettle();

      await tapButton(tester, 'Hitung & Evaluasi');
      await tester.pumpAndSettle();

      // Step 3 displays evaluation card and summary
      expect(find.textContaining('Tahap 3 dari 3'), findsOneWidget);
      expect(find.text('Hasil Evaluasi Nutrisi'), findsOneWidget);
      expect(find.text('Komposisi Pakan Diberikan'), findsOneWidget);
      expect(find.text('Tutup Detail'), findsOneWidget);
    },
  );

  testWidgets('deleting feed row preserves remaining quantity state', (
    tester,
  ) async {
    await pumpScreen(tester, twoFeeds: true);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut ke Komposisi Pakan');
    await tapFeedAdd(tester);
    await tester.enterText(find.byType(TextField).at(0), '10');
    await tapFeedAdd(tester);
    await tester.enterText(find.byType(TextField).at(1), '20');

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.byType(AppTextField), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).last)
          .controller
          .text,
      '20',
    );
  });

  Future<void> selectLaktasi(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<FisiologiSapi>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laktasi').last);
    await tester.pump();
  }

  for (final invalidValue in ['NaN', 'Infinity', '1e21']) {
    testWidgets('rejects invalid BB value $invalidValue', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(find.byType(TextFormField).first, invalidValue);
      await tapButton(tester, 'Lanjut ke Komposisi Pakan');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
    });

    testWidgets('rejects invalid produksi susu value $invalidValue', (
      tester,
    ) async {
      await pumpScreen(tester);
      await selectLaktasi(tester);
      await tester.enterText(find.byType(TextFormField).at(1), invalidValue);
      await tapButton(tester, 'Lanjut ke Komposisi Pakan');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
    });

    testWidgets('rejects invalid lemak susu value $invalidValue', (
      tester,
    ) async {
      await pumpScreen(tester);
      await selectLaktasi(tester);
      await tester.enterText(find.byType(TextFormField).at(2), invalidValue);
      await tapButton(tester, 'Lanjut ke Komposisi Pakan');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.textContaining('Tahap 1 dari 3'), findsOneWidget);
    });
  }

  testWidgets('profile edit updates requirement and navigation flow', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut ke Komposisi Pakan');
    await tapFeedAdd(tester);
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.pumpAndSettle();

    await tapHeaderBack(tester);
    await tester.enterText(find.byType(TextFormField).first, '600');
    await tester.pumpAndSettle();

    expect(find.text('Kebutuhan Nutrien'), findsOneWidget);

    await tapButton(tester, 'Lanjut ke Komposisi Pakan');
    await tester.pumpAndSettle();

    expect(find.textContaining('Tahap 2 dari 3'), findsOneWidget);
  });

  for (final invalidQuantity in ['abc', 'NaN', 'Infinity', '-1']) {
    testWidgets(
      'blocks result when one feed quantity is invalid: $invalidQuantity',
      (tester) async {
        await pumpScreen(tester, twoFeeds: true);
        await tester.enterText(find.byType(TextFormField).first, '500');
        await tapButton(tester, 'Lanjut ke Komposisi Pakan');
        await tapFeedAdd(tester);
        await tester.enterText(find.byType(TextField).at(0), '10');
        await tapFeedAdd(tester);
        await tester.enterText(
          find.byType(TextField).at(1),
          invalidQuantity,
        );
        await tester.pumpAndSettle();

        await tapButton(tester, 'Hitung & Evaluasi');
        await tester.pumpAndSettle();

        expect(find.textContaining('Tahap 2 dari 3'), findsOneWidget);
        expect(find.text('Hasil Evaluasi Nutrisi'), findsNothing);
      },
    );
  }

  testWidgets('recommendation starts at Data Sapi stage', (tester) async {
    await pumpRecommendationScreen(tester);

    expect(find.text('Data Sapi'), findsNWidgets(2));
    expect(find.text('Tahap 1 dari 3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Bahan Pakan Tersedia'), findsNothing);
    expect(find.text('Hasil Rekomendasi'), findsNothing);
    expect(find.text('Lanjut'), findsOneWidget);
    expect(find.text('Kembali'), findsNothing);
  });

  testWidgets('recommendation stage two header back returns to stage one', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');

    expect(find.text('Kembali'), findsNothing);
    expect(find.text('Lanjut'), findsOneWidget);
    await tapHeaderBack(tester);

    expect(find.text('Data Sapi'), findsNWidgets(2));
    expect(find.text('Tahap 1 dari 3'), findsOneWidget);
  });

  testWidgets('recommendation blocks stage two until profile is valid', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);

    await tapButton(tester, 'Lanjut');

    expect(find.text('BB wajib diisi'), findsOneWidget);
    expect(find.text('Bahan Pakan Tersedia'), findsNothing);
  });

  testWidgets('valid recommendation profile opens available feed stage', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');

    expect(find.text('Bahan Pakan Tersedia'), findsWidgets);
    expect(find.text('Tambah Hijauan'), findsOneWidget);
    expect(find.text('Tambah Konsentrat'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
  });

  testWidgets('accepts grouped Indonesian recommendation profile input', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '1.234,50');
    await tapButton(tester, 'Lanjut');

    expect(find.text('Bahan Pakan Tersedia'), findsWidgets);
  });

  for (final invalidValue in ['NaN', 'Infinity', '1e21']) {
    testWidgets('recommendation rejects invalid BB $invalidValue', (
      tester,
    ) async {
      await pumpRecommendationScreen(tester);
      await tester.enterText(find.byType(TextFormField).first, invalidValue);
      await tester.pump();
      await tapButton(tester, 'Lanjut');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.text('Tahap 1 dari 3'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == invalidValue,
        ),
        findsNothing,
      );
    });

    testWidgets('recommendation rejects invalid produksi susu $invalidValue', (
      tester,
    ) async {
      await pumpRecommendationScreen(tester);
      await selectLaktasi(tester);
      await tester.enterText(find.byType(TextFormField).first, '500');
      await tester.enterText(find.byType(TextFormField).at(1), invalidValue);
      await tester.enterText(find.byType(TextFormField).at(2), '3,5');
      await tester.pump();
      await tapButton(tester, 'Lanjut');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.text('Tahap 1 dari 3'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == invalidValue,
        ),
        findsNothing,
      );
    });

    testWidgets('recommendation rejects invalid lemak susu $invalidValue', (
      tester,
    ) async {
      await pumpRecommendationScreen(tester);
      await selectLaktasi(tester);
      await tester.enterText(find.byType(TextFormField).first, '500');
      await tester.enterText(find.byType(TextFormField).at(1), '13');
      await tester.enterText(find.byType(TextFormField).at(2), invalidValue);
      await tester.pump();
      await tapButton(tester, 'Lanjut');

      expect(find.text('Angka tidak valid'), findsWidgets);
      expect(find.text('Tahap 1 dari 3'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data == invalidValue,
        ),
        findsNothing,
      );
    });
  }

  testWidgets('recommendation hides selected feed from other row options', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester, twoForages: true);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapButton(tester, 'Tambah Hijauan');

    final secondDropdown = find
        .byType(DropdownButtonFormField<BahanPakan>)
        .last;
    await tester.tap(secondDropdown);
    await tester.pumpAndSettle();

    expect(find.text('Rumput Gajah'), findsOneWidget);
    expect(find.text('Rumput Odot'), findsOneWidget);
  });

  testWidgets('recommendation retains row identity after forage removal', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester, twoForages: true);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Odot');

    const secondKey = ValueKey<int>(1);
    expect(find.byKey(secondKey), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();

    expect(find.byKey(secondKey), findsOneWidget);
  });

  testWidgets('recommendation caps selected feeds per group', (tester) async {
    await pumpRecommendationScreen(tester, twoForages: true);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');

    for (var i = 0; i < 4; i++) {
      await tapButton(tester, 'Tambah Hijauan');
    }
    expect(find.byType(DropdownButtonFormField<BahanPakan>), findsNWidgets(4));

    await tapButton(tester, 'Tambah Hijauan');

    expect(find.byType(DropdownButtonFormField<BahanPakan>), findsNWidgets(4));
    expect(find.text('Maksimal 4 bahan hijauan.'), findsOneWidget);
  });

  testWidgets('recommendation rejects finite overflowed nutrient targets', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await selectLaktasi(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tester.enterText(find.byType(TextFormField).at(1), '1e308');
    await tester.enterText(find.byType(TextFormField).at(2), '3,5');
    await tester.pump();

    expect(find.text('Target kebutuhan nutrien tidak valid.'), findsOneWidget);
    expect(find.text('NaN'), findsNothing);
    expect(find.text('Infinity'), findsNothing);

    await tapButton(tester, 'Lanjut');
    expect(find.text('Bahan Pakan Tersedia'), findsNothing);
  });

  testWidgets('recommendation requires forage and concentrate before result', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapButton(tester, 'Lanjut');

    expect(find.text('Tambahkan minimal satu konsentrat.'), findsWidgets);
    expect(find.text('Hasil Rekomendasi'), findsNothing);
  });

  testWidgets('recommendation back navigation preserves profile and feeds', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapRecommendationFeed(tester, 'Tambah Konsentrat', 'Dedak Padi');
    await tapButton(tester, 'Lanjut');
    await tapHeaderBack(tester);

    expect(find.text('Bahan Pakan Tersedia'), findsWidgets);
    expect(find.text('Rumput Gajah'), findsOneWidget);
    expect(find.text('Dedak Padi'), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<BahanPakan>), findsNWidgets(2));

    await tapHeaderBack(tester);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '500',
    );
  });

  testWidgets('complete recommendation opens inline result stage', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapRecommendationFeed(tester, 'Tambah Konsentrat', 'Dedak Padi');
    await tapButton(tester, 'Lanjut');

    expect(find.text('Hasil Rekomendasi'), findsWidgets);
    expect(find.text('Hasil Analisis Ransum Pakan'), findsOneWidget);
    expect(find.text('Lanjut'), findsNothing);
  });

  testWidgets('editing recommendation profile invalidates result', (
    tester,
  ) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapRecommendationFeed(tester, 'Tambah Konsentrat', 'Dedak Padi');
    await tapButton(tester, 'Lanjut');
    await tapHeaderBack(tester);
    await tapHeaderBack(tester);
    await tester.enterText(find.byType(TextFormField).first, '600');
    await tester.pump();
    await tapButton(tester, 'Lanjut');

    expect(find.text('Hasil Rekomendasi'), findsNothing);
    expect(find.text('Bahan Pakan Tersedia'), findsWidgets);
  });

  testWidgets('editing recommendation feed invalidates result', (tester) async {
    await pumpRecommendationScreen(tester);
    await tester.enterText(find.byType(TextFormField).first, '500');
    await tapButton(tester, 'Lanjut');
    await tapRecommendationFeed(tester, 'Tambah Hijauan', 'Rumput Gajah');
    await tapRecommendationFeed(tester, 'Tambah Konsentrat', 'Dedak Padi');
    await tapButton(tester, 'Lanjut');
    await tapHeaderBack(tester);

    final forageDropdown = find
        .byType(DropdownButtonFormField<BahanPakan>)
        .first;
    await tester.tap(forageDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rumput Gajah').last);
    await tester.pump();

    expect(find.text('Hasil Rekomendasi'), findsNothing);
    await tapButton(tester, 'Lanjut');
    expect(find.text('Hasil Rekomendasi'), findsWidgets);
  });
}
