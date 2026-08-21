import 'package:dipo_feed/data/csv/bahan_pakan_csv_codec.dart';
import 'package:dipo_feed/data/csv/hasil_import_bahan_pakan.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:flutter_test/flutter_test.dart';

const header = 'nama;kategori;BK;abu;lemak;serat;PK;BETN;TDN;ME;harga;Ca;P';

String row({
  String nama = 'Rumput Gajah',
  String kategori = 'hijauan',
  String bk = '29,24',
  String abu = '17,90',
  String lemak = '1,27',
  String serat = '31,21',
  String protein = '9,35',
  String betn = '40,27',
  String tdn = '54,58',
  String me = '8,24',
  String harga = '500',
  String ca = '0,00',
  String p = '0,00',
}) {
  return [
    nama,
    kategori,
    bk,
    abu,
    lemak,
    serat,
    protein,
    betn,
    tdn,
    me,
    harga,
    ca,
    p,
  ].join(';');
}

void main() {
  group('BahanPakanCsvCodec.parse', () {
    test('parses exact header, Indonesian numbers, and UTF-8 text', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(nama: 'Kedelai Á')}\n',
      );

      expect(rows, hasLength(1));
      expect(rows.single.nama, 'Kedelai Á');
      expect(rows.single.kategori, 'hijauan');
      expect(rows.single.bk, 29.24);
      expect(rows.single.harga, 500);
      expect(rows.single.ca, 0);
      expect(rows.single.p, 0);
    });

    test('normalizes accepted categories and rejects unknown categories', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(kategori: ' HIJAUAN ')}',
      );

      expect(rows.single.kategori, 'hijauan');
      expect(
        () => BahanPakanCsvCodec.parse('$header\n${row(kategori: 'suplemen')}'),
        throwsFormatException,
      );
    });

    test('uses the last row for trim and case-insensitive duplicate names', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(nama: '  Rumput Gajah ', bk: '29,00')}\n${row(nama: 'Daun Singkong')}\n${row(nama: 'RUMPUT GAJAH', bk: '30,00', abu: '18,00', harga: '600')}',
      );

      expect(rows, hasLength(2));
      expect(rows.map((item) => item.nama).toList(), [
        'Daun Singkong',
        'RUMPUT GAJAH',
      ]);
      expect(rows.last.bk, 30);
      expect(rows.last.abu, 18);
      expect(rows.last.harga, 600);
    });

    test('rejects invalid values in every numeric column', () {
      final numericColumns = header.split(';').sublist(2);
      for (var index = 0; index < numericColumns.length; index++) {
        final fields = row().split(';');
        fields[index + 2] = 'invalid';

        expect(
          () => BahanPakanCsvCodec.parse('$header\n${fields.join(';')}'),
          throwsFormatException,
          reason: numericColumns[index],
        );
      }
    });

    test('rejects negative values in every numeric column', () {
      final numericColumns = header.split(';').sublist(2);
      for (var index = 0; index < numericColumns.length; index++) {
        final fields = row().split(';');
        fields[index + 2] = '-1';

        expect(
          () => BahanPakanCsvCodec.parse('$header\n${fields.join(';')}'),
          throwsFormatException,
          reason: numericColumns[index],
        );
      }
    });

    test('rejects numeric values formatter cannot export', () {
      final fields = row().split(';');
      fields[2] = '1e21';

      expect(
        () => BahanPakanCsvCodec.parse('$header\n${fields.join(';')}'),
        throwsFormatException,
      );
    });

    test('rejects blank records before, between, and after data rows', () {
      for (final csv in [
        '$header\n\n${row()}',
        '$header\n  \n${row()}',
        '$header\n${row()}\n\n${row(nama: 'Daun Singkong')}',
        '$header\n${row()}\n  \n',
      ]) {
        expect(() => BahanPakanCsvCodec.parse(csv), throwsFormatException);
      }
    });

    test('parses quoted fields containing delimiter, quote, and newline', () {
      final rows = BahanPakanCsvCodec.parse(
        [
          header,
          '"Pakan; ""Spesial""\nBaru";hijauan;29,24;17,90;1,27;31,21;9,35;40,27;54,58;8,24;500;0,00;0,00',
        ].join('\n'),
      );

      expect(rows.single.nama, 'Pakan; "Spesial"\nBaru');
    });

    test('rejects wrong header', () {
      expect(
        () => BahanPakanCsvCodec.parse('nama;kategori\n${row()}'),
        throwsFormatException,
      );
    });

    test('rejects blank required fields and malformed rows', () {
      for (final csv in [
        '$header\n${row(nama: '   ')}',
        '$header\n${row(kategori: '')}',
        '$header\n${row(bk: '')}',
        '$header\n${row(bk: '1.23')}',
        '$header\n${row()}\nshort;row',
      ]) {
        expect(() => BahanPakanCsvCodec.parse(csv), throwsFormatException);
      }
    });

    test('rejects malformed quoting', () {
      expect(
        () => BahanPakanCsvCodec.parse('$header\n"Rumput Gajah;hijauan;29,24'),
        throwsFormatException,
      );
      expect(
        () =>
            BahanPakanCsvCodec.parse('$header\n${row(nama: 'Rumput "Gajah')} '),
        throwsFormatException,
      );
    });
  });

  group('BahanPakanCsvCodec.serialize', () {
    test('uses exact order, precision, and Indonesian separators', () {
      const bahan = BahanPakan(
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
        hargaDefault: 4500,
        isActive: true,
        ca: 0,
        p: 0,
      );

      expect(
        BahanPakanCsvCodec.serialize([bahan]),
        '$header\nRumput Gajah;hijauan;29,24;17,90;1,27;31,21;9,35;40,27;54,58;8,24;4.500;0,00;0,00\n',
      );
    });

    test('quotes fields containing delimiter, quote, or newline', () {
      const bahan = BahanPakan(
        id: 1,
        nama: 'Pakan; "Spesial"\nBaru',
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
        isActive: true,
      );

      expect(
        BahanPakanCsvCodec.serialize([bahan]),
        '$header\n"Pakan; ""Spesial""\nBaru";lainnya;1,00;2,00;3,00;4,00;5,00;6,00;7,00;8,00;9;0,00;0,00\n',
      );
    });

    test('canonicalizes legacy categories for re-importable round trips', () {
      final bahan = const BahanPakan(
        id: 1,
        nama: 'Energi Lama',
        kategori: 'energi',
        bk: 1,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9,
        isActive: true,
      );
      final csv = BahanPakanCsvCodec.serialize([bahan]);
      final rows = BahanPakanCsvCodec.parse(csv);

      expect(rows.single.kategori, 'lainnya');
      expect(csv, contains('Energi Lama;lainnya;'));
    });

    test('rejects unknown categories during serialization', () {
      final bahan = const BahanPakan(
        id: 1,
        nama: 'Unknown',
        kategori: 'suplemen',
        bk: 1,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9,
        isActive: true,
      );

      expect(() => BahanPakanCsvCodec.serialize([bahan]), throwsArgumentError);
    });

    test('canonicalizes names and categories before quoting', () {
      final bahan = BahanPakan(
        id: 1,
        nama: '  Rumput Gajah  ',
        kategori: ' HIJAUAN ',
        bk: 1,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9,
        isActive: true,
      );

      final rows = BahanPakanCsvCodec.parse(
        BahanPakanCsvCodec.serialize([bahan]),
      );

      expect(rows.single.nama, 'Rumput Gajah');
      expect(rows.single.kategori, 'hijauan');
    });

    test('uses formatter rounding and rejects non-finite numeric values', () {
      final bahan = BahanPakan(
        id: 1,
        nama: 'Rounding',
        kategori: 'hijauan',
        bk: 1.235,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9.5,
        isActive: true,
      );

      expect(
        BahanPakanCsvCodec.serialize([bahan]).split('\n')[1].split(';'),
        containsAllInOrder(['1,24', '2,00']),
      );
      expect(
        () => BahanPakanCsvCodec.serialize([bahan.copyWith(bk: double.nan)]),
        throwsArgumentError,
      );
      expect(
        () => BahanPakanCsvCodec.serialize([
          bahan.copyWith(hargaDefault: double.infinity),
        ]),
        throwsArgumentError,
      );
    });

    test('rejects negative values in every numeric field', () {
      final bahan = const BahanPakan(
        id: 1,
        nama: 'Negative',
        kategori: 'hijauan',
        bk: 1,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9,
        isActive: true,
      );
      final negativeValues = [
        bahan.copyWith(bk: -1),
        bahan.copyWith(abu: -1),
        bahan.copyWith(lemak: -1),
        bahan.copyWith(serat: -1),
        bahan.copyWith(protein: -1),
        bahan.copyWith(betn: -1),
        bahan.copyWith(tdn: -1),
        bahan.copyWith(me: -1),
        bahan.copyWith(hargaDefault: -1),
        bahan.copyWith(ca: -1),
        bahan.copyWith(p: -1),
      ];

      for (final value in negativeValues) {
        expect(
          () => BahanPakanCsvCodec.serialize([value]),
          throwsArgumentError,
        );
      }
    });

    test('preserves caller-provided active filtering and record order', () {
      final first = BahanPakan(
        id: 1,
        nama: 'Pertama',
        kategori: 'hijauan',
        bk: 1,
        abu: 2,
        lemak: 3,
        serat: 4,
        protein: 5,
        betn: 6,
        tdn: 7,
        me: 8,
        hargaDefault: 9,
        isActive: true,
      );
      final inactive = first.copyWith(
        id: 2,
        nama: 'Tidak Aktif',
        isActive: false,
      );
      final last = first.copyWith(id: 3, nama: 'Terakhir');

      final csv = BahanPakanCsvCodec.serialize(
        [first, inactive, last].where((bahan) => bahan.isActive),
      );

      expect(
        csv.split('\n').sublist(1, 3).map((line) => line.split(';').first),
        ['Pertama', 'Terakhir'],
      );
    });
  });

  test('validates import result counts and keeps errors immutable', () {
    for (final field in [
      'ditambah',
      'diperbarui',
      'dihapus',
      'barisDiproses',
    ]) {
      expect(
        () => HasilImportBahanPakan(
          ditambah: field == 'ditambah' ? -1 : 0,
          diperbarui: field == 'diperbarui' ? -1 : 0,
          dihapus: field == 'dihapus' ? -1 : 0,
          barisDiproses: field == 'barisDiproses' ? -1 : 0,
        ),
        throwsArgumentError,
        reason: field,
      );
    }

    final result = HasilImportBahanPakan(
      ditambah: 1,
      diperbarui: 2,
      dihapus: 3,
      barisDiproses: 4,
      errors: const ['invalid row'],
    );

    expect(result.berhasil, isFalse);
    expect(() => result.errors.add('another error'), throwsUnsupportedError);
    expect(
      HasilImportBahanPakan(
        ditambah: 0,
        diperbarui: 0,
        dihapus: 0,
        barisDiproses: 0,
      ).berhasil,
      isTrue,
    );
  });
}
