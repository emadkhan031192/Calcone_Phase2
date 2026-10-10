import 'package:calcone/engines/decomposition/expression_decomposer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpressionDecomposer (spec §8–§9)', () {
    test('splits a chained addition into terms', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('180+650+1200+450+320+750');
      expect(terms, isNotNull);
      expect(terms!.map((t) => t.source).toList(), <String>[
        '180',
        '+650',
        '+1200',
        '+450',
        '+320',
        '+750',
      ]);
      expect(
        terms.map((t) => t.value.toString()).toList(),
        <String>['180', '650', '1200', '450', '320', '750'],
      );
    });

    test('keeps subtraction signs attached to their terms', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('100-20+5');
      expect(terms!.map((t) => t.source).toList(), <String>[
        '100',
        '-20',
        '+5',
      ]);
      expect(terms.map((t) => t.value.toString()).toList(),
          <String>['100', '-20', '5']);
    });

    test('keeps nested multiply/divide inside their term', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('2+3*4');
      expect(terms!.map((t) => t.source).toList(), <String>['2', '+3*4']);
      expect(
          terms.map((t) => t.value.toString()).toList(), <String>['2', '12']);
    });

    test('keeps parenthesized groups whole', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('(2+3)*4+10');
      expect(terms!.map((t) => t.source).toList(), <String>[
        '(2+3)*4',
        '+10',
      ]);
    });

    test('handles a leading unary minus', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('-5+3');
      expect(terms!.map((t) => t.source).toList(), <String>['-5', '+3']);
      expect(
          terms.map((t) => t.value.toString()).toList(), <String>['-5', '3']);
    });

    test('percent expressions stay whole (never decomposed)', () {
      final List<ExpressionTerm>? terms =
          ExpressionDecomposer.decompose('500+10%');
      expect(terms, hasLength(1));
      expect(terms!.single.source, '500+10%');
      expect(terms.single.value.toString(), '550');
    });

    test('a single value is a single term', () {
      final List<ExpressionTerm>? terms = ExpressionDecomposer.decompose('42');
      expect(terms, hasLength(1));
      expect(terms!.single.value.toString(), '42');
    });

    test('returns null for empty or invalid input', () {
      expect(ExpressionDecomposer.decompose(''), isNull);
      expect(ExpressionDecomposer.decompose('5+'), isNotNull);
      expect(ExpressionDecomposer.decompose('('), isNull);
    });
  });
}
