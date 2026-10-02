import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import 'parser.dart';
import 'tokenizer.dart';

/// Public entry point for turning a raw expression string into an exact
/// [Rational] result. This is the only class the rest of the app needs to
/// know about; [Tokenizer], [Parser] and the AST are implementation detail.
class ExpressionEvaluator {
  const ExpressionEvaluator();

  Rational evaluate(String expression) {
    if (expression.trim().isEmpty) {
      throw CalculatorException.emptyInput;
    }
    final Tokenizer tokenizer = const Tokenizer();
    final List<Token> tokens = tokenizer.tokenize(expression);
    final Parser parser = Parser(tokens);
    return parser.parse().evaluate();
  }
}
