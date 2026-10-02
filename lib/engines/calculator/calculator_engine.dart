import 'package:rational/rational.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/calculator_exception.dart';
import '../../core/utils/number_formatter.dart';
import '../../models/calculation_entry.dart';
import '../expression/expression_evaluator.dart';

/// Plain-Dart, UI-agnostic calculator state machine.
///
/// This is the single owner of "what is currently on screen" and "what has
/// the user calculated this session" (the tape, spec §7). It knows nothing
/// about Flutter or Riverpod — the features/basic layer wraps it in a
/// StateNotifier so widgets can listen for changes, and unit tests can
/// exercise it directly without pumping a widget tree.
class CalculatorEngine {
  CalculatorEngine({ExpressionEvaluator? evaluator})
      : _evaluator = evaluator ?? const ExpressionEvaluator();

  final ExpressionEvaluator _evaluator;
  static const List<String> _binaryOps = <String>[
    AppConstants.opAdd,
    AppConstants.opSubtract,
    AppConstants.opMultiply,
    AppConstants.opDivide,
  ];

  String _expression = '';
  Rational? _lastResult;
  bool _justEvaluated = false;

  /// For "long press equals repeats the previous operation" (spec §17):
  /// remembers the operator+operand that produced [_lastResult] so it can
  /// be re-applied to the new left-hand value.
  String? _lastOperator;
  Rational? _lastOperand;

  final List<CalculationEntry> _tape = <CalculationEntry>[];
  int _nextId = 0;

  /// Raw, ASCII-operator expression exactly as the parser will see it.
  String get rawExpression => _expression;

  /// Read-only view of this session's calculation tape, oldest first.
  List<CalculationEntry> get tape => List<CalculationEntry>.unmodifiable(_tape);

  bool get hasResult => _lastResult != null;

  /// The expression, rewritten with display glyphs (×, ÷, −) instead of the
  /// internal ASCII operators, for showing above the result (spec §5).
  String get displayExpression {
    return _expression
        .replaceAll(AppConstants.opMultiply, AppConstants.glyphMultiply)
        .replaceAll(AppConstants.opDivide, AppConstants.glyphDivide)
        .replaceAll(AppConstants.opSubtract, AppConstants.glyphSubtract);
  }

  /// Appends a digit ('0'-'9').
  void inputDigit(String digit) {
    if (_expression.length >= AppConstants.maxExpressionLength) return;
    if (_justEvaluated) {
      _startFresh();
    }
    _expression += digit;
  }

  void inputDecimalPoint() {
    if (_justEvaluated) _startFresh();
    final String currentSegment = _currentNumberSegment();
    if (currentSegment.contains('.')) return; // one decimal point per number
    _expression += currentSegment.isEmpty ? '0.' : '.';
  }

  /// '+', '-', '*', '/'. Replaces a trailing operator rather than stacking
  /// them (so "5 + + " becomes "5 +", not "5 + +").
  void inputOperator(String op) {
    if (!_binaryOps.contains(op)) return;

    if (_expression.isEmpty) {
      // Only a leading minus makes sense with nothing typed yet.
      if (op == AppConstants.opSubtract) _expression = op;
      return;
    }

    if (_justEvaluated && _lastResult != null) {
      _expression = NumberFormatter.format(_lastResult!, maxDecimalPlaces: 20)
          .replaceAll(',', '');
      _justEvaluated = false;
    }

    final String lastChar = _expression[_expression.length - 1];
    if (_binaryOps.contains(lastChar)) {
      _expression = _expression.substring(0, _expression.length - 1) + op;
    } else {
      _expression += op;
    }
  }

  void inputPercent() {
    if (_expression.isEmpty) return;
    if (_justEvaluated) _startFresh();
    final String lastChar = _expression[_expression.length - 1];
    if (_binaryOps.contains(lastChar) ||
        lastChar == AppConstants.glyphPercent) {
      return;
    }
    _expression += AppConstants.opPercent;
  }

  void inputOpenParen() {
    if (_justEvaluated) _startFresh();
    _expression += AppConstants.glyphOpenParen;
  }

  void inputCloseParen() {
    if (_justEvaluated) return;
    final int opens = '('.allMatches(_expression).length;
    final int closes = ')'.allMatches(_expression).length;
    if (opens > closes) _expression += AppConstants.glyphCloseParen;
  }

  void backspace() {
    if (_justEvaluated) {
      _startFresh();
      return;
    }
    if (_expression.isEmpty) return;
    _expression = _expression.substring(0, _expression.length - 1);
  }

  /// Clears the current expression only (tape is untouched) — the "C"
  /// behaviour most users expect.
  void clearCurrent() {
    _expression = '';
    _justEvaluated = false;
  }

  /// Clears the current expression AND the session tape (a hard reset).
  void clearAll() {
    _expression = '';
    _justEvaluated = false;
    _tape.clear();
    _lastResult = null;
    _lastOperator = null;
    _lastOperand = null;
  }

  /// Evaluates the current expression, appends it to the tape, and returns
  /// the formatted display string. Throws [CalculatorException] on invalid
  /// input — callers (the UI layer) are expected to catch this and show
  /// the exception's friendly [CalculatorException.message].
  String evaluate() {
    if (_expression.isEmpty) {
      throw CalculatorException.emptyInput;
    }

    final Rational result = _evaluator.evaluate(_expression);
    _rememberRepeatOperation();

    final CalculationEntry entry = CalculationEntry(
      id: (_nextId++).toString(),
      expression: displayExpression,
      result: result,
      timestamp: DateTime.now(),
    );
    _tape.add(entry);

    _lastResult = result;
    _justEvaluated = true;
    return NumberFormatter.format(result);
  }

  /// Long-press equals: re-applies the last operator/operand to the
  /// current result (spec §17). No-op if there's nothing to repeat.
  String? repeatLastOperation() {
    if (_lastOperator == null || _lastOperand == null || _lastResult == null) {
      return null;
    }
    final String leftOperand =
        NumberFormatter.format(_lastResult!, maxDecimalPlaces: 20).replaceAll(',', '');
    final String rightOperand =
        NumberFormatter.format(_lastOperand!, maxDecimalPlaces: 20).replaceAll(',', '');
    _expression = '$leftOperand$_lastOperator$rightOperand';
    return evaluate();
  }

  void deleteTapeEntry(String id) {
    _tape.removeWhere((CalculationEntry e) => e.id == id);
  }

  /// Used by Quick Scan (spec §9) to edit a past input and recalculate.
  /// Full recalculation-of-dependent-entries lands with the Quick Scan
  /// feature; for now this updates the single entry in place.
  void editTapeEntry(String id, Rational newValue, String newExpression) {
    final int index = _tape.indexWhere((CalculationEntry e) => e.id == id);
    if (index == -1) return;
    _tape[index] = _tape[index].copyWith(
      result: newValue,
      expression: newExpression,
    );
  }

  String _currentNumberSegment() {
    final int lastOpIndex = _lastOperatorIndex();
    return _expression.substring(lastOpIndex + 1);
  }

  int _lastOperatorIndex() {
    for (int i = _expression.length - 1; i >= 0; i--) {
      if (_binaryOps.contains(_expression[i]) && i != 0) {
        return i;
      }
    }
    return -1;
  }

  void _startFresh() {
    _expression = '';
    _justEvaluated = false;
  }

  void _rememberRepeatOperation() {
    final int lastOpIndex = _lastOperatorIndex();
    if (lastOpIndex == -1) {
      _lastOperator = null;
      _lastOperand = null;
      return;
    }
    final String operand = _expression.substring(lastOpIndex + 1);
    if (operand.isEmpty) {
      _lastOperator = null;
      _lastOperand = null;
      return;
    }
    try {
      _lastOperator = _expression[lastOpIndex];
      _lastOperand = _evaluator.evaluate(operand);
    } on CalculatorException {
      _lastOperator = null;
      _lastOperand = null;
    }
  }
}
