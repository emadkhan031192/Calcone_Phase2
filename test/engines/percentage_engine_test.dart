import 'package:calcone/core/utils/number_formatter.dart';
import 'package:calcone/engines/percentage/percentage_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rational/rational.dart';

void main() {
  Rational r(String s) => Rational.parse(s);
  String fmt(Rational v) => NumberFormatter.format(v);

  group('PercentageEngine', () {
    test('percentOf: 15% of 2500 = 375', () {
      expect(fmt(PercentageEngine.percentOf(r('2500'), r('15'))), '375');
    });

    test('increaseBy: 500 increased by 10% = 550', () {
      expect(fmt(PercentageEngine.increaseBy(r('500'), r('10'))), '550');
    });

    test('decreaseBy: 500 decreased by 10% = 450 (discount)', () {
      expect(fmt(PercentageEngine.decreaseBy(r('500'), r('10'))), '450');
    });

    test('whatPercent: 50 is 10% of 500', () {
      expect(fmt(PercentageEngine.whatPercent(r('50'), r('500'))), '10');
    });

    test('percentChange: from 100 to 150 is a 50% increase', () {
      expect(fmt(PercentageEngine.percentChange(r('100'), r('150'))), '50');
    });

    test('percentChange: from 100 to 80 is a -20% change', () {
      expect(fmt(PercentageEngine.percentChange(r('100'), r('80'))), '-20');
    });

    test('markupPrice: cost 100 with 25% markup sells for 125', () {
      expect(fmt(PercentageEngine.markupPrice(r('100'), r('25'))), '125');
    });
  });
}
