import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import '../expression/expression_evaluator.dart';
import '../expression/tokenizer.dart';

/// One top-level additive term of an expression, e.g. the `450` in
/// `180+650+450`. The [sign] is stored separately so editing the term
/// text can never accidentally drop (or duplicate) its operator.
class ExpressionTerm {
  const ExpressionTerm({
    required this.sign,
    required this.text,
    required this.value,
  });

  /// '' for the first term, otherwise '+' or '-'.
  final String sign;

  /// The term's source text without its leading sign, e.g. `450`, `2*3`.
  final String text;

  /// The signed evaluated value.
  final Rational value;

  /// Source text including the sign, for rebuilding the expression.
  String get source => '$sign$text';
}

/// Splits an expression into its top-level additive terms for Quick Scan
/// (spec §8–§9): `180+650+450` → `[180, +650, +450]`.
///
/// Parenthesized groups and nested `*`/`/` stay inside their term; unary
/// signs stay attached to their term. A context-aware `%` can never be
/// decomposed safely, so such expressions come back as a single term —
/// editing it edits the whole expression, which is always safe.
abstract final class ExpressionDecomposer {
  static List<ExpressionTerm>? decompose(String expression) {
    final String trimmed = expression.trim();
    if (trimmed.isEmpty) return null;
    try {
      const ExpressionEvaluator evaluator = ExpressionEvaluator();
      if (trimmed.contains('%')) {
        return <ExpressionTerm>[
          ExpressionTerm(
            sign: '',
            text: trimmed,
            value: evaluator.evaluate(trimmed),
          ),
        ];
      }
      final List<Token> tokens = Tokenizer().tokenize(trimmed);
      final List<ExpressionTerm> terms = <ExpressionTerm>[];
      final StringBuffer currentText = StringBuffer();
      String currentSign = '';
      int depth = 0;
      bool hasTokens = false;

      void flush() {
        if (!hasTokens) return;
        final String body = currentText.toString();
        terms.add(ExpressionTerm(
          sign: currentSign,
          text: body,
          value: evaluator.evaluate('$currentSign$body'),
        ));
        currentText.clear();
        hasTokens = false;
      }

      for (int i = 0; i < tokens.length; i++) {
        final Token token = tokens[i];
        if (token.type == TokenType.lparen) depth++;
        if (token.type == TokenType.rparen) depth--;
        if (depth == 0 && _isBinarySplit(tokens, i)) {
          flush();
          currentSign = _tokenText(token);
        } else {
          currentText.write(_tokenText(token));
          hasTokens = true;
        }
      }
      flush();
      return terms.isEmpty ? null : terms;
    } on CalculatorException {
      return null;
    }
  }

  /// A top-level `+`/`-` separates terms — unless it's unary (leading, or
  /// right after another operator, `%`, or an opening paren).
  static bool _isBinarySplit(List<Token> tokens, int i) {
    final Token token = tokens[i];
    if (token.type != TokenType.plus && token.type != TokenType.minus) {
      return false;
    }
    if (i == 0) return false;
    final TokenType prev = tokens[i - 1].type;
    return prev != TokenType.plus &&
        prev != TokenType.minus &&
        prev != TokenType.multiply &&
        prev != TokenType.divide &&
        prev != TokenType.lparen &&
        prev != TokenType.percent;
  }

  /// The source characters a token came from (operators carry no value).
  static String _tokenText(Token token) {
    if (token.value != null) return token.value!;
    return switch (token.type) {
      TokenType.plus => '+',
      TokenType.minus => '-',
      TokenType.multiply => '*',
      TokenType.divide => '/',
      TokenType.percent => '%',
      TokenType.lparen => '(',
      TokenType.rparen => ')',
      TokenType.number => '',
    };
  }
}
