import '../../core/errors/calculator_exception.dart';

enum TokenType { number, plus, minus, multiply, divide, percent, lparen, rparen }

class Token {
  const Token(this.type, [this.value]);

  final TokenType type;
  final String? value;

  @override
  String toString() => value ?? type.name;
}

/// Converts a raw expression string (using the engine's internal ASCII
/// operators — see [AppConstants]) into a flat list of [Token]s.
///
/// Kept deliberately dumb: it does not know about operator precedence or
/// grouping. That is the parser's job. This makes the tokenizer trivial to
/// unit test in isolation and reuse for input validation (e.g. "can I add
/// another decimal point right now?").
class Tokenizer {
  static const String _operatorChars = '+-*/%()';

  List<Token> tokenize(String expression) {
    final List<Token> tokens = <Token>[];
    final String source = expression.replaceAll(' ', '');
    if (source.isEmpty) {
      throw CalculatorException.emptyInput;
    }

    int i = 0;
    while (i < source.length) {
      final String char = source[i];

      if (_operatorChars.contains(char)) {
        tokens.add(_operatorToken(char));
        i++;
        continue;
      }

      if (_isDigit(char) || char == '.') {
        final StringBuffer buffer = StringBuffer();
        bool sawDecimalPoint = false;
        while (i < source.length && (_isDigit(source[i]) || source[i] == '.')) {
          if (source[i] == '.') {
            if (sawDecimalPoint) {
              throw CalculatorException.malformedExpression;
            }
            sawDecimalPoint = true;
          }
          buffer.write(source[i]);
          i++;
        }
        String numeric = buffer.toString();
        if (numeric.startsWith('.')) numeric = '0$numeric';
        if (numeric.endsWith('.')) numeric = '${numeric}0';
        tokens.add(Token(TokenType.number, numeric));
        continue;
      }

      throw CalculatorException.malformedExpression;
    }

    return tokens;
  }

  bool _isDigit(String char) => char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  Token _operatorToken(String char) {
    switch (char) {
      case '+':
        return const Token(TokenType.plus);
      case '-':
        return const Token(TokenType.minus);
      case '*':
        return const Token(TokenType.multiply);
      case '/':
        return const Token(TokenType.divide);
      case '%':
        return const Token(TokenType.percent);
      case '(':
        return const Token(TokenType.lparen);
      case ')':
        return const Token(TokenType.rparen);
      default:
        throw CalculatorException.malformedExpression;
    }
  }
}
