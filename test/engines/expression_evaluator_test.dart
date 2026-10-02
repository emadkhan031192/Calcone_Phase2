import 'package:calcone/core/errors/calculator_exception.dart';
import 'package:calcone/core/utils/number_formatter.dart';
import 'package:calcone/engines/expression/expression_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rational/rational.dart';

void main() {
  const ExpressionEvaluator evaluator = ExpressionEvaluator();

  String evalToDisplay(String expr) => NumberFormatter.format(evaluator.evaluate(expr));

  group('basic arithmetic (spec §33)', () {
    test('2 + 2 = 4', () => expect(evalToDisplay('2+2'), '4'));
    test('10 - 3 = 7', () => expect(evalToDisplay('10-3'), '7'));
    test('5 * 6 = 30', () => expect(evalToDisplay('5*6'), '30'));
    test('20 / 4 = 5', () => expect(evalToDisplay('20/4'), '5'));
  });

  group('operator precedence', () {
    test('2 + 3 * 4 = 14', () => expect(evalToDisplay('2+3*4'), '14'));
    test('(2 + 3) * 4 = 20', () => expect(evalToDisplay('(2+3)*4'), '20'));
    test('10 - 2 - 3 = 5 (left-associative)', () => expect(evalToDisplay('10-2-3'), '5'));
    test('100 / 10 / 2 = 5 (left-associative)', () => expect(evalToDisplay('100/10/2'), '5'));
  });

  group('smart percentage (spec §6)', () {
    test('500 + 10% = 550', () => expect(evalToDisplay('500+10%'), '550'));
    test('500 - 10% = 450', () => expect(evalToDisplay('500-10%'), '450'));
    test('500 * 10% = 50', () => expect(evalToDisplay('500*10%'), '50'));
    test('2500 * 15% = 375', () => expect(evalToDisplay('2500*15%'), '375'));
    test('standalone 50% = 0.5', () => expect(evalToDisplay('50%'), '0.5'));
    test('1000 + 10% + 10% compounds sequentially', () {
      // 1000 + 10% -> 1100; 1100 + 10% of 1100 -> 1210
      expect(evalToDisplay('1000+10%+10%'), '1,210');
    });
  });

  group('decimal precision (spec §32)', () {
    test('0.1 + 0.2 = 0.3 exactly, not 0.30000000000000004', () {
      expect(evalToDisplay('0.1+0.2'), '0.3');
    });
    test('1/3 * 3 = 1 exactly (no floating point drift)', () {
      expect(evalToDisplay('1/3*3'), '1');
    });
    test('trailing zeros are trimmed: 25.0000 -> 25', () {
      final Rational result = evaluator.evaluate('25.0000');
      expect(NumberFormatter.format(result), '25');
    });
    test('large numbers get thousands separators', () {
      expect(evalToDisplay('1000000+250000'), '1,250,000');
    });
  });

  group('negative numbers and unary minus', () {
    test('-5 + 3 = -2', () => expect(evalToDisplay('-5+3'), '-2'));
    test('5 * -3 = -15', () => expect(evalToDisplay('5*-3'), '-15'));
    test('-(2+3) = -5', () => expect(evalToDisplay('-(2+3)'), '-5'));
  });

  group('error handling (spec §31)', () {
    test('division by zero throws a friendly exception', () {
      expect(
        () => evaluator.evaluate('5/0'),
        throwsA(isA<CalculatorException>().having(
          (CalculatorException e) => e.message,
          'message',
          'Cannot divide by zero.',
        )),
      );
    });

    test('empty input throws', () {
      expect(() => evaluator.evaluate(''), throwsA(isA<CalculatorException>()));
    });

    test('unmatched parentheses throws', () {
      expect(() => evaluator.evaluate('(2+3'), throwsA(isA<CalculatorException>()));
    });

    test('malformed expression throws', () {
      expect(() => evaluator.evaluate('2**3'), throwsA(isA<CalculatorException>()));
    });

    test('trailing operator throws', () {
      expect(() => evaluator.evaluate('5+'), throwsA(isA<CalculatorException>()));
    });
  });

  group('zero and edge cases', () {
    test('0 * 5 = 0', () => expect(evalToDisplay('0*5'), '0'));
    test('0 - 0 = 0', () => expect(evalToDisplay('0-0'), '0'));
    test('very small decimal', () => expect(evalToDisplay('0.0001+0.0001'), '0.0002'));
  });
}
