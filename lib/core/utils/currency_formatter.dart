import 'package:flutter/services.dart';

class CurrencyFormatter {
  /// Formats any number into Indonesian Rupiah (Rp) string representation.
  /// Example: 3500 -> "Rp 3.500,00" or "3.500" depending on parameters.
  static String formatRupiah(num value, {bool withSymbol = true, bool withDecimals = true}) {
    String valueStr = value.toStringAsFixed(withDecimals ? 2 : 0);
    List<String> parts = valueStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // Add dot thousand separators
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger = integerPart.replaceAllMapped(reg, (Match match) => '${match[1]}.');

    String result = formattedInteger;
    if (withDecimals && decimalPart.isNotEmpty) {
      result += ',$decimalPart';
    }

    return withSymbol ? 'Rp $result' : result;
  }

  /// Parses an Indonesian formatted currency string back to a double.
  /// Example: "3.500" -> 3500.0, "Rp 1.500.000,50" -> 1500000.50
  static double parseRupiah(String value) {
    if (value.isEmpty) return 0;
    // Remove dots (thousand separators)
    String clean = value.replaceAll('.', '');
    // Replace comma with dot (decimal separator)
    clean = clean.replaceAll(',', '.');
    // Remove any non-numeric characters except digits and dot
    clean = clean.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(clean) ?? 0;
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
