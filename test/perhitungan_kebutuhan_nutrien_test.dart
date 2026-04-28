import 'package:flutter_test/flutter_test.dart';

import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/features/cek_kecukupan_pakan/logic/perhitungan_kebutuhan_nutrien.dart';

void main() {
  group('Perhitungan kebutuhan nutrien Dara NRC 1978', () {
    test('menggunakan nilai tabel saat BB sama persis', () {
      final hasil =
          PerhitunganKebutuhanNutrien.hitungKebutuhanDaraNrc1978(200);

      expect(hasil.kebutuhanBkKg, 5.0);
      expect(hasil.kebutuhanTdnKg, 2.85);
      expect(hasil.kebutuhanProteinKg, 0.533);
      expect(hasil.kebutuhanCaGram, 18);
      expect(hasil.kebutuhanPGram, 12);
    });

    test('menggunakan interpolasi linear saat BB di antara tabel', () {
      final hasil =
          PerhitunganKebutuhanNutrien.hitungKebutuhanDaraNrc1978(175);

      expect(hasil.kebutuhanBkKg, closeTo(4.5, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(2.575, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(0.483, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(17, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(11, 0.0001));
    });

    test('menggunakan ekstrapolasi linear saat BB di bawah rentang', () {
      final hasil =
          PerhitunganKebutuhanNutrien.hitungKebutuhanDaraNrc1978(75);

      expect(hasil.kebutuhanBkKg, closeTo(2.2, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(1.385, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(0.259, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(13, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(5.5, 0.0001));
    });

    test('menggunakan ekstrapolasi linear saat BB di atas rentang', () {
      final hasil =
          PerhitunganKebutuhanNutrien.hitungKebutuhanDaraNrc1978(400);

      expect(hasil.kebutuhanBkKg, closeTo(7.79, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(4.58, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(0.731, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(24, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(17, 0.0001));
    });
  });

  group('Perhitungan kebutuhan nutrien Laktasi NRC 1988', () {
    test('menghasilkan nilai contoh BB 380 produksi 12 lemak 2.8', () {
      final hasil = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: FisiologiSapi.laktasi,
        beratBadan: 380,
        produksiSusuLiter: 12,
        lemakSusuPersen: 2.8,
      )!;

      expect(hasil.detail!.kgSusu, closeTo(12.336, 0.0001));
      expect(hasil.detail!.fcm4, closeTo(9.84, 0.0001));
      expect(hasil.detail!.bkPersenBb, closeTo(2.74336, 0.0001));
      expect(hasil.kebutuhanBkKg, closeTo(10.424768, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(5.686544, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(1.052704, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(41.11856, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(26.1408, 0.0001));
    });

    test('tetap menghitung saat lemak susu di luar rentang rekomendasi', () {
      final hasil = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: FisiologiSapi.laktasi,
        beratBadan: 450,
        produksiSusuLiter: 12,
        lemakSusuPersen: 4.2,
      )!;

      expect(hasil.kebutuhanBkKg, greaterThan(0));
      expect(
        hasil.catatan.any((item) => item.contains('luar rentang rekomendasi')),
        isTrue,
      );
    });
  });

  group('Perhitungan kebutuhan nutrien Kering Kandang', () {
    test('menghasilkan nilai tabel saat BB sama persis', () {
      final hasil = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: FisiologiSapi.keringKandang,
        beratBadan: 500,
      )!;

      expect(hasil.kebutuhanBkKg, closeTo(10.0, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(4.90, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(0.978, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(33.0, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(20.0, 0.0001));
    });

    test('menggunakan interpolasi saat BB di antara tabel', () {
      final hasil = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: FisiologiSapi.keringKandang,
        beratBadan: 425,
      )!;

      expect(hasil.kebutuhanBkKg, closeTo(8.5, 0.0001));
      expect(hasil.kebutuhanTdnKg, closeTo(4.34, 0.0001));
      expect(hasil.kebutuhanProteinKg, closeTo(0.9015, 0.0001));
      expect(hasil.kebutuhanCaGram, closeTo(28.0, 0.0001));
      expect(hasil.kebutuhanPGram, closeTo(17.0, 0.0001));
    });
  });
}
