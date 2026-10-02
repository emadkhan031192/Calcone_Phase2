import 'package:rational/rational.dart';

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
  final String expression;
  final Rational result;
  final DateTime timestamp;
  final String? label;
  final bool isPinned;

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
