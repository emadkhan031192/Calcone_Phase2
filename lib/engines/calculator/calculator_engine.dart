import 'package:decimal/decimal.dart';
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

  /// Raw expression text that produced [_lastResult] (for Show Steps and
  /// sharing, spec §25/§12). [_expression] may have moved on since.
  String _lastEvaluatedExpression = '';

  /// For "long press equals repeats the previous operation" (spec §17):
  /// remembers the operator and the original operand *text* (e.g. "10%",
  /// not its evaluated value) that produced [_lastResult], so repeating
  /// "500+10%=" gives 605 instead of 550.1.
  String? _lastOperator;
  String? _lastOperandExpression;

  final List<CalculationEntry> _tape = <CalculationEntry>[];
  int _nextId = 0;

  /// Raw, ASCII-operator expression exactly as the parser will see it.
  String get rawExpression => _expression;

  /// Read-only view of this session's calculation tape, oldest first.
  List<CalculationEntry> get tape => List<CalculationEntry>.unmodifiable(_tape);

  bool get hasResult => _lastResult != null;

  bool get justEvaluated => _justEvaluated;

  /// Raw expression text that produced the last result.
  String get lastEvaluatedExpression => _lastEvaluatedExpression;

  /// Rewrites raw expression text with display glyphs (×, ÷, −).
  static String toDisplayString(String raw) {
    return raw
        .replaceAll(AppConstants.opMultiply, AppConstants.glyphMultiply)
        .replaceAll(AppConstants.opDivide, AppConstants.glyphDivide)
        .replaceAll(AppConstants.opSubtract, AppConstants.glyphSubtract);
  }

  /// The expression, rewritten with display glyphs (×, ÷, −) instead of the
  /// internal ASCII operators, for showing above the result (spec §5).
  String get displayExpression => toDisplayString(_expression);

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
      // Seed the new expression from the exact result — never round-trip
      // through display formatting, or "1/3 = × 3 =" would give
      // 0.99999999999999999999 instead of 1 (spec §32).
      _expression = _losslessString(_lastResult!);
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

  /// Smart parenthesis key: inserts ")" when there is an unclosed "(" and
  /// the cursor sits right after a value (digit, ")" or "%"); otherwise
  /// inserts "(". One tap always does the sensible thing — no hidden
  /// long-press needed to close a parenthesis.
  void inputSmartParen() {
    if (_expression.length >= AppConstants.maxExpressionLength) return;
    if (_justEvaluated) _startFresh();
    if (_expression.isEmpty) {
      _expression += AppConstants.glyphOpenParen;
      return;
    }
    final int opens = '('.allMatches(_expression).length;
    final int closes = ')'.allMatches(_expression).length;
    final String lastChar = _expression[_expression.length - 1];
    final bool lastIsValue = _isDigit(lastChar) ||
        lastChar == AppConstants.glyphCloseParen ||
        lastChar == AppConstants.glyphPercent;
    if (opens > closes && lastIsValue) {
      _expression += AppConstants.glyphCloseParen;
    } else {
      _expression += AppConstants.glyphOpenParen;
    }
  }

  void backspace() {
    if (_justEvaluated) {
      // Let the user edit the result they just got instead of wiping it:
      // restore the exact value, then delete one character as usual.
      if (_lastResult == null) {
        _startFresh();
        return;
      }
      _expression = _losslessString(_lastResult!);
      _justEvaluated = false;
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
    _lastOperandExpression = null;
    _lastEvaluatedExpression = '';
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
    _lastEvaluatedExpression = _expression;

    final CalculationEntry entry = CalculationEntry(
      id: (_nextId++).toString(),
      // Stored raw (ASCII operators): the UI renders display glyphs, and
      // edit-and-recalculate (Quick Scan) needs a re-parseable expression.
      expression: _expression,
      result: result,
      timestamp: DateTime.now(),
    );
    _tape.add(entry);

    _lastResult = result;
    _justEvaluated = true;
    return NumberFormatter.format(result);
  }

  /// Long-press equals: re-applies the last operator/operand to the
  /// current result (spec §17). Only valid immediately after an
  /// evaluation — long-pressing while a new expression is being typed is
  /// a no-op instead of replaying a stale operation over what the user
  /// typed. Returns null when there is nothing valid to repeat.
  String? repeatLastOperation() {
    if (!_justEvaluated) return null;
    if (_lastOperator == null ||
        _lastOperandExpression == null ||
        _lastResult == null) {
      return null;
    }
    _expression =
        '${_losslessString(_lastResult!)}$_lastOperator$_lastOperandExpression';
    try {
      return evaluate();
    } on CalculatorException {
      return null;
    }
  }

  /// Best-effort evaluation of the current expression for the live result
  /// preview, without touching the tape or the repeat state. Returns null
  /// when the expression is empty or not complete enough to evaluate yet
  /// (e.g. a trailing operator) — callers should keep the previous
  /// preview in that case.
  Rational? previewResult() {
    if (_expression.isEmpty) return null;
    try {
      return _evaluator.evaluate(_expression);
    } on CalculatorException {
      return null;
    }
  }

  void deleteTapeEntry(String id) {
    _tape.removeWhere((CalculationEntry e) => e.id == id);
  }

  /// Inserts [entry] back at [index] (used by undo).
  void insertTapeEntry(int index, CalculationEntry entry) {
    _tape.insert(index.clamp(0, _tape.length), entry);
    int maxId = _nextId - 1;
    final int? parsed = int.tryParse(entry.id);
    if (parsed != null && parsed >= _nextId) maxId = parsed;
    _nextId = maxId + 1;
  }

  /// Clears the session tape without touching the in-progress expression.
  void clearTape() {
    _tape.clear();
  }

  /// Replaces the in-progress expression (used by undo).
  void restoreExpression(String expression) {
    _expression = expression;
    _justEvaluated = false;
  }

  /// Restores a previously persisted session (spec §19): replaces the
  /// tape and the in-progress expression wholesale. Repeat state is
  /// cleared — the restored expression was never evaluated here.
  void restoreSession(List<CalculationEntry> entries, String expression) {
    _tape
      ..clear()
      ..addAll(entries);
    int maxId = -1;
    for (final CalculationEntry e in entries) {
      final int? parsed = int.tryParse(e.id);
      if (parsed != null && parsed > maxId) maxId = parsed;
    }
    _nextId = maxId + 1;
    _expression = expression;
    _justEvaluated = false;
    _lastResult = null;
    _lastOperator = null;
    _lastOperandExpression = null;
    _lastEvaluatedExpression = '';
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
      _lastOperandExpression = null;
      return;
    }
    final String operand = _expression.substring(lastOpIndex + 1);
    if (operand.isEmpty) {
      _lastOperator = null;
      _lastOperandExpression = null;
      return;
    }
    // Keep the operand's original text (e.g. "10%", not 0.1) so the smart
    // percentage meaning survives the repeat. Validate that it parses so
    // a repeat can never build garbage.
    try {
      _evaluator.evaluate(operand);
    } on CalculatorException {
      _lastOperator = null;
      _lastOperandExpression = null;
      return;
    }
    _lastOperator = _expression[lastOpIndex];
    _lastOperandExpression = operand;
  }

  /// Converts a [Rational] back to expression text without losing
  /// exactness: a plain decimal when the value terminates, otherwise the
  /// fraction in parentheses (e.g. "(1/3)"), which the parser reads back
  /// exactly. Never route through display formatting here (spec §32).
  String _losslessString(Rational value) {
    if (value.hasFinitePrecision) {
      return value.toDecimal().toString();
    }
    final String fraction = value.toString();
    return fraction.contains('/') ? '($fraction)' : fraction;
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
}
