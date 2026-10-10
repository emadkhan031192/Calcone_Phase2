import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import '../../core/utils/number_formatter.dart';
import '../expression/ast.dart';
import '../expression/parser.dart';
import '../expression/tokenizer.dart';

/// Turns an evaluated expression into human-readable calculation steps
/// (spec §25).
///
/// Steps are derived from the actual AST evaluation order — never
/// invented. When the expression is too complex to explain safely (deep
/// nesting, many operations), [explain] returns null and callers should
/// show the result without steps.
abstract final class StepExplainer {
  static const int _maxSteps = 8;

  static List<String>? explain(String expression) {
    try {
      final AstNode root = Parser(Tokenizer().tokenize(expression)).parse();
      if (_binaryOpCount(root) > 6) return null;
      final List<String> steps = <String>[];
      _explainNode(root, steps);
      if (steps.isEmpty || steps.length > _maxSteps) return null;
      return steps;
    } on CalculatorException {
      return null;
    }
  }

  static int _binaryOpCount(AstNode node) {
    return switch (node) {
      BinaryOpNode(:final left, :final right) =>
        1 + _binaryOpCount(left) + _binaryOpCount(right),
      PercentNode(:final inner) => _binaryOpCount(inner),
      UnaryMinusNode(:final operand) => _binaryOpCount(operand),
      NumberNode() => 0,
    };
  }

  static void _explainNode(AstNode node, List<String> steps) {
    switch (node) {
      case BinaryOpNode(:final op, :final left, :final right):
        final Rational leftVal = left.evaluate();
        if (right is PercentNode) {
          _explainPercentOp(op, left, leftVal, right, steps);
          return;
        }
        _explainNode(left, steps);
        _explainNode(right, steps);
        final Rational rightVal = right.evaluate();
        final Rational result = node.evaluate();
        steps.add(
          '${_fmt(leftVal)} ${_glyph(op)} ${_fmt(rightVal)} = ${_fmt(result)}',
        );
      case PercentNode(:final inner):
        final Rational raw = inner.evaluate();
        steps.add('${_fmt(raw)}% = ${_fmt(node.evaluate())}');
      case UnaryMinusNode(:final operand):
        _explainNode(operand, steps);
        if (operand is! NumberNode) {
          steps
              .add('−(${_fmt(operand.evaluate())}) = ${_fmt(node.evaluate())}');
        }
      case NumberNode():
        break;
    }
  }

  static void _explainPercentOp(
    BinaryOperator op,
    AstNode left,
    Rational leftVal,
    PercentNode right,
    List<String> steps,
  ) {
    final Rational pctRaw = right.rawValue;
    final Rational fraction = pctRaw / Rational.fromInt(100);
    _explainNode(left, steps);
    switch (op) {
      case BinaryOperator.add:
      case BinaryOperator.subtract:
        final Rational part = leftVal * fraction;
        final String sign = op == BinaryOperator.add ? '+' : '−';
        final Rational result =
            op == BinaryOperator.add ? leftVal + part : leftVal - part;
        steps.add('${_fmt(pctRaw)}% of ${_fmt(leftVal)} = ${_fmt(part)}');
        steps.add('${_fmt(leftVal)} $sign ${_fmt(part)} = ${_fmt(result)}');
      case BinaryOperator.multiply:
        steps.add(
          '${_fmt(pctRaw)}% of ${_fmt(leftVal)} = ${_fmt(leftVal * fraction)}',
        );
      case BinaryOperator.divide:
        steps.add('${_fmt(pctRaw)}% = ${_fmt(fraction)}');
        steps.add(
          '${_fmt(leftVal)} ÷ ${_fmt(fraction)} = ${_fmt(leftVal / fraction)}',
        );
    }
  }

  static String _fmt(Rational value) => NumberFormatter.format(value);

  static String _glyph(BinaryOperator op) => switch (op) {
        BinaryOperator.add => '+',
        BinaryOperator.subtract => '−',
        BinaryOperator.multiply => '×',
        BinaryOperator.divide => '÷',
      };
}
