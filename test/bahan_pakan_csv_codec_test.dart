import 'package:dipo_feed/data/csv/bahan_pakan_csv_codec.dart';
import 'package:dipo_feed/data/csv/hasil_import_bahan_pakan.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:flutter_test/flutter_test.dart';

const header = 'No,Bahan Pakan,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber';

String row({
  String nama = 'Rumput Gajah',
  String harga = '500',
  String bk = '29.24',
  String abu = '17.90',
  String lemak = '1.27',
  String serat = '31.21',
  String protein = '9.35',
  String betn = '40.27',
  String tdn = '54.58',
  String me = '8.24',
  String ca = '0.42',
  String p = '0.25',
}) {
  return [
    '', // No — kosong, parser akan skip
    nama,
    harga,
    bk,
    abu,
    lemak,
    serat,
    protein,
    betn,
    tdn,
    me,
    ca,
    p,
    '', // Sumber — kosong
  ].join(',');
}

/// Build CSV with header + rows.
String csv(Iterable<String> rows) {
  return '$header\n${rows.join('\n')}\n';
}

void main() {
  group('BahanPakanCsvCodec.parse', () {
    test('parses full header with UTF-8 text and point decimals', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(nama: 'Kedelai Á')}\n',
      );

      expect(rows, hasLength(1));
      expect(rows.single.nama, 'Kedelai Á');
      expect(rows.single.bk, closeTo(29.24, 0.001));
      expect(rows.single.harga, closeTo(500, 0.001));
      expect(rows.single.ca, closeTo(0.42, 0.001));
      expect(rows.single.p, closeTo(0.25, 0.001));
    });

    test('uses the last row for trim and case-insensitive duplicate names', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n'
        '${row(nama: '  Rumput Gajah ', bk: '29.00')}\n'
        '${row(nama: 'Daun Singkong')}\n'
        '${row(nama: 'RUMPUT GAJAH', bk: '30.00', abu: '18.00', harga: '600')}\n',
      );

      expect(rows, hasLength(2));
      expect(rows.map((item) => item.nama).toList(), [
        'Daun Singkong',
        'RUMPUT GAJAH',
      ]);
      expect(rows.last.bk, closeTo(30, 0.001));
      expect(rows.last.abu, closeTo(18, 0.001));
      expect(rows.last.harga, closeTo(600, 0.001));
    });

    test('parses harga with Rp prefix', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(harga: 'Rp4.500')}\n',
      );
      expect(rows.single.harga, closeTo(4500, 0.001));
    });

    test('parses harga with Indonesian comma-ribuan format', () {
      // Use manually quoted CSV — comma in value needs quoting
      final csv = 'No,Bahan Pakan,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber\n'
          '1,Rumput Gajah,"Rp4,000",29.24,17.90,1.27,31.21,9.35,40.27,54.58,8.24,0.42,0.25,\n';
      final rows = BahanPakanCsvCodec.parse(csv);
      expect(rows.single.harga, closeTo(4000, 0.001));
    });

    test('parses harga with comma as decimal separator', () {
      final csv = 'No,Bahan Pakan,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber\n'
          '1,Rumput Gajah,"4,5",29.24,17.90,1.27,31.21,9.35,40.27,54.58,8.24,0.42,0.25,\n';
      final rows = BahanPakanCsvCodec.parse(csv);
      expect(rows.single.harga, closeTo(4.5, 0.001));
    });

    test('parses harga with blank or missing as 0', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(harga: '')}\n',
      );
      expect(rows.single.harga, closeTo(0, 0.001));
    });

    test('parses numeric values with Rp prefix and dot ribuan', () {
      final rows = BahanPakanCsvCodec.parse(
        '$header\n${row(harga: 'Rp4.000')}\n',
      );
      expect(rows.single.harga, closeTo(4000, 0.001));
    });

    test('rejects invalid values in every numeric column', () {
      final testCases = <int, String>{
        2: 'harga', 3: 'BK', 4: 'abu', 5: 'lemak', 6: 'serat',
        7: 'PK', 8: 'BETN', 9: 'TDN', 10: 'ME', 11: 'Ca', 12: 'P',
      };
      for (final entry in testCases.entries) {
        final fields = row().split(',');
        fields[entry.key] = 'invalid';
        expect(
          () => BahanPakanCsvCodec.parse('$header\n${fields.join(',')}'),
          throwsFormatException,
          reason: entry.value,
        );
      }
    });

    test('rejects negative values in every numeric column', () {
      final testCases = <int, String>{
        2: 'harga', 3: 'BK', 4: 'abu', 5: 'lemak', 6: 'serat',
        7: 'PK', 8: 'BETN', 9: 'TDN', 10: 'ME', 11: 'Ca', 12: 'P',
      };
      for (final entry in testCases.entries) {
        final fields = row().split(',');
        fields[entry.key] = '-1';
        expect(
          () => BahanPakanCsvCodec.parse('$header\n${fields.join(',')}'),
          throwsFormatException,
          reason: entry.value,
        );
      }
    });

    test('rejects blank records before, between, and after data rows', () {
      for (final testCsv in [
        '$header\n\n${row()}',
        '$header\n  \n${row()}',
        '$header\n${row()}\n\n${row(nama: 'Daun Singkong')}',
        '$header\n${row()}\n  \n',
      ]) {
        expect(() => BahanPakanCsvCodec.parse(testCsv), throwsFormatException);
      }
    });

    test('parses quoted fields containing delimiter, quote, and newline', () {
      final rows = BahanPakanCsvCodec.parse(
        [
          header,
          '1,"Rumput, Gajah & ""King""",500,29.24,17.90,1.27,31.21,9.35,40.27,54.58,8.24,0.42,0.25,',
        ].join('\n'),
      );

      expect(rows.single.nama, 'Rumput, Gajah & "King"');
      expect(rows.single.harga, closeTo(500, 0.001));
    });

    test('rejects wrong or missing required columns', () {
      expect(
        () => BahanPakanCsvCodec.parse('Bahan Pakan,Harga/kg\n${row()}'),
        throwsFormatException,
      );
      expect(
        () => BahanPakanCsvCodec.parse('No,Bahan Pakan\n${row()}'),
        throwsFormatException,
      );
    });

    test('rejects blank required fields and malformed rows', () {
      for (final testCsv in [
        '$header\n${row(nama: '   ')}',
        '$header\n${row()}\n,',
      ]) {
        expect(() => BahanPakanCsvCodec.parse(testCsv), throwsFormatException);
      }
    });

    test('rejects malformed quoting', () {
      expect(
        () => BahanPakanCsvCodec.parse('$header\n"Rumput Gajah,500,29.24'),
        throwsFormatException,
      );
    });

    test('ignores unknown columns (No, Sumber, extra columns)', () {
      final csv = 'Kode,Bahan Pakan,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Catatan\n'
          'X01,Rumput Gajah,500,29.24,17.90,1.27,31.21,9.35,40.27,54.58,8.24,0.42,0.25,something\n';

      final rows = BahanPakanCsvCodec.parse(csv);
      expect(rows, hasLength(1));
      expect(rows.single.nama, 'Rumput Gajah');
      expect(rows.single.bk, closeTo(29.24, 0.001));
    });
  });

  group('BahanPakanCsvCodec.serialize', () {
    test('uses exact order, precision, and standard CSV format', () {
      const bahan = BahanPakan(
        id: 1,
        nama: 'Rumput Gajah',
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
        ca: 0.42,
        p: 0.25,
      );

      final output = BahanPakanCsvCodec.serialize([bahan]);
      expect(output, startsWith(header));
      final dataLine = output.split('\n')[1];
      expect(dataLine, contains('Rumput Gajah'));
      expect(dataLine, contains('4500'));
      expect(dataLine, contains('29.24'));
      expect(dataLine, contains('0.42'));
      expect(dataLine, contains('0.25'));
    });

    test('quotes fields containing delimiter, quote, or newline', () {
      const bahan = BahanPakan(
        id: 1,
        nama: 'Pakan, "Spesial"\nBaru',
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

      final output = BahanPakanCsvCodec.serialize([bahan]);
      expect(output, contains('"Pakan, ""Spesial""\nBaru"'));
      final rows = BahanPakanCsvCodec.parse(output);
      expect(rows.single.nama, bahan.nama);
    });

    test('rejects non-finite numeric values', () {
      final bahan = BahanPakan(
        id: 1,
        nama: 'Test',
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
        bahan.copyWith(hargaDefault: -1),
        bahan.copyWith(bk: -1),
        bahan.copyWith(abu: -1),
        bahan.copyWith(lemak: -1),
        bahan.copyWith(serat: -1),
        bahan.copyWith(protein: -1),
        bahan.copyWith(betn: -1),
        bahan.copyWith(tdn: -1),
        bahan.copyWith(me: -1),
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

      final csvOutput = BahanPakanCsvCodec.serialize(
        [first, inactive, last].where((bahan) => bahan.isActive),
      );

      final dataLines = csvOutput
          .split('\n')
          .sublist(1)
          .where((line) => line.trim().isNotEmpty)
          .toList();
      expect(dataLines.length, 2);
      expect(dataLines[0], contains('Pertama'));
      expect(dataLines[1], contains('Terakhir'));
    });
  });

  test('validates import result counts and keeps errors immutable', () {
    for (final field in [
      'ditambah', 'diperbarui', 'dihapus', 'barisDiproses',
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

  test('round-trip: parse(serialize(data)) preserves values', () {
    final bahan = BahanPakan(
      id: 1,
      nama: 'Rumput Gajah',
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
      ca: 0.42,
      p: 0.25,
    );

    final csvOutput = BahanPakanCsvCodec.serialize([bahan]);
    final rows = BahanPakanCsvCodec.parse(csvOutput);

    expect(rows, hasLength(1));
    expect(rows.single.nama, 'Rumput Gajah');
    expect(rows.single.bk, closeTo(29.24, 0.01));
    expect(rows.single.harga, closeTo(4500, 0.01));
    expect(rows.single.ca, closeTo(0.42, 0.01));
    expect(rows.single.p, closeTo(0.25, 0.01));
  });

  test('ignores extra columns during import', () {
    final csvWithExtraCols = 'No,Kode,Bahan Pakan,Kategori,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber,Extra\n'
        '1,X01,Rumput Gajah,hijauan,500,29.24,17.90,1.27,31.21,9.35,40.27,54.58,8.24,0.42,0.25,Sumber data,ignore\n';

    final rows = BahanPakanCsvCodec.parse(csvWithExtraCols);
    expect(rows, hasLength(1));
    expect(rows.single.nama, 'Rumput Gajah');
    expect(rows.single.bk, closeTo(29.24, 0.01));
  });
}