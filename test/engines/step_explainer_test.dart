import 'package:calcone/engines/steps/step_explainer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StepExplainer (spec §25)', () {
    test('explains a smart percent addition', () {
      expect(
        StepExplainer.explain('500+10%'),
        <String>[
          '10% of 500 = 50',
          '500 + 50 = 550',
        ],
      );
    });

    test('explains a smart percent multiplication', () {
      expect(
        StepExplainer.explain('2500*15%'),
        <String>['15% of 2,500 = 375'],
      );
    });

    test('explains precedence in evaluation order', () {
      expect(
        StepExplainer.explain('2+3*4'),
        <String>[
          '3 × 4 = 12',
          '2 + 12 = 14',
        ],
      );
    });

    test('explains a parenthesized expression', () {
      expect(
        StepExplainer.explain('(2+3)*4'),
        <String>[
          '2 + 3 = 5',
          '5 × 4 = 20',
        ],
      );
    });

    test('returns null for a bare number (nothing to explain)', () {
      expect(StepExplainer.explain('42'), isNull);
    });

    test('returns null for invalid input instead of inventing steps', () {
      expect(StepExplainer.explain('5+'), isNull);
      expect(StepExplainer.explain(''), isNull);
    });

    test('returns null for overly complex expressions', () {
      expect(StepExplainer.explain('1+2+3+4+5+6+7+8'), isNull);
    });
  });
}
