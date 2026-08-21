import 'package:dipo_feed/core/utils/indonesian_number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IndonesianNumberFormatter.parse', () {
    test('parses Indonesian decimal and grouped numbers', () {
      expect(IndonesianNumberFormatter.parse('2,57'), 2.57);
      expect(IndonesianNumberFormatter.parse('1.234,50'), 1234.5);
      expect(IndonesianNumberFormatter.parse('4500'), 4500);
    });

    test('parses a leading minus sign', () {
      expect(IndonesianNumberFormatter.parse('-1.234,50'), -1234.5);
    });

    test('parses finite scientific notation within formatter range', () {
      expect(IndonesianNumberFormatter.parse('1e20'), 1e20);
      expect(IndonesianNumberFormatter.parse('-1e20'), -1e20);
    });

    test('rejects scientific notation outside formatter range', () {
      for (final value in ['1e21', '-1e21', '1e308', '1e+21']) {
        expect(
          () => IndonesianNumberFormatter.parse(value),
          throwsFormatException,
          reason: value,
        );
        expect(IndonesianNumberFormatter.tryParse(value), isNull);
      }
    });

    test('trims surrounding whitespace', () {
      expect(IndonesianNumberFormatter.parse(' 1.234,50 '), 1234.5);
    });

    test('throws for empty and malformed input', () {
      for (final value in [
        '',
        '   ',
        '1.23',
        '1.2345',
        '1.23.456',
        '1,',
        ',50',
        '--1',
        '1 234',
      ]) {
        expect(
          () => IndonesianNumberFormatter.parse(value),
          throwsFormatException,
        );
      }
    });
  });

  group('IndonesianNumberFormatter.tryParse', () {
    test('returns null for invalid input', () {
      expect(IndonesianNumberFormatter.tryParse(''), isNull);
      expect(IndonesianNumberFormatter.tryParse('1.23'), isNull);
    });

    test('returns parsed value for valid input', () {
      expect(IndonesianNumberFormatter.tryParse('1.234,50'), 1234.5);
    });
  });

  group('IndonesianNumberFormatter.format', () {
    test('formats values with Indonesian separators and precision', () {
      expect(IndonesianNumberFormatter.format(2.57, decimals: 2), '2,57');
      expect(IndonesianNumberFormatter.format(1234.5, decimals: 2), '1.234,50');
      expect(IndonesianNumberFormatter.format(4500, decimals: 0), '4.500');
    });

    test('supports ungrouped and negative values', () {
      expect(
        IndonesianNumberFormatter.format(
          1234.5,
          decimals: 2,
          groupThousands: false,
        ),
        '1234,50',
      );
      expect(
        IndonesianNumberFormatter.format(-1234.5, decimals: 2),
        '-1.234,50',
      );
    });

    test('rejects invalid precision and non-finite values', () {
      expect(
        () => IndonesianNumberFormatter.format(1, decimals: -1),
        throwsArgumentError,
      );
      expect(
        () => IndonesianNumberFormatter.format(double.nan, decimals: 2),
        throwsArgumentError,
      );
      expect(
        () => IndonesianNumberFormatter.format(double.infinity, decimals: 2),
        throwsArgumentError,
      );
      expect(
        () => IndonesianNumberFormatter.format(1e21, decimals: 2),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('less than 1e21'),
          ),
        ),
      );
    });

    test('exposes formatter magnitude contract', () {
      expect(IndonesianNumberFormatter.isSupportedMagnitude(1e20), isTrue);
      expect(IndonesianNumberFormatter.isSupportedMagnitude(1e21), isFalse);
      expect(
        IndonesianNumberFormatter.isSupportedMagnitude(double.infinity),
        isFalse,
      );
    });
  });
}
