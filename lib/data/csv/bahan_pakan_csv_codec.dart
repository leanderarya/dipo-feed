import 'package:dipo_feed/data/models/bahan_pakan.dart';

class BahanPakanCsvRow {
  const BahanPakanCsvRow({
    required this.nama,
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
  /// Header baris yang dihasilkan saat ekspor dan diharapkan saat impor.
  /// Kolom "No" dan "Sumber" hanya ada di output ekspor (nilai default);
  /// saat impor, kolom tak dikenal dilewati.
  static const String header =
      'No,Bahan Pakan,Harga/kg,BK (%),Abu (%),Lemak (%),Serat (%),Protein (%),BETN (%),TDN (%),ME (KJoule/kg),Ca (%),P (%),Sumber';

  /// Nama label user-friendly untuk setiap indeks kolom (untuk error message).
  static const _columnLabels = [
    'Nama/Bahan Pakan', // 0
    'Harga/kg',         // 1
    'BK (%)',           // 2
    'Abu (%)',          // 3
    'Lemak (%)',        // 4
    'Serat (%)',        // 5
    'Protein/PK (%)',   // 6
    'BETN (%)',         // 7
    'TDN (%)',          // 8
    'ME (KJoule/kg)',   // 9
    'Ca (%)',           // 10
    'P (%)',            // 11
  ];

  static const _columnAliases = <int, List<String>>{
    0: ['Bahan Pakan', 'Nama', 'Bahan', 'Feed', 'Feed Name'],
    1: ['Harga/kg', 'Harga/ kg', 'Harga', 'Price', 'Price/kg'],
    2: ['BK (%)', 'BK', 'Bahan Kering (%)', 'BK %', 'DM (%)'],
    3: ['Abu (%)', 'Abu', 'Ash (%)'],
    4: ['Lemak (%)', 'Lemak', 'Fat (%)', 'Crude Fat (%)'],
    5: ['Serat (%)', 'Serat', 'Fiber (%)', 'Crude Fiber (%)', 'Serat Kasar (%)'],
    6: ['Protein (%)', 'PK (%)', 'PK', 'Protein', 'Crude Protein (%)', 'Protein Kasar (%)'],
    7: ['BETN (%)', 'BETN', 'BETN (Bahan Ekstrak Tanpa Nitrogen) (%)'],
    8: ['TDN (%)', 'TDN', 'TDN (Total Digestible Nutrien) (%)'],
    9: ['ME (KJoule/kg)', 'ME', 'ME (%)', 'Metabolism Energy (KJoule/kg)', 'ME (Kjoule/kg)'],
    10: ['Ca (%)', 'Ca', 'Calcium (%)', 'Kalsium (%)'],
    11: ['P (%)', 'P', 'Phosphor (%)', 'Phosphorus (%)', 'Fosfor (%)'],
  };

  /// Minimal kolom wajib: nama(0), harga(1), bk(2)..p(11).
  static const _requiredColumnIndices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};

  static List<BahanPakanCsvRow> parse(String csv) {
    final normalizedCsv = csv.startsWith('\uFEFF') ? csv.substring(1) : csv;
    final records = _parseRecords(normalizedCsv);
    if (records.isEmpty) {
      throw const FormatException('CSV header baris tidak ditemukan');
    }

    final headerFields = records.first;
    final columnIndex = _mapColumns(headerFields);

    final rows = <String, BahanPakanCsvRow>{};
    for (var lineIndex = 1; lineIndex < records.length; lineIndex++) {
      final fields = records[lineIndex];
      final rowNumber = lineIndex + 1;

      final nama = _fieldAt(fields, columnIndex, 0, 'nama', rowNumber);
      if (nama.isEmpty) {
        throw FormatException('Nama wajib diisi pada baris $rowNumber');
      }
      if (isFormulaLeadingName(nama)) {
        throw FormatException(
          'Nama bahan pakan tidak boleh diawali karakter formula pada baris $rowNumber',
        );
      }

      // Harga
      final harga = _parseNumeric(
        _fieldAt(fields, columnIndex, 1, 'harga', rowNumber),
        rowNumber,
        'harga',
      );
      if (harga < 0) {
        throw FormatException('Harga tidak boleh negatif pada baris $rowNumber');
      }

      final fieldNames = [
        'BK', 'abu', 'lemak', 'serat', 'PK',
        'BETN', 'TDN', 'ME', 'Ca', 'P',
      ];
      final values = <double>[];
      for (var i = 0; i < fieldNames.length; i++) {
        final raw = _fieldAt(fields, columnIndex, i + 2, fieldNames[i], rowNumber);
        final v = _parseNumeric(raw, rowNumber, fieldNames[i]);
        if (v < 0) {
          throw FormatException(
            '${fieldNames[i]} tidak boleh negatif pada baris $rowNumber',
          );
        }
        values.add(v);
      }

      final row = BahanPakanCsvRow(
        nama: nama.trim(),
        harga: harga,
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
    var no = 1;
    for (final bahan in bahanPakan) {
      _validateNumeric(bahan.hargaDefault, 'harga', bahan.nama);
      _validateNumeric(bahan.bk, 'BK', bahan.nama);
      _validateNumeric(bahan.abu, 'abu', bahan.nama);
      _validateNumeric(bahan.lemak, 'lemak', bahan.nama);
      _validateNumeric(bahan.serat, 'serat', bahan.nama);
      _validateNumeric(bahan.protein, 'PK', bahan.nama);
      _validateNumeric(bahan.betn, 'BETN', bahan.nama);
      _validateNumeric(bahan.tdn, 'TDN', bahan.nama);
      _validateNumeric(bahan.me, 'ME', bahan.nama);
      _validateNumeric(bahan.ca, 'Ca', bahan.nama);
      _validateNumeric(bahan.p, 'P', bahan.nama);

      final nama = bahan.nama.trim();
      if (isFormulaLeadingName(nama)) {
        throw ArgumentError.value(
          bahan.nama,
          'nama',
          'Nama bahan pakan tidak boleh diawali karakter formula',
        );
      }

      String fmt(double v, [int d = 2]) => v.toStringAsFixed(d);

      lines.add([
        '$no',
        _quote(nama),
        '${bahan.hargaDefault.toInt()}',
        fmt(bahan.bk),
        fmt(bahan.abu),
        fmt(bahan.lemak),
        fmt(bahan.serat),
        fmt(bahan.protein),
        fmt(bahan.betn),
        fmt(bahan.tdn),
        fmt(bahan.me),
        fmt(bahan.ca),
        fmt(bahan.p),
        '', // Sumber — kosong
      ].join(','));
      no++;
    }
    return '${lines.join('\n')}\n';
  }

  static void _validateNumeric(double value, String label, String nama) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        label,
        '$nama: $label harus finite dan non-negatif',
      );
    }
  }

  // ---------- helpers ----------

  static bool isFormulaLeadingName(String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return false;
    return '=+-@'.contains(normalized[0]);
  }

  /// Map header row ke indeks kolom internal (0..11).
  /// Kolom yang tidak dikenal (No, Sumber, dll.) diabaikan.
  static Map<int, int> _mapColumns(List<String> headerFields) {
    final indexMap = <int, int>{};
    for (var i = 0; i < headerFields.length; i++) {
      final normalized = headerFields[i]
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      for (final entry in _columnAliases.entries) {
        final internalIndex = entry.key;
        final matched = entry.value.any((alias) {
          final aliasNorm = alias
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ');
          return normalized == aliasNorm;
        });
        if (matched) {
          indexMap[internalIndex] = i;
          break;
        }
      }
    }
    // Pastikan semua kolom wajib ada (kategori tidak wajib)
    for (final i in _requiredColumnIndices) {
      if (!indexMap.containsKey(i)) {
        throw FormatException(
          'Kolom "${_columnLabels[i]}" tidak ditemukan di header CSV.',
        );
      }
    }
    return indexMap;
  }

  static String _fieldAt(
    List<String> fields,
    Map<int, int> columnIndex,
    int col,
    String label,
    int row,
  ) {
    final idx = columnIndex[col]!;
    return idx < fields.length ? fields[idx] : '';
  }

  /// Parse angka dari string CSV.
  static double _parseNumeric(String raw, int row, String label) {
    var s = raw.trim();
    if (s.isEmpty) return 0;

    // Strip "Rp" prefix
    if (s.startsWith('Rp') || s.startsWith('rp') || s.startsWith('RP')) {
      s = s.substring(2).trim();

      // Indonesian price format: dots = ribuan, commas = desimal/ribuan
      s = s.replaceAll(' ', '');
      s = s.replaceAll('.', '');
      final commaIdx = s.lastIndexOf(',');
      if (commaIdx >= 0) {
        final after = s.substring(commaIdx + 1);
        if (after.length <= 2) {
          // 1-2 digit after comma → decimal separator
          s = '${s.substring(0, commaIdx)}.$after';
        } else {
          // 3+ digit → thousands separator
          s = s.replaceAll(',', '');
        }
      }

      final value = double.tryParse(s);
      if (value == null || !value.isFinite) {
        throw FormatException('$label tidak valid pada baris $row');
      }
      return value;
    }

    s = s.replaceAll(' ', '');

    // Normalize commas: jika 1-2 digit setelah koma → desimal; jika 3+ → ribuan
    final commaIdx = s.lastIndexOf(',');
    if (commaIdx >= 0) {
      final after = s.substring(commaIdx + 1);
      if (after.length <= 2) {
        s = '${s.substring(0, commaIdx)}.$after';
      } else {
        s = s.replaceAll(',', '');
      }
    }

    final dotCount = s.split('.').length - 1;
    if (dotCount > 1) {
      final parts = s.split('.');
      s = '${parts.sublist(0, parts.length - 1).join('')}.${parts.last}';
    }

    final value = double.tryParse(s);
    if (value == null || !value.isFinite) {
      throw FormatException('$label tidak valid pada baris $row');
    }
    return value;
  }

  static String _quote(String value) {
    if (!value.contains(RegExp(r'[,\"\r\n]'))) {
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
      record.add(_trimOrEmpty(field.toString()));
      field.clear();
    }

    void addRecord() {
      if (!hasQuotedField &&
          record.isEmpty &&
          _trimOrEmpty(field.toString()).isEmpty) {
        throw const FormatException('Baris CSV kosong');
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
        if (character == ',') {
          addField();
          afterQuote = false;
          index++;
          continue;
        }
        if (character == '\r' || character == '\n') {
          addRecord();
          afterQuote = false;
          if (character == '\r' && index + 1 < csv.length && csv[index + 1] == '\n') {
            index++;
          }
          index++;
          continue;
        }
        throw FormatException(
          'Karakter tidak terduga setelah field quoted pada posisi $index',
        );
      }

      if (character == '"') {
        if (field.isNotEmpty) {
          throw FormatException('Field quoted harus diawali di posisi $index');
        }
        quoted = true;
        hasQuotedField = true;
        index++;
        continue;
      }
      if (character == ',') {
        addField();
        index++;
        continue;
      }
      if (character == '\r' || character == '\n') {
        addRecord();
        if (character == '\r' && index + 1 < csv.length && csv[index + 1] == '\n') {
          index++;
        }
        index++;
        continue;
      }
      field.write(character);
      index++;
    }

    if (quoted) {
      throw const FormatException('Field quoted tidak ditutup');
    }
    if (afterQuote || field.isNotEmpty || record.isNotEmpty) {
      addRecord();
    }
    return records;
  }

  static String _trimOrEmpty(String s) => s.trim();
}