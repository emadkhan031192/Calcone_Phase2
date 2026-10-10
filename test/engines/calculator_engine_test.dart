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
      expect(engine.tape.map((e) => e.expression).toList(), <String>[
        '180',
        '650',
        '1200',
      ]);
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

  group('exact precision when continuing from a result (spec §32)', () {
    test('1/3 = then × 3 = gives exactly 1', () {
      engine.inputDigit('1');
      engine.inputOperator('/');
      engine.inputDigit('3');
      engine.evaluate();
      engine.inputOperator('*');
      engine.inputDigit('3');
      expect(engine.evaluate(), '1');
    });

    test('0.1 + 0.2 = then + 0.4 = stays exact', () {
      for (final String ch in '0.1+0.2'.split('')) {
        if (ch == '.') {
          engine.inputDecimalPoint();
        } else if ('0123456789'.contains(ch)) {
          engine.inputDigit(ch);
        } else {
          engine.inputOperator(ch);
        }
      }
      expect(engine.evaluate(), '0.3');
      engine.inputOperator('+');
      engine.inputDigit('0');
      engine.inputDecimalPoint();
      engine.inputDigit('4');
      expect(engine.evaluate(), '0.7');
    });
  });

  group('long-press equals repeats the last operation (spec §17)', () {
    test('2 + 2 = then repeat gives 6, then 8', () {
      engine.inputDigit('2');
      engine.inputOperator('+');
      engine.inputDigit('2');
      expect(engine.evaluate(), '4');
      expect(engine.repeatLastOperation(), '6');
      expect(engine.repeatLastOperation(), '8');
    });

    test('500 + 10% = then repeat gives 605 (percent context kept)', () {
      for (final String ch in '500'.split('')) {
        engine.inputDigit(ch);
      }
      engine.inputOperator('+');
      for (final String ch in '10'.split('')) {
        engine.inputDigit(ch);
      }
      engine.inputPercent();
      expect(engine.evaluate(), '550');
      expect(engine.repeatLastOperation(), '605');
    });

    test('repeat while typing a new expression is a no-op', () {
      engine.inputDigit('2');
      engine.inputOperator('+');
      engine.inputDigit('2');
      engine.evaluate();
      engine.inputDigit('9');
      engine.inputOperator('*');
      engine.inputDigit('9');
      expect(engine.repeatLastOperation(), isNull);
      expect(engine.rawExpression, '9*9');
    });

    test('repeat with no previous evaluation is a no-op', () {
      expect(engine.repeatLastOperation(), isNull);
    });
  });

  group('smart parenthesis key', () {
    test('tap on empty input inserts (', () {
      engine.inputSmartParen();
      expect(engine.rawExpression, '(');
    });

    test('tap after a digit with an open paren inserts )', () {
      engine.inputSmartParen();
      engine.inputDigit('5');
      engine.inputOperator('+');
      engine.inputDigit('3');
      engine.inputSmartParen();
      expect(engine.rawExpression, '(5+3)');
    });

    test('tap with balanced parens inserts (', () {
      engine.inputSmartParen();
      engine.inputDigit('5');
      engine.inputSmartParen();
      engine.inputSmartParen();
      expect(engine.rawExpression, '(5)(');
    });

    test('tap after an operator inserts (', () {
      engine.inputDigit('5');
      engine.inputOperator('+');
      engine.inputSmartParen();
      expect(engine.rawExpression, '5+(');
    });
  });

  group('backspace after evaluation edits the result', () {
    test('backspace restores the result and deletes one character', () {
      engine.inputDigit('1');
      engine.inputDigit('2');
      engine.inputDigit('3');
      engine.inputOperator('+');
      engine.inputDigit('4');
      expect(engine.evaluate(), '127');
      engine.backspace();
      expect(engine.rawExpression, '12');
      expect(engine.evaluate(), '12');
    });
  });

  group('live preview (no tape side effects)', () {
    test('previewResult evaluates the in-progress expression', () {
      engine.inputDigit('5');
      engine.inputOperator('+');
      engine.inputDigit('1');
      engine.inputDigit('0');
      expect(engine.previewResult().toString(), '15');
      expect(engine.tape, isEmpty);
    });

    test('previewResult returns null for an incomplete expression', () {
      engine.inputDigit('5');
      engine.inputOperator('+');
      expect(engine.previewResult(), isNull);
    });

    test('previewResult returns null for empty input', () {
      expect(engine.previewResult(), isNull);
    });
  });
}
