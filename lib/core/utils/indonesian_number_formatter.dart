class IndonesianNumberFormatter {
  static bool isSupportedMagnitude(num value) =>
      value.isFinite && value.abs() < 1e21;

  static num parse(String value) {
    final input = value.trim();
    if (input.isEmpty) {
      throw const FormatException('Number must not be empty');
    }

    final scientificMatch = RegExp(r'^-?\d+[eE][+-]?\d+$').hasMatch(input);
    if (scientificMatch) {
      final result = num.tryParse(input);
      if (result == null || !isSupportedMagnitude(result)) {
        throw FormatException('Invalid Indonesian number: $value');
      }
      return result;
    }

    final match = RegExp(
      r'^(-?)(\d+|\d{1,3}(?:\.\d{3})+)(?:,(\d+))?$',
    ).firstMatch(input);
    if (match == null) {
      throw FormatException('Invalid Indonesian number: $value');
    }

    final sign = match.group(1) == '-' ? '-' : '';
    final integerPart = match.group(2)!.replaceAll('.', '');
    final decimalPart = match.group(3);
    final normalized =
        '$sign$integerPart${decimalPart == null ? '' : '.$decimalPart'}';
    final result = num.tryParse(normalized);
    if (result == null || !isSupportedMagnitude(result)) {
      throw FormatException('Invalid Indonesian number: $value');
    }
    return result;
  }

  static num? tryParse(String value) {
    try {
      return parse(value);
    } on FormatException {
      return null;
    }
  }

  static String format(
    num value, {
    required int decimals,
    bool groupThousands = true,
  }) {
    if (decimals < 0 || decimals > 20) {
      throw ArgumentError.value(
        decimals,
        'decimals',
        'Must be between 0 and 20',
      );
    }
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite');
    }
    if (!isSupportedMagnitude(value)) {
      throw ArgumentError.value(value, 'value', 'Must be less than 1e21');
    }

    final parts = value.toStringAsFixed(decimals).split('.');
    final sign = parts[0].startsWith('-') ? '-' : '';
    final integerPart = parts[0].replaceFirst(RegExp(r'^-'), '');
    final groupedInteger = groupThousands
        ? integerPart.replaceAllMapped(
            RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
            (_) => '.',
          )
        : integerPart;
    final decimalPart = decimals == 0 ? '' : ',${parts[1]}';
    return '$sign$groupedInteger$decimalPart';
  }
}
