import 'package:flutter/services.dart';
import 'package:dipo_feed/core/utils/indonesian_number_formatter.dart';

class CurrencyFormatter {
  /// Formats any number into Indonesian Rupiah (Rp) string representation.
  /// Example: 3500 -> "Rp 3.500,00" or "3.500" depending on parameters.
  static String formatRupiah(
    num value, {
    bool withSymbol = true,
    bool withDecimals = true,
  }) {
    final result = IndonesianNumberFormatter.format(
      value,
      decimals: withDecimals ? 2 : 0,
    );
    return withSymbol ? 'Rp $result' : result;
  }

  /// Parses an Indonesian formatted currency string back to a double.
  /// Example: "3.500" -> 3500.0, "Rp 1.500.000,50" -> 1500000.50
  static double parseRupiah(String value) {
    final clean = value.replaceFirst(
      RegExp(r'^\s*Rp\s*', caseSensitive: false),
      '',
    );
    return IndonesianNumberFormatter.tryParse(clean)?.toDouble() ?? 0;
  }
}

/// A text input formatter that automatically formats input digits to Indonesian currency format as the user types.
/// Example: "3500" -> "3.500"
class IndonesianCurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Strip all non-numeric characters (only allow numbers)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse to integer
    int? value = int.tryParse(cleanText);
    if (value == null) {
      return oldValue;
    }

    // Format with thousand separators (dots)
    String formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
