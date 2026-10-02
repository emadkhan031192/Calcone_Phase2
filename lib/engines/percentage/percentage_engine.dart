import 'package:rational/rational.dart';

/// Pure, stateless percentage functions.
///
/// The calculator's *inline* "500 + 10%" behaviour lives in the expression
/// AST ([BinaryOpNode]) because it needs parser context. This engine is for
/// everything else that needs a percentage calculation without typing an
/// expression — e.g. a future Finance module's discount/markup/margin
/// tools (spec §24) — kept here so that logic isn't duplicated or
/// re-derived per feature.
abstract final class PercentageEngine {
  static final Rational _hundred = Rational.fromInt(100);

  /// What is [percent]% of [base]?
  static Rational percentOf(Rational base, Rational percent) => base * percent / _hundred;

  /// [base] increased by [percent]%.
  static Rational increaseBy(Rational base, Rational percent) => base + percentOf(base, percent);

  /// [base] decreased by [percent]% (e.g. a discount).
  static Rational decreaseBy(Rational base, Rational percent) => base - percentOf(base, percent);

  /// What percentage does [part] represent of [whole]?
  static Rational whatPercent(Rational part, Rational whole) {
    if (whole == Rational.zero) return Rational.zero;
    return part / whole * _hundred;
  }

  /// Percentage change from [from] to [to] (positive = increase).
  static Rational percentChange(Rational from, Rational to) {
    if (from == Rational.zero) return Rational.zero;
    return (to - from) / from * _hundred;
  }

  /// Markup: given a cost and a desired markup %, returns the sale price.
  /// sale = cost * (1 + markup/100)
  static Rational markupPrice(Rational cost, Rational markupPercent) =>
      increaseBy(cost, markupPercent);

  /// Margin: given a sale price and a desired margin %, returns the cost
  /// that yields that margin. cost = sale * (1 - margin/100)
  static Rational costForMargin(Rational salePrice, Rational marginPercent) =>
      decreaseBy(salePrice, marginPercent);
}
