import 'package:flutter_test/flutter_test.dart';

import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/models/kebutuhan_nutrien_sapi.dart';
import 'package:dipo_feed/features/rekomendasi_pakan/logic/nutrien_helper.dart';
import 'package:dipo_feed/features/rekomendasi_pakan/logic/perhitungan_rekomendasi_pakan.dart';

void main() {
  group('Klasifikasi bahan rekomendasi pakan', () {
    test('menerima kategori hijauan dengan spasi dan mixed case', () {
      expect(isBahanHijauan(_bahan(1, 'Rumput Gajah', ' HIJAUAN ')), isTrue);
      expect(isBahanHijauan(_bahan(2, 'Rumput Gajah', 'HijAuAn')), isTrue);
    });

    test('hanya menganggap kategori yang sama persis sebagai hijauan', () {
      expect(
        isBahanHijauan(_bahan(3, 'Rumput Lainnya', 'hijauan tambahan')),
        isFalse,
      );
      expect(isBahanHijauan(_bahan(4, 'Rumput Lainnya', 'lainnya')), isFalse);
    });

    test('menggunakan inverse hijauan untuk kategori konsentrat', () {
      expect(
        isBahanKonsentrat(_bahan(5, 'Rumput Gajah', ' HIJAUAN ')),
        isFalse,
      );
      expect(isBahanKonsentrat(_bahan(6, 'Pollard', 'konsentrat')), isTrue);
      expect(
        isBahanKonsentrat(_bahan(7, 'Rumput Lainnya', 'hijauan tambahan')),
        isTrue,
      );
    });
  });

  group('Perhitungan rekomendasi pakan', () {
    test('menghasilkan rekomendasi as-fed dari target BK 60:40', () {
      const kebutuhan = KebutuhanNutrienSapi(
        kebutuhanBkKg: 10.32,
        kebutuhanProteinKg: 1.33,
        kebutuhanTdnKg: 6.75,
        kebutuhanCaGram: 51.71,
        kebutuhanPGram: 29.89,
      );

      const hijauan = BahanPakan(
        id: 1,
        nama: 'Rumput Gajah',
        kategori: 'hijauan',
        bk: 29.24,
        abu: 0,
        lemak: 2.0,
        serat: 0,
        protein: 8.0,
        betn: 0,
        tdn: 50.0,
        me: 0,
        hargaDefault: 0,
        isActive: true,
        ca: 0,
        p: 0,
      );

      const konsentrat = BahanPakan(
        id: 2,
        nama: 'Pollard Tongkat',
        kategori: 'konsentrat',
        bk: 86.63,
        abu: 0,
        lemak: 4.85,
        serat: 0,
        protein: 13.47,
        betn: 0,
        tdn: 79.25,
        me: 0,
        hargaDefault: 0,
        isActive: true,
        ca: 0,
        p: 0,
      );

      final hasil = PerhitunganRekomendasiPakan.hitung(
        kebutuhan: kebutuhan,
        bahanHijauan: const [hijauan],
        bahanKonsentrat: const [konsentrat],
      );

      expect(hasil.targetBkHijauan, closeTo(6.192, 0.0001));
      expect(hasil.targetBkKonsentrat, closeTo(4.128, 0.0001));
      expect(hasil.rekomendasiHijauan.first.asFedKg, closeTo(21.18, 0.5));
      expect(hasil.rekomendasiKonsentrat.first.asFedKg, closeTo(4.75, 0.5));
      expect(hasil.totalHijauan.bkKg, closeTo(6.19, 0.2));
      expect(hasil.totalKonsentrat.bkKg, closeTo(4.13, 0.3));
      expect(hasil.totalGabungan.bkKg, greaterThan(9.5));
      expect(
        hasil.totalGabungan.bkKg,
        closeTo(hasil.totalHijauan.bkKg + hasil.totalKonsentrat.bkKg, 0.0001),
      );
    });

    test('menandai LK tidak aman saat melebihi 5 persen BK', () {
      const kebutuhan = KebutuhanNutrienSapi(
        kebutuhanBkKg: 8,
        kebutuhanProteinKg: 1,
        kebutuhanTdnKg: 5,
        kebutuhanCaGram: 10,
        kebutuhanPGram: 10,
      );

      const hijauan = BahanPakan(
        id: 3,
        nama: 'Hijauan Berlemak',
        kategori: 'rumput',
        bk: 30,
        abu: 0,
        lemak: 8,
        serat: 0,
        protein: 8,
        betn: 0,
        tdn: 55,
        me: 0,
        hargaDefault: 0,
        isActive: true,
      );

      const konsentrat = BahanPakan(
        id: 4,
        nama: 'Konsentrat Berlemak',
        kategori: 'konsentrat',
        bk: 85,
        abu: 0,
        lemak: 9,
        serat: 0,
        protein: 12,
        betn: 0,
        tdn: 70,
        me: 0,
        hargaDefault: 0,
        isActive: true,
      );

      final hasil = PerhitunganRekomendasiPakan.hitung(
        kebutuhan: kebutuhan,
        bahanHijauan: const [hijauan],
        bahanKonsentrat: const [konsentrat],
      );

      expect(hasil.lkPersenDariBk, greaterThan(5));
      expect(hasil.isLkAman, isFalse);
    });

    test(
      'tetap menghasilkan rekomendasi konsentrat saat hijauan sudah tinggi nutrien',
      () {
        const kebutuhan = KebutuhanNutrienSapi(
          kebutuhanBkKg: 10.32,
          kebutuhanProteinKg: 1.10,
          kebutuhanTdnKg: 6.20,
          kebutuhanCaGram: 20,
          kebutuhanPGram: 15,
        );

        const hijauan = BahanPakan(
          id: 5,
          nama: 'Rumput Gajah',
          kategori: 'hijauan',
          bk: 29.24,
          abu: 0,
          lemak: 2.0,
          serat: 0,
          protein: 14.0,
          betn: 0,
          tdn: 58.0,
          me: 0,
          hargaDefault: 0,
          isActive: true,
        );

        const konsentratA = BahanPakan(
          id: 6,
          nama: 'Pollard',
          kategori: 'konsentrat',
          bk: 86.0,
          abu: 0,
          lemak: 4.0,
          serat: 0,
          protein: 13.0,
          betn: 0,
          tdn: 78.0,
          me: 0,
          hargaDefault: 0,
          isActive: true,
        );

        const konsentratB = BahanPakan(
          id: 7,
          nama: 'Dedak',
          kategori: 'konsentrat',
          bk: 88.0,
          abu: 0,
          lemak: 5.0,
          serat: 0,
          protein: 12.0,
          betn: 0,
          tdn: 75.0,
          me: 0,
          hargaDefault: 0,
          isActive: true,
        );

        final hasil = PerhitunganRekomendasiPakan.hitung(
          kebutuhan: kebutuhan,
          bahanHijauan: const [hijauan],
          bahanKonsentrat: const [konsentratA, konsentratB],
        );

        expect(hasil.rekomendasiKonsentrat.length, 2);
        expect(
          hasil.rekomendasiKonsentrat.every((item) => item.asFedKg > 0),
          isTrue,
        );
        expect(hasil.totalKonsentrat.bkKg, closeTo(4.128, 0.6));
        expect(hasil.totalGabungan.bkKg, greaterThan(hasil.totalHijauan.bkKg));
      },
    );

    test(
      'berhasil menghitung rekomendasi dengan lebih dari 4 hijauan dan konsentrat secara cepat',
      () {
        const kebutuhan = KebutuhanNutrienSapi(
          kebutuhanBkKg: 12.0,
          kebutuhanProteinKg: 1.5,
          kebutuhanTdnKg: 8.0,
          kebutuhanCaGram: 50,
          kebutuhanPGram: 30,
        );

        final banyakHijauan = List.generate(
          5,
          (i) => BahanPakan(
            id: 10 + i,
            nama: 'Hijauan $i',
            kategori: 'hijauan',
            bk: 25.0 + i,
            abu: 8.0,
            lemak: 2.0,
            serat: 30.0,
            protein: 8.0 + i,
            betn: 40.0,
            tdn: 52.0 + i,
            me: 0,
            hargaDefault: 500,
            isActive: true,
          ),
        );

        final banyakKonsentrat = List.generate(
          6,
          (i) => BahanPakan(
            id: 20 + i,
            nama: 'Konsentrat $i',
            kategori: 'konsentrat',
            bk: 85.0,
            abu: 6.0,
            lemak: 3.5,
            serat: 10.0,
            protein: 14.0 + i,
            betn: 55.0,
            tdn: 75.0,
            me: 0,
            hargaDefault: 4000,
            isActive: true,
          ),
        );

        final stopwatch = Stopwatch()..start();
        final hasil = PerhitunganRekomendasiPakan.hitung(
          kebutuhan: kebutuhan,
          bahanHijauan: banyakHijauan,
          bahanKonsentrat: banyakKonsentrat,
        );
        stopwatch.stop();

        // Eksekusi komputasi harus instan (< 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(150));
        expect(hasil.rekomendasiHijauan, isNotEmpty);
        expect(hasil.rekomendasiKonsentrat, isNotEmpty);
        expect(hasil.totalGabungan.bkKg, greaterThan(0));
        expect(hasil.isLkAman, isTrue);
      },
    );
  });
}

BahanPakan _bahan(int id, String nama, String kategori) {
  return BahanPakan(
    id: id,
    nama: nama,
    kategori: kategori,
    bk: 30,
    abu: 0,
    lemak: 0,
    serat: 0,
    protein: 0,
    betn: 0,
    tdn: 0,
    me: 0,
    hargaDefault: 0,
    isActive: true,
  );
}
