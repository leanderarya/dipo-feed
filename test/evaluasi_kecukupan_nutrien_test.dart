import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/models/campuran_pakan_item.dart';
import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/data/models/kebutuhan_nutrien_sapi.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'package:dipo_feed/features/cek_kecukupan_pakan/logic/evaluasi_kecukupan_nutrien.dart';
import 'package:dipo_feed/features/cek_kecukupan_pakan/widgets/evaluasi_kecukupan_card.dart';

void main() {
  group('EvaluasiKecukupanNutrien Tests', () {
    test('menghitung evaluasi kecukupan dengan benar', () {
      const kebutuhan = KebutuhanNutrienSapi(
        kebutuhanBkKg: 10.0,
        kebutuhanProteinKg: 1.2,
        kebutuhanTdnKg: 6.5,
        kebutuhanCaGram: 45.0,
        kebutuhanPGram: 30.0,
      );

      const nutrisiPemberian = HasilPerhitunganNutrisi(
        totalBerat: 25.0,
        totalBiaya: 50000,
        hargaRataRata: 2000,
        bk: 40.0, // 25 * 0.4 = 10.0 kg BK (Pas 100%)
        abu: 5.0,
        lemak: 3.0,
        serat: 20.0,
        protein: 4.8, // 25 * 0.048 = 1.2 kg PK (Pas 100%)
        tdn: 26.0, // 25 * 0.26 = 6.5 kg TDN (Pas 100%)
        ca: 0.0,
        p: 0.0,
        me: 2.2,
      );

      final hasil = HasilEvaluasiKecukupanNutrien.hitung(
        fisiologi: FisiologiSapi.dara,
        kebutuhan: kebutuhan,
        nutrisiPemberian: nutrisiPemberian,
      );

      expect(hasil.bk.pemberian, 10.0);
      expect(hasil.bk.kebutuhan, 10.0);
      expect(hasil.bk.status, StatusKecukupanNutrien.pas);

      expect(hasil.protein.pemberian, closeTo(1.2, 0.001));
      expect(hasil.protein.status, StatusKecukupanNutrien.pas);

      expect(hasil.tdn.pemberian, closeTo(6.5, 0.001));
      expect(hasil.tdn.status, StatusKecukupanNutrien.pas);

      // Ca & P 0
      expect(hasil.ca.status, StatusKecukupanNutrien.kurang);
      expect(hasil.p.status, StatusKecukupanNutrien.kurang);

      expect(
        hasil.kesimpulanUmum,
        'Pakan yang diberikan belum mencukupi seluruh kebutuhan nutrien sapi.',
      );
    });

    test('status berlebih ketika pemberian > 105% kebutuhan', () {
      const item = EvaluasiKecukupanItem(
        nama: 'Bahan Kering',
        singkatan: 'BK',
        kebutuhan: 10.0,
        pemberian: 11.0,
        satuan: 'kg',
      );
      expect(item.status, StatusKecukupanNutrien.berlebih);
      expect(item.selisih, 1.0);
      expect(item.labelLengkap, 'BK (Bahan Kering)');
    });

    test('status kurang ketika pemberian < 95% kebutuhan', () {
      const item = EvaluasiKecukupanItem(
        nama: 'Protein Kasar',
        singkatan: 'PK',
        kebutuhan: 1.0,
        pemberian: 0.8,
        satuan: 'kg',
      );
      expect(item.status, StatusKecukupanNutrien.kurang);
      expect(item.selisih, closeTo(-0.2, 0.001));
      expect(item.labelLengkap, 'PK (Protein Kasar)');
    });

    test('menghitung kontribusi nutrien per bahan dalam satuan kg', () {
      const bahan = BahanPakan(
        id: 1,
        nama: 'Rumput Gajah',
        kategori: 'hijauan',
        bk: 22.10,
        abu: 17.90,
        lemak: 1.27,
        serat: 31.21,
        protein: 10.20,
        betn: 40.27,
        tdn: 55.00,
        me: 8.24,
        hargaDefault: 500,
        isActive: true,
      );

      final item = CampuranPakanItem(
        bahan: bahan,
        jumlahKg: 25.0,
        hargaPerKg: 500,
      );

      final kontribusi = KontribusiNutrisiBahanPakan.fromItem(item, index: 0);
      expect(kontribusi.bkKg, closeTo(5.525, 0.001));
      expect(kontribusi.pkKg, closeTo(2.55, 0.001));
      expect(kontribusi.tdnKg, closeTo(13.75, 0.001));
      expect(kontribusi.warna, getFeedColor(0));
    });

    test('HasilEvaluasiKecukupanNutrien menghasilkan segmen per bahan', () {
      const bahan1 = BahanPakan(
        id: 1,
        nama: 'Rumput Gajah',
        kategori: 'hijauan',
        bk: 20.0,
        abu: 10.0,
        lemak: 2.0,
        serat: 30.0,
        protein: 10.0,
        betn: 40.0,
        tdn: 50.0,
        me: 8.0,
        hargaDefault: 500,
        isActive: true,
      );

      const bahan2 = BahanPakan(
        id: 2,
        nama: 'Konsentrat',
        kategori: 'konsentrat',
        bk: 80.0,
        abu: 5.0,
        lemak: 4.0,
        serat: 10.0,
        protein: 15.0,
        betn: 50.0,
        tdn: 70.0,
        me: 10.0,
        hargaDefault: 3000,
        isActive: true,
      );

      final items = [
        CampuranPakanItem(bahan: bahan1, jumlahKg: 20.0, hargaPerKg: 500),
        CampuranPakanItem(bahan: bahan2, jumlahKg: 5.0, hargaPerKg: 3000),
      ];

      final nutrisi = PerhitunganNutrisi.hitungSemua(items);
      const kebutuhan = KebutuhanNutrienSapi(
        kebutuhanBkKg: 10.0,
        kebutuhanProteinKg: 2.0,
        kebutuhanTdnKg: 15.0,
        kebutuhanCaGram: 30.0,
        kebutuhanPGram: 20.0,
      );

      final hasil = HasilEvaluasiKecukupanNutrien.hitung(
        fisiologi: FisiologiSapi.dara,
        kebutuhan: kebutuhan,
        nutrisiPemberian: nutrisi,
        daftarPemberian: items,
      );

      expect(hasil.kontribusiBahan.length, 2);
      expect(hasil.bk.segmen.length, 2);
      expect(hasil.bk.segmen[0].namaBahan, 'Rumput Gajah');
      expect(hasil.bk.segmen[0].nilaiKg, closeTo(4.0, 0.001));
      expect(hasil.bk.segmen[1].namaBahan, 'Konsentrat');
      expect(hasil.bk.segmen[1].nilaiKg, closeTo(4.0, 0.001));
    });

    testWidgets('EvaluasiKecukupanCard renders compact mode and toggles to expanded', (
      tester,
    ) async {
      const kebutuhan = KebutuhanNutrienSapi(
        kebutuhanBkKg: 10.0,
        kebutuhanProteinKg: 1.2,
        kebutuhanTdnKg: 6.5,
        kebutuhanCaGram: 45.0,
        kebutuhanPGram: 30.0,
      );

      const nutrisiPemberian = HasilPerhitunganNutrisi(
        totalBerat: 25.0,
        totalBiaya: 50000,
        hargaRataRata: 2000,
        bk: 40.0,
        abu: 5.0,
        lemak: 3.0,
        serat: 20.0,
        protein: 4.8,
        tdn: 26.0,
        ca: 0.0,
        p: 0.0,
        me: 2.2,
      );

      final hasil = HasilEvaluasiKecukupanNutrien.hitung(
        fisiologi: FisiologiSapi.dara,
        kebutuhan: kebutuhan,
        nutrisiPemberian: nutrisiPemberian,
      );

      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EvaluasiKecukupanCard(hasil: hasil),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hasil Evaluasi Nutrisi'), findsOneWidget);
      expect(find.text('Lihat Detail'), findsOneWidget);
      expect(find.byType(StackedNutrientProgressBar), findsWidgets);

      // Tap Lihat Detail
      await tester.tap(find.text('Lihat Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Tutup Detail'), findsOneWidget);
      expect(find.text('Kesimpulan Umum'), findsOneWidget);

      // Tap Tutup Detail
      await tester.tap(find.text('Tutup Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Lihat Detail'), findsOneWidget);
    });
  });
}
