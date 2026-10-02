import 'package:calcone/core/utils/number_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rational/rational.dart';

void main() {
  group('NumberFormatter', () {
    test('adds thousands separators', () {
      expect(NumberFormatter.format(Rational.parse('1250000')), '1,250,000');
    });

    test('trims trailing zeros', () {
      expect(NumberFormatter.format(Rational.parse('25.0000')), '25');
    });

    test('keeps significant decimals', () {
      expect(NumberFormatter.format(Rational.parse('25.4000')), '25.4');
    });

    test('formats negative numbers with the sign preserved', () {
      expect(NumberFormatter.format(Rational.parse('-1250.5')), '-1,250.5');
    });

    test('formats zero as "0", not "0.0"', () {
      expect(NumberFormatter.format(Rational.parse('0')), '0');
    });

    test('caps non-terminating decimals at maxDecimalPlaces without crashing', () {
      final Rational oneThird = Rational.parse('1') / Rational.parse('3');
      final String formatted = NumberFormatter.format(oneThird, maxDecimalPlaces: 4);
      expect(formatted, '0.3333');
    });
  });
}
