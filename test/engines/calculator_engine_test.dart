import 'package:calcone/core/errors/calculator_exception.dart';
import 'package:calcone/engines/calculator/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CalculatorEngine engine;

  setUp(() {
    engine = CalculatorEngine();
  });

  group('digit and operator input', () {
    test('typing builds up the expression', () {
      engine.inputDigit('5');
      engine.inputOperator('+');
      engine.inputDigit('3');
      expect(engine.displayExpression, '5+3');
    });

    test('pressing an operator twice replaces the first', () {
      engine.inputDigit('5');
      engine.inputOperator('+');
      engine.inputOperator('-');
      expect(engine.displayExpression, '5−');
    });

    test('decimal point cannot be entered twice in one number', () {
      engine.inputDigit('5');
      engine.inputDecimalPoint();
      engine.inputDigit('2');
      engine.inputDecimalPoint();
      expect(engine.rawExpression, '5.2');
    });

    test('leading decimal point becomes "0."', () {
      engine.inputDecimalPoint();
      expect(engine.rawExpression, '0.');
    });
  });

  group('backspace and clear', () {
    test('backspace removes one character', () {
      engine.inputDigit('1');
      engine.inputDigit('2');
      engine.inputDigit('3');
      engine.backspace();
      expect(engine.rawExpression, '12');
    });

    test('clearCurrent empties the expression but keeps the tape', () {
      engine.inputDigit('2');
      engine.inputOperator('+');
      engine.inputDigit('2');
      engine.evaluate();
      expect(engine.tape, hasLength(1));

      engine.inputDigit('9');
      engine.clearCurrent();
      expect(engine.rawExpression, '');
      expect(engine.tape, hasLength(1));
    });

    test('clearAll wipes both the expression and the tape', () {
      engine.inputDigit('2');
      engine.inputOperator('+');
      engine.inputDigit('2');
      engine.evaluate();
      engine.clearAll();
      expect(engine.rawExpression, '');
      expect(engine.tape, isEmpty);
    });
  });

  group('evaluation and the calculation tape (spec §7)', () {
    test('evaluate() commits an entry to the tape', () {
      engine.inputDigit('1');
      engine.inputDigit('8');
      engine.inputDigit('0');
      final String result = engine.evaluate();
      expect(result, '180');
      expect(engine.tape, hasLength(1));
      expect(engine.tape.first.expression, '180');
    });

    test('multiple evaluations accumulate in order', () {
      for (final String value in <String>['180', '650', '1200']) {
        for (final String ch in value.split('')) {
          engine.inputDigit(ch);
        }
        engine.evaluate();
        engine.clearCurrent();
      }
      expect(engine.tape.map((e) => e.expression).toList(), <String>['180', '650', '1200']);
    });

    test('typing after evaluating starts a fresh expression', () {
      engine.inputDigit('5');
      engine.evaluate();
      engine.inputDigit('9');
      expect(engine.rawExpression, '9');
    });

    test('pressing an operator after evaluating continues from the result', () {
      engine.inputDigit('5');
      engine.evaluate();
      engine.inputOperator('+');
      engine.inputDigit('3');
      expect(engine.evaluate(), '8');
    });

    test('evaluating empty input throws', () {
      expect(() => engine.evaluate(), throwsA(isA<CalculatorException>()));
    });
  });

  group('deleting a tape entry (Quick Scan support, spec §9)', () {
    test('deleteTapeEntry removes the matching entry', () {
      engine.inputDigit('1');
      engine.evaluate();
      engine.clearCurrent();
      engine.inputDigit('2');
      engine.evaluate();

      final String idToDelete = engine.tape.first.id;
      engine.deleteTapeEntry(idToDelete);

      expect(engine.tape, hasLength(1));
      expect(engine.tape.first.expression, '2');
    });
  });
}
