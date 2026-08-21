import 'package:dipo_feed/core/theme/app_theme.dart';
import 'package:dipo_feed/core/widgets/app_comparison_bar.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_repository.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/evaluasi_standar_nutrien.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/widgets/evaluasi_standar_card.dart';
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

BahanPakan _bahan({
  required int id,
  required String nama,
  required String kategori,
  double hargaDefault = 100,
}) {
  return BahanPakan(
    id: id,
    nama: nama,
    kategori: kategori,
    bk: 30,
    abu: 2,
    lemak: 3,
    serat: 4,
    protein: 5,
    betn: 6,
    tdn: 7,
    me: 8,
    hargaDefault: hargaDefault,
    isActive: true,
  );
}

BahanPakanRepository _repository(Iterable<BahanPakan> data) {
  return BahanPakanRepository.forTesting(_MemorySource(data.toList()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rejects every malformed persisted BahanPakan numeric field', () {
    final valid = _bahan(id: 1, nama: 'Valid', kategori: 'hijauan');
    final malformed = <String, BahanPakan>{
      'BK': valid.copyWith(bk: double.nan),
      'abu': valid.copyWith(abu: double.infinity),
      'lemak': valid.copyWith(lemak: -1),
      'serat': valid.copyWith(serat: double.nan),
      'PK': valid.copyWith(protein: -1),
      'BETN': valid.copyWith(betn: double.infinity),
      'TDN': valid.copyWith(tdn: -1),
      'ME': valid.copyWith(me: double.nan),
      'harga': valid.copyWith(hargaDefault: -1),
      'Ca': valid.copyWith(ca: double.infinity),
      'P': valid.copyWith(p: -1),
    };

    for (final entry in malformed.entries) {
      expect(entry.value.isValidForCalculation(), isFalse, reason: entry.key);
    }
    expect(valid.copyWith(bk: 0).isValidForCalculation(), isTrue);
    expect(
      valid.copyWith(bk: 0).isValidForCalculation(requirePositiveBk: true),
      isFalse,
    );
  });

  testWidgets('comparison bar formats visible values as Indonesian numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppComparisonBar(
            label: 'BK',
            current: 1234.5,
            limit: 2000,
            unit: 'kg',
          ),
        ),
      ),
    );

    expect(find.text('1.234,50 / 2.000,00 kg'), findsOneWidget);
    expect(find.text('Butuh 765,50 lagi'), findsOneWidget);
  });

  testWidgets('Cek Kecukupan rejects feed at formatter magnitude limit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CekKecukupanPakanScreen(
          repository: _repository([_bahan(id: 1, nama: 'Ekstrem', kategori: 'hijauan').copyWith(bk: 1e21)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Bahan Pakan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.textContaining('Data bahan pakan tersimpan tidak valid'),
      findsOneWidget,
    );
  });

  testWidgets(
    'evaluation card formats visible decimal values as Indonesian numbers',
    (tester) async {
      const hasil = HasilPerhitunganNutrisi(
        totalBerat: 1234.5,
        totalBiaya: 1000000,
        hargaRataRata: 810,
        bk: 60,
        abu: 8,
        lemak: 4,
        serat: 18,
        protein: 12.345,
        tdn: 69,
        ca: 0.8,
        p: 0.5,
        me: 0,
      );
      final evaluasi = EvaluasiStandarNutrienHelper.evaluasi(
        hasil: hasil,
        fisiologi: FisiologiSapi.laktasi,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EvaluasiStandarCard(
                evaluasi: evaluasi,
                totalBeratKg: hasil.totalBerat,
                totalBiaya: hasil.totalBiaya,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1.234,50 kg'), findsOneWidget);
      expect(find.text('12,35%'), findsOneWidget);
    },
  );

  testWidgets('Cek Kecukupan rejects malformed persisted feed before success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CekKecukupanPakanScreen(
          repository: _repository([
            _bahan(
              id: 1,
              nama: 'Pakan Harga Rusak',
              kategori: 'hijauan',
              hargaDefault: -1,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tambah Bahan Pakan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tambah Bahan Pakan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.textContaining('Data bahan pakan tersimpan tidak valid'),
      findsOneWidget,
    );
  });

  testWidgets('Rekomendasi rejects malformed persisted feed before success', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RekomendasiPakanScreen(
          repository: _repository([
            _bahan(
              id: 1,
              nama: 'Hijauan Harga Rusak',
              kategori: 'hijauan',
              hargaDefault: double.nan,
            ),
            _bahan(id: 2, nama: 'Konsentrat Valid', kategori: 'konsentrat'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tambah Hijauan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tambah Hijauan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BahanPakan>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijauan Harga Rusak'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Tambah Konsentrat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tambah Konsentrat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BahanPakan>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konsentrat Valid'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal menghitung'), findsOneWidget);
    expect(
      find.textContaining('Data bahan pakan tersimpan tidak valid'),
      findsOneWidget,
    );
  });

  testWidgets('Rekomendasi does not render feed above formatter magnitude', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: RekomendasiPakanScreen(
          repository: _repository([
            _bahan(
              id: 1,
              nama: 'Hijauan Ekstrem',
              kategori: 'hijauan',
            ).copyWith(bk: 1e21),
            _bahan(id: 2, nama: 'Konsentrat Valid', kategori: 'konsentrat'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Tambah Hijauan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BahanPakan>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hijauan Ekstrem'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Data bahan pakan tidak valid.'), findsOneWidget);
  });
}
