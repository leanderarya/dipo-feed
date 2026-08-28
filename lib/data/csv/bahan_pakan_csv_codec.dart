import 'package:dipo_feed/core/utils/indonesian_number_formatter.dart';
import 'package:dipo_feed/data/models/bahan_pakan.dart';

class BahanPakanCsvRow {
  const BahanPakanCsvRow({
    required this.nama,
    required this.kategori,
    required this.bk,
    required this.abu,
    required this.lemak,
    required this.serat,
    required this.protein,
    required this.betn,
    required this.tdn,
    required this.me,
    required this.harga,
    required this.ca,
    required this.p,
  });

  final String nama;
  final String kategori;
  final double bk;
  final double abu;
  final double lemak;
  final double serat;
  final double protein;
  final double betn;
  final double tdn;
  final double me;
  final double harga;
  final double ca;
  final double p;

  String get namaNormalisasi => nama.trim().toLowerCase();
}

class BahanPakanCsvCodec {
  static const header =
      'nama;harga;kategori;BK;abu;lemak;serat;PK;BETN;TDN;ME;Ca;P';

  static const _fieldCount = 13;
  static const _nutrientFields = <String>[
    'BK',
    'abu',
    'lemak',
    'serat',
    'PK',
    'BETN',
    'TDN',
    'ME',
    'Ca',
    'P',
  ];
  static const _categories = {'hijauan', 'konsentrat', 'lainnya'};

  static List<BahanPakanCsvRow> parse(String csv) {
    final normalizedCsv = csv.startsWith('\uFEFF') ? csv.substring(1) : csv;
    final records = _parseRecords(normalizedCsv);
    if (records.isEmpty || records.first.length != _fieldCount) {
      throw const FormatException('CSV header must match exactly');
    }
    if (records.first.join(';') != header) {
      throw const FormatException('CSV header must match exactly');
    }

    final rows = <String, BahanPakanCsvRow>{};
    for (var index = 1; index < records.length; index++) {
      final fields = records[index];
      if (fields.length != _fieldCount) {
        throw FormatException('Invalid CSV row at line ${index + 1}');
      }
      final nama = fields[0].trim();
      final hargaStr = fields[1].trim();
      final kategori = fields[2].trim().toLowerCase();
      if (nama.isEmpty || kategori.isEmpty) {
        throw FormatException(
          'Name and category are required at line ${index + 1}',
        );
      }
      if (isFormulaLeadingName(nama)) {
        throw FormatException(
          'Feed name cannot start with a formula character at line ${index + 1}',
        );
      }
      if (!_categories.contains(kategori)) {
        throw FormatException('Invalid category at line ${index + 1}');
      }

      final harga = IndonesianNumberFormatter.tryParse(hargaStr);
      if (harga == null ||
          !IndonesianNumberFormatter.isSupportedMagnitude(harga) ||
          harga < 0) {
        throw FormatException('Invalid harga at line ${index + 1}');
      }

      final values = <double>[];
      for (var fieldIndex = 3; fieldIndex < _fieldCount; fieldIndex++) {
        final value = IndonesianNumberFormatter.tryParse(fields[fieldIndex]);
        if (value == null ||
            !IndonesianNumberFormatter.isSupportedMagnitude(value) ||
            value < 0) {
          throw FormatException(
            'Invalid ${_nutrientFields[fieldIndex - 3]} at line ${index + 1}',
          );
        }
        values.add(value.toDouble());
      }

      final row = BahanPakanCsvRow(
        nama: nama,
        kategori: kategori,
        harga: harga.toDouble(),
        bk: values[0],
        abu: values[1],
        lemak: values[2],
        serat: values[3],
        protein: values[4],
        betn: values[5],
        tdn: values[6],
        me: values[7],
        ca: values[8],
        p: values[9],
      );
      rows.remove(row.namaNormalisasi);
      rows[row.namaNormalisasi] = row;
    }
    return List.unmodifiable(rows.values);
  }

  static String serialize(Iterable<BahanPakan> bahanPakan) {
    final lines = <String>[header];
    for (final bahan in bahanPakan) {
      final numericValues = <String, double>{
        'harga': bahan.hargaDefault,
        'BK': bahan.bk,
        'abu': bahan.abu,
        'lemak': bahan.lemak,
        'serat': bahan.serat,
        'PK': bahan.protein,
        'BETN': bahan.betn,
        'TDN': bahan.tdn,
        'ME': bahan.me,
        'Ca': bahan.ca,
        'P': bahan.p,
      };
      for (final entry in numericValues.entries) {
        if (!IndonesianNumberFormatter.isSupportedMagnitude(entry.value) ||
            entry.value < 0) {
          throw ArgumentError.value(
            entry.value,
            entry.key,
            'Must be finite and non-negative',
          );
        }
      }

      final nama = bahan.nama.trim();
      if (isFormulaLeadingName(nama)) {
        throw ArgumentError.value(
          bahan.nama,
          'nama',
          'Feed name cannot start with a formula character',
        );
      }
      final kategori = _kategoriUntukEkspor(bahan.kategori);
      lines.add(
        [
          _quote(nama),
          bahan.hargaDefault.toInt().toString(), // plain integer, no thousands dot
          _quote(kategori),
          IndonesianNumberFormatter.format(bahan.bk, decimals: 2),
          IndonesianNumberFormatter.format(bahan.abu, decimals: 2),
          IndonesianNumberFormatter.format(bahan.lemak, decimals: 2),
          IndonesianNumberFormatter.format(bahan.serat, decimals: 2),
          IndonesianNumberFormatter.format(bahan.protein, decimals: 2),
          IndonesianNumberFormatter.format(bahan.betn, decimals: 2),
          IndonesianNumberFormatter.format(bahan.tdn, decimals: 2),
          IndonesianNumberFormatter.format(bahan.me, decimals: 2),
          IndonesianNumberFormatter.format(bahan.ca, decimals: 2),
          IndonesianNumberFormatter.format(bahan.p, decimals: 2),
        ].join(';'),
      );
    }
    return '${lines.join('\n')}\n';
  }

  static bool isFormulaLeadingName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return false;
    return '=+-@'.contains(normalized[0]);
  }

  static String _kategoriUntukEkspor(String kategori) {
    final normalized = kategori.trim().toLowerCase();
    if (normalized == 'energi' || normalized == 'limbah') return 'lainnya';
    if (!_categories.contains(normalized)) {
      throw ArgumentError.value(kategori, 'kategori', 'Unknown feed category');
    }
    return normalized;
  }

  static String _quote(String value) {
    if (!value.contains(RegExp(r'[;"\r\n]'))) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  static List<List<String>> _parseRecords(String csv) {
    final records = <List<String>>[];
    final record = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var afterQuote = false;
    var hasQuotedField = false;
    var index = 0;

    void addField() {
      record.add(field.toString());
      field.clear();
    }

    void addRecord() {
      if (!hasQuotedField &&
          record.isEmpty &&
          field.toString().trim().isEmpty) {
        throw const FormatException('Blank CSV record');
      }
      addField();
      records.add(List.unmodifiable(record));
      record.clear();
      hasQuotedField = false;
    }

    while (index < csv.length) {
      final character = csv[index];
      if (quoted) {
        if (character == '"') {
          if (index + 1 < csv.length && csv[index + 1] == '"') {
            field.write('"');
            index += 2;
            continue;
          }
          quoted = false;
          afterQuote = true;
          index++;
          continue;
        }
        field.write(character);
        index++;
        continue;
      }

      if (afterQuote) {
        if (character == ';') {
          addField();
          afterQuote = false;
          index++;
          continue;
        }
        if (character == '\r' || character == '\n') {
          addRecord();
          afterQuote = false;
          if (character == '\r' &&
              index + 1 < csv.length &&
              csv[index + 1] == '\n') {
            index++;
          }
          index++;
          continue;
        }
        throw FormatException(
          'Unexpected character after quoted field at position $index',
        );
      }

      if (character == '"') {
        if (field.isNotEmpty) {
          throw FormatException('Quoted field must start at position $index');
        }
        quoted = true;
        hasQuotedField = true;
        index++;
        continue;
      }
      if (character == ';') {
        addField();
        index++;
        continue;
      }
      if (character == '\r' || character == '\n') {
        addRecord();
        if (character == '\r' &&
            index + 1 < csv.length &&
            csv[index + 1] == '\n') {
          index++;
        }
        index++;
        continue;
      }
      field.write(character);
      index++;
    }

    if (quoted) {
      throw const FormatException('Unterminated quoted field');
    }
    if (afterQuote || field.isNotEmpty || record.isNotEmpty) {
      addRecord();
    }
    return records;
  }
}
