import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dipo_feed/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formatRupiah formats double/int correctly with decimals and symbols', () {
      expect(CurrencyFormatter.formatRupiah(3500), 'Rp 3.500,00');
      expect(CurrencyFormatter.formatRupiah(1500000), 'Rp 1.500.000,00');
      expect(CurrencyFormatter.formatRupiah(1250.5, withDecimals: true), 'Rp 1.250,50');
      expect(CurrencyFormatter.formatRupiah(1250.5, withSymbol: false, withDecimals: true), '1.250,50');
      expect(CurrencyFormatter.formatRupiah(1250.5, withSymbol: false, withDecimals: false), '1.251'); // rounded
      expect(CurrencyFormatter.formatRupiah(0), 'Rp 0,00');
    });

    test('parseRupiah parses Indonesian formatted currency strings correctly', () {
      expect(CurrencyFormatter.parseRupiah('3.500'), 3500.0);
      expect(CurrencyFormatter.parseRupiah('Rp 1.500.000,50'), 1500000.50);
      expect(CurrencyFormatter.parseRupiah('1.250,50'), 1250.50);
      expect(CurrencyFormatter.parseRupiah(''), 0.0);
      expect(CurrencyFormatter.parseRupiah('Rp '), 0.0);
    });
  });

  group('IndonesianCurrencyInputFormatter Tests', () {
    test('formats text editing value correctly as user types digits', () {
      final formatter = IndonesianCurrencyInputFormatter();

      // Typing "3"
      var oldVal = const TextEditingValue(text: '');
      var newVal = const TextEditingValue(text: '3', selection: TextSelection.collapsed(offset: 1));
      var result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '3');
      expect(result.selection.extentOffset, 1);

      // Typing "35"
      oldVal = result;
      newVal = const TextEditingValue(text: '35', selection: TextSelection.collapsed(offset: 2));
      result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '35');
      expect(result.selection.extentOffset, 2);

      // Typing "3500"
      oldVal = result;
      newVal = const TextEditingValue(text: '3500', selection: TextSelection.collapsed(offset: 4));
      result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '3.500');
      expect(result.selection.extentOffset, 5);

      // Backspace deleting from "3.500" to "3.50"
      oldVal = result;
      newVal = const TextEditingValue(text: '3.50', selection: TextSelection.collapsed(offset: 4));
      result = formatter.formatEditUpdate(oldVal, newVal);
      expect(result.text, '350');
      expect(result.selection.extentOffset, 3);
    });
  });
}
