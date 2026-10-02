import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import 'ast.dart';
import 'tokenizer.dart';

/// Recursive-descent parser.
///
/// Grammar (highest precedence last):
///   expression := term (('+' | '-') term)*
///   term       := unary (('*' | '/') unary)*
///   unary      := '-' unary | percentPostfix
///   percentPostfix := primary '%'*
///   primary    := number | '(' expression ')'
///
/// Percent is a postfix suffix on whatever primary/parenthesized value
/// precedes it; its *meaning* (fraction vs. "percent of the left operand")
/// is resolved later, during evaluation, by [BinaryOpNode].
class Parser {
  Parser(List<Token> tokens) : _tokens = tokens;

  final List<Token> _tokens;
  int _pos = 0;

  Token? get _current => _pos < _tokens.length ? _tokens[_pos] : null;

  AstNode parse() {
    final AstNode node = _parseExpression();
    if (_current != null) {
      // Trailing tokens the grammar couldn't consume, e.g. "2)3".
      throw CalculatorException.malformedExpression;
    }
    return node;
  }

  AstNode _parseExpression() {
    AstNode node = _parseTerm();
    while (_current?.type == TokenType.plus || _current?.type == TokenType.minus) {
      final BinaryOperator op = _current!.type == TokenType.plus
          ? BinaryOperator.add
          : BinaryOperator.subtract;
      _advance();
      final AstNode right = _parseTerm();
      node = BinaryOpNode(op, node, right);
    }
    return node;
  }

  AstNode _parseTerm() {
    AstNode node = _parseUnary();
    while (_current?.type == TokenType.multiply || _current?.type == TokenType.divide) {
      final BinaryOperator op = _current!.type == TokenType.multiply
          ? BinaryOperator.multiply
          : BinaryOperator.divide;
      _advance();
      final AstNode right = _parseUnary();
      node = BinaryOpNode(op, node, right);
    }
    return node;
  }

  AstNode _parseUnary() {
    if (_current?.type == TokenType.minus) {
      _advance();
      return UnaryMinusNode(_parseUnary());
    }
    if (_current?.type == TokenType.plus) {
      // Leading/redundant unary plus — no-op, just skip it.
      _advance();
      return _parseUnary();
    }
    return _parsePercentPostfix();
  }

  AstNode _parsePercentPostfix() {
    AstNode node = _parsePrimary();
    while (_current?.type == TokenType.percent) {
      _advance();
      node = PercentNode(node);
    }
    return node;
  }

  AstNode _parsePrimary() {
    final Token? token = _current;
    if (token == null) {
      throw CalculatorException.malformedExpression;
    }

    if (token.type == TokenType.number) {
      _advance();
      return NumberNode(Rational.parse(token.value!));
    }

    if (token.type == TokenType.lparen) {
      _advance();
      final AstNode inner = _parseExpression();
      if (_current?.type != TokenType.rparen) {
        throw CalculatorException.unmatchedParentheses;
      }
      _advance();
      return inner;
    }

    // A unary minus that reached here already consumed itself in
    // _parseUnary; anything else at this position is malformed input, e.g.
    // "2 * * 3" or a trailing operator like "5 +".
    throw CalculatorException.malformedExpression;
  }

  void _advance() => _pos++;
}
