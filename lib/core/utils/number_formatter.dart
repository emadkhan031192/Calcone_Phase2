import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

import '../constants/app_constants.dart';

/// Formats exact [Rational] values for display: thousands separators,
/// trimmed trailing zeros, and a display-precision cap that never mutates
/// the underlying exact value the calculation tape stores (spec §5, §32).
///
/// Internal precision (the [Rational] carried through the AST) and visual
/// formatting are kept strictly separate — this class only ever *reads* a
/// value to produce a display string; it never rounds the value that gets
/// stored back into the tape or used as an operand in the next step.
///
/// Grouping/trimming is implemented as plain string manipulation on
/// [Decimal.toString]'s exact plain-decimal output, deliberately avoiding
/// `package:intl`'s NumberFormat (which only accepts a Dart `num` — routing
/// a whole-number part through `double` would silently lose precision on
/// any value bigger than 2^53, exactly the class of bug this app exists to
/// avoid) and avoiding any Decimal/Rational conversion methods beyond the
/// well-documented `toString()`.
abstract final class NumberFormatter {
  /// e.g. 1250000 -> "1,250,000"; 25.0000 -> "25"; (1/10 + 2/10) -> "0.3".
  static String format(
    Rational value, {
    int maxDecimalPlaces = AppConstants.maxDisplayDecimalPlaces,
  }) {
    final Decimal rounded = _toRoundedDecimal(value, maxDecimalPlaces);
    String plain = rounded.toString(); // e.g. "-1250.5", "25", "0.3"

    final bool isNegative = plain.startsWith('-');
    if (isNegative) plain = plain.substring(1);

    final int dotIndex = plain.indexOf('.');
    final String wholeDigits = dotIndex == -1 ? plain : plain.substring(0, dotIndex);
    String fractionalDigits = dotIndex == -1 ? '' : plain.substring(dotIndex + 1);

    // Trim trailing zeros without losing significant digits.
    fractionalDigits = fractionalDigits.replaceFirst(RegExp(r'0+$'), '');

    final String groupedWhole = _groupDigits(wholeDigits);
    final String body = fractionalDigits.isEmpty ? groupedWhole : '$groupedWhole.$fractionalDigits';

    // Never show a signed zero.
    final bool isZero = groupedWhole == '0' && fractionalDigits.isEmpty;
    return (isNegative && !isZero) ? '-$body' : body;
  }

  /// Rounds a [Rational] to at most [maxDecimalPlaces] and returns it as a
  /// [Decimal] purely for formatting purposes — the caller's own copy of
  /// the value (e.g. in the calculation tape) is untouched.
  ///
  /// A value with finite decimal precision (e.g. 1/8 = 0.125) is converted
  /// exactly first, then capped with [Decimal.round] in case it still has
  /// more digits than [maxDecimalPlaces]. A non-terminating value (e.g.
  /// 1/3) has no exact decimal form, so it's rounded during conversion via
  /// `scaleOnInfinitePrecision`.
  static Decimal _toRoundedDecimal(Rational value, int maxDecimalPlaces) {
    if (value.hasFinitePrecision) {
      return value.toDecimal().round(scale: maxDecimalPlaces);
    }
    return value.toDecimal(scaleOnInfinitePrecision: maxDecimalPlaces);
  }

  /// Inserts a thousands separator every 3 digits from the right, on the
  /// raw digit string — arbitrary precision, no `num` conversion involved.
  static String _groupDigits(String digits) {
    final StringBuffer out = StringBuffer();
    final int len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }
}
