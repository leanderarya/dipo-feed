class HasilImportBahanPakan {
  factory HasilImportBahanPakan({
    required int ditambah,
    required int diperbarui,
    required int dihapus,
    required int barisDiproses,
    List<String> errors = const [],
  }) {
    for (final entry in {
      'ditambah': ditambah,
      'diperbarui': diperbarui,
      'dihapus': dihapus,
      'barisDiproses': barisDiproses,
    }.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Must not be negative',
        );
      }
    }
    return HasilImportBahanPakan._(
      ditambah: ditambah,
      diperbarui: diperbarui,
      dihapus: dihapus,
      barisDiproses: barisDiproses,
      errors: errors,
    );
  }

  HasilImportBahanPakan._({
    required this.ditambah,
    required this.diperbarui,
    required this.dihapus,
    required this.barisDiproses,
    required List<String> errors,
  }) : errors = List.unmodifiable(errors);

  final int ditambah;
  final int diperbarui;
  final int dihapus;
  final int barisDiproses;
  final List<String> errors;

  bool get berhasil => errors.isEmpty;
}
