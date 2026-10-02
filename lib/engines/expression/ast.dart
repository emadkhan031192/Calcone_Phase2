import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';

/// Base type for all expression-tree nodes.
///
/// Internally everything evaluates to a [Rational], not a Decimal.
/// Decimal is not closed under division (1/3 has no terminating decimal
/// expansion), so keeping exact fractions throughout the tree — and only
/// converting to a fixed-scale Decimal at display time, in
/// NumberFormatter — is what keeps "0.1 + 0.2" exactly "0.3" and avoids
/// ever accumulating floating-point noise (spec §32).
///
/// The "smart percentage" behaviour (spec §6) lives in [BinaryOpNode]:
/// it inspects whether its right-hand operand is a [PercentNode] and, for
/// `+`/`-`, resolves it as a percentage *of the left operand* rather than a
/// bare fraction. For `*`/`/` (and when a percent appears with no enclosing
/// operator) it resolves as a plain fraction (V / 100).
sealed class AstNode {
  const AstNode();

  Rational evaluate();
}

final class NumberNode extends AstNode {
  const NumberNode(this.value);

  final Rational value;

  @override
  Rational evaluate() => value;
}

final Rational _oneHundred = Rational.fromInt(100);

/// Wraps an operand that was suffixed with `%` in the original expression.
/// [rawValue] evaluates to the number *before* dividing by 100 — the parent
/// [BinaryOpNode] decides how to interpret it contextually.
final class PercentNode extends AstNode {
  const PercentNode(this.inner);

  final AstNode inner;

  Rational get rawValue => inner.evaluate();

  /// Standalone fallback: a percent with no enclosing binary operator (e.g.
  /// the whole expression is just "50%", or it's inside parentheses) is a
  /// plain fraction.
  @override
  Rational evaluate() => rawValue / _oneHundred;
}

final class UnaryMinusNode extends AstNode {
  const UnaryMinusNode(this.operand);

  final AstNode operand;

  @override
  Rational evaluate() => -operand.evaluate();
}

enum BinaryOperator { add, subtract, multiply, divide }

final class BinaryOpNode extends AstNode {
  const BinaryOpNode(this.op, this.left, this.right);

  final BinaryOperator op;
  final AstNode left;
  final AstNode right;

  @override
  Rational evaluate() {
    final Rational leftVal = left.evaluate();

    if (right is PercentNode) {
      final Rational percentFraction = (right as PercentNode).rawValue / _oneHundred;

      switch (op) {
        case BinaryOperator.add:
          return leftVal + (leftVal * percentFraction);
        case BinaryOperator.subtract:
          return leftVal - (leftVal * percentFraction);
        case BinaryOperator.multiply:
          return leftVal * percentFraction;
        case BinaryOperator.divide:
          if (percentFraction == Rational.zero) {
            throw CalculatorException.divisionByZero;
          }
          return leftVal / percentFraction;
      }
    }

    final Rational rightVal = right.evaluate();
    switch (op) {
      case BinaryOperator.add:
        return leftVal + rightVal;
      case BinaryOperator.subtract:
        return leftVal - rightVal;
      case BinaryOperator.multiply:
        return leftVal * rightVal;
      case BinaryOperator.divide:
        if (rightVal == Rational.zero) {
          throw CalculatorException.divisionByZero;
        }
        return leftVal / rightVal;
    }
  }
}
