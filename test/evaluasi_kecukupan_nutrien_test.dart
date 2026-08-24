import 'package:flutter_test/flutter_test.dart';
import 'package:dipo_feed/data/models/fisiologi_sapi.dart';
import 'package:dipo_feed/data/models/kebutuhan_nutrien_sapi.dart';
import 'package:dipo_feed/features/cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'package:dipo_feed/features/cek_kecukupan_pakan/logic/evaluasi_kecukupan_nutrien.dart';

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
  });
}
