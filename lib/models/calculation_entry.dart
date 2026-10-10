import 'package:rational/rational.dart';

import '../core/constants/app_constants.dart';

/// A single completed calculation, as it appears in the calculation tape
/// (spec §7), Quick Scan (spec §8), and History (spec §20).
///
/// [result] is kept as an exact [Rational] so a later edit-and-recalculate
/// (Quick Scan §9) never compounds rounding error — only [displayResult]
/// (produced by NumberFormatter at render time) is ever rounded.
class CalculationEntry {
  CalculationEntry({
    required this.id,
    required this.expression,
    required this.result,
    required this.timestamp,
    this.label,
    this.isPinned = false,
  });

  final String id;

  /// The raw expression (ASCII operators) as the parser saw it. Render
  /// [displayExpression] for the user; use this for re-evaluation.
  final String expression;
  final Rational result;
  final DateTime timestamp;
  final String? label;
  final bool isPinned;

  /// The expression rewritten with display glyphs (×, ÷, −) for the UI.
  String get displayExpression {
    return expression
        .replaceAll(AppConstants.opMultiply, AppConstants.glyphMultiply)
        .replaceAll(AppConstants.opDivide, AppConstants.glyphDivide)
        .replaceAll(AppConstants.opSubtract, AppConstants.glyphSubtract);
  }

  CalculationEntry copyWith({
    String? expression,
    Rational? result,
    String? label,
    bool? isPinned,
  }) {
    return CalculationEntry(
      id: id,
      expression: expression ?? this.expression,
      result: result ?? this.result,
      timestamp: timestamp,
      label: label ?? this.label,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
