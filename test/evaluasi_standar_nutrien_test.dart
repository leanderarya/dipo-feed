import 'package:flutter_test/flutter_test.dart';

import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/evaluasi_standar_nutrien.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';

void main() {
  group('Evaluasi standar nutrien pakan', () {
    test('menggunakan standar laktasi tengah untuk fisiologi laktasi', () {
      const hasil = HasilPerhitunganNutrisi(
        totalBerat: 10,
        totalBiaya: 10000,
        hargaRataRata: 1000,
        bk: 60,
        abu: 8,
        lemak: 4,
        serat: 18,
        protein: 16,
        tdn: 69,
        ca: 0.8,
        p: 0.5,
        me: 0,
      );

      final evaluasi = EvaluasiStandarNutrienHelper.evaluasi(
        hasil: hasil,
        fisiologi: FisiologiSapi.laktasi,
      );

      expect(evaluasi.standar.nama, 'Laktasi Tengah');
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'Protein').status,
        StatusStandarNutrien.sesuai,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'TDN').status,
        StatusStandarNutrien.sesuai,
      );
    });

    test('menandai kurang dan berlebih sesuai rentang standar', () {
      const hasil = HasilPerhitunganNutrisi(
        totalBerat: 12,
        totalBiaya: 12000,
        hargaRataRata: 1000,
        bk: 87,
        abu: 7,
        lemak: 8,
        serat: 16,
        protein: 13.4,
        tdn: 66,
        ca: 0.5,
        p: 0.9,
        me: 0,
      );

      final evaluasi = EvaluasiStandarNutrienHelper.evaluasi(
        hasil: hasil,
        fisiologi: FisiologiSapi.laktasi,
      );

      expect(
        evaluasi.items.firstWhere((item) => item.label == 'BK').status,
        StatusStandarNutrien.berlebih,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'Protein').status,
        StatusStandarNutrien.kurang,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'Lemak').status,
        StatusStandarNutrien.berlebih,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'TDN').status,
        StatusStandarNutrien.kurang,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'Ca').status,
        StatusStandarNutrien.kurang,
      );
      expect(
        evaluasi.items.firstWhere((item) => item.label == 'P').status,
        StatusStandarNutrien.berlebih,
      );
      expect(evaluasi.narasi, isNotEmpty);
      expect(evaluasi.kesimpulan, contains('masih perlu perbaikan'));
    });
  });
}
