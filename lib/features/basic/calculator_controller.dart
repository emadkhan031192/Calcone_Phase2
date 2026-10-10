import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import '../../core/utils/number_formatter.dart';
import '../../engines/calculator/calculator_engine.dart';
import '../../engines/expression/expression_evaluator.dart';
import '../../engines/steps/step_explainer.dart';
import '../../models/calculation_entry.dart';
import '../../services/session_service.dart';
import '../sharing/share_payload.dart';

/// A destructive action the user can take back (spec §18). Shown as a
/// small snackbar with an Undo button — no permanent on-screen chrome.
class UndoRequest {
  const UndoRequest(this.label);

  final String label;
}

class _UndoEntry {
  _UndoEntry(this.label, this.restore);

  final String label;
  final void Function() restore;
}

/// Immutable snapshot of everything the Basic Calculator screen needs to
/// render. Rebuilt after every user action.
class CalculatorUiState {
  const CalculatorUiState({
    required this.expression,
    required this.resultPreview,
    required this.tape,
    this.errorMessage,
    this.justEvaluated = false,
    this.undoRequest,
  });

  factory CalculatorUiState.initial() => const CalculatorUiState(
        expression: '',
        resultPreview: '0',
        tape: <CalculationEntry>[],
      );

  final String expression;
  final String resultPreview;
  final List<CalculationEntry> tape;
  final String? errorMessage;
  final bool justEvaluated;
  final UndoRequest? undoRequest;

  CalculatorUiState copyWith({
    String? expression,
    String? resultPreview,
    List<CalculationEntry>? tape,
    String? errorMessage,
    bool clearError = false,
    bool? justEvaluated,
    UndoRequest? undoRequest,
    bool clearUndo = false,
  }) {
    return CalculatorUiState(
      expression: expression ?? this.expression,
      resultPreview: resultPreview ?? this.resultPreview,
      tape: tape ?? this.tape,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      justEvaluated: justEvaluated ?? this.justEvaluated,
      undoRequest: clearUndo ? null : (undoRequest ?? this.undoRequest),
    );
  }
}

/// Bridges the UI-agnostic [CalculatorEngine] to Flutter's widget tree.
/// Every public method here corresponds to exactly one user gesture.
class CalculatorController extends StateNotifier<CalculatorUiState> {
  CalculatorController()
      : _engine = CalculatorEngine(),
        super(CalculatorUiState.initial());

  final CalculatorEngine _engine;
  final SessionService _sessions = SessionService();
  final List<_UndoEntry> _undoStack = <_UndoEntry>[];
  Timer? _persistTimer;

  /// Sum of every tape entry's exact result (Quick Scan total, spec §8).
  Rational get tapeTotal => _engine.tape.fold<Rational>(
        Rational.zero,
        (Rational sum, CalculationEntry e) => sum + e.result,
      );

  /// Whether the display is currently showing an error message.
  bool get hasError => state.errorMessage != null;

  /// The current display expression (for sharing).
  String get currentExpression => state.expression;

  /// Whether the last action was an evaluation.
  bool get justEvaluated => state.justEvaluated;

  void inputDigit(String digit) {
    _engine.inputDigit(digit);
    _syncLivePreview();
  }

  void inputDecimalPoint() {
    _engine.inputDecimalPoint();
    _syncLivePreview();
  }

  void inputOperator(String op) {
    _engine.inputOperator(op);
    _syncLivePreview();
  }

  void inputPercent() {
    _engine.inputPercent();
    _syncLivePreview();
  }

  /// Smart parenthesis key: one tap inserts "(" or ")" depending on
  /// context — no hidden long-press needed to close a parenthesis.
  void inputSmartParen() {
    _engine.inputSmartParen();
    _syncLivePreview();
  }

  void backspace() {
    _engine.backspace();
    _syncLivePreview();
  }

  void clearCurrent() {
    final String expr = _engine.rawExpression;
    _engine.clearCurrent();
    state = CalculatorUiState(
      expression: '',
      resultPreview: '0',
      tape: _engine.tape,
    );
    if (expr.isNotEmpty) {
      _pushUndo('Input cleared', () => _engine.restoreExpression(expr));
    }
    _schedulePersist();
  }

  void clearAll() {
    final String expr = _engine.rawExpression;
    final List<CalculationEntry> oldTape = List.of(_engine.tape);
    _engine.clearAll();
    state = CalculatorUiState.initial();
    if (expr.isNotEmpty || oldTape.isNotEmpty) {
      _pushUndo('Cleared', () => _engine.restoreSession(oldTape, expr));
    }
    _schedulePersist();
  }

  void evaluate() {
    try {
      final String result = _engine.evaluate();
      state = state.copyWith(
        expression: _engine.displayExpression,
        resultPreview: result,
        tape: _engine.tape,
        clearError: true,
        justEvaluated: true,
      );
      _schedulePersist();
    } on CalculatorException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void repeatLastOperation() {
    final String? result = _engine.repeatLastOperation();
    if (result == null) {
      // Nothing valid to repeat (e.g. mid-typing): long-press behaves
      // like a normal equals press instead of doing nothing surprising.
      evaluate();
      return;
    }
    state = state.copyWith(
      expression: _engine.displayExpression,
      resultPreview: result,
      tape: _engine.tape,
      clearError: true,
      justEvaluated: true,
    );
    _schedulePersist();
  }

  /// Deletes one tape entry (Quick Scan, spec §9). Undoable.
  void deleteTapeEntry(String id) {
    final int index = _engine.tape.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final CalculationEntry removed = _engine.tape[index];
    _engine.deleteTapeEntry(id);
    _pushUndo('Entry deleted', () => _engine.insertTapeEntry(index, removed));
    _syncTape();
  }

  /// Re-evaluates a tape entry from edited expression text and updates the
  /// total automatically (Quick Scan, spec §9). Throws
  /// [CalculatorException] when the edited text isn't a valid expression —
  /// the UI shows the friendly message and keeps the old entry.
  void editTapeEntry(String id, String newExpression) {
    final int index = _engine.tape.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final CalculationEntry old = _engine.tape[index];
    final String trimmed = newExpression.trim();
    final Rational newValue = const ExpressionEvaluator().evaluate(trimmed);
    _engine.editTapeEntry(id, newValue, trimmed);
    _pushUndo(
      'Edit undone',
      () => _engine.editTapeEntry(id, old.result, old.expression),
    );
    _syncTape();
  }

  /// Clears the whole session tape (Quick Scan action). Undoable.
  void clearTape() {
    if (_engine.tape.isEmpty) return;
    final List<CalculationEntry> oldTape = List.of(_engine.tape);
    final String expr = _engine.rawExpression;
    _engine.clearTape();
    _pushUndo('Tape cleared', () => _engine.restoreSession(oldTape, expr));
    _syncTape();
  }

  /// Undoes the most recent destructive action (spec §18).
  void undo() {
    if (_undoStack.isEmpty) return;
    _undoStack.removeLast().restore();
    _syncAll(clearUndo: true, justEvaluated: false);
    _schedulePersist();
  }

  void dismissUndo() {
    if (state.undoRequest != null) {
      state = state.copyWith(clearUndo: true);
    }
  }

  Future<bool> hasSavedSession() => _sessions.hasSavedSession();

  /// Restores the persisted session after the user accepts the
  /// "Continue previous calculation?" prompt (spec §19).
  Future<void> restoreSavedSession() async {
    final ({List<CalculationEntry> tape, String expression}) loaded =
        await _sessions.loadSession();
    if (loaded.tape.isEmpty && loaded.expression.isEmpty) return;
    _engine.restoreSession(loaded.tape, loaded.expression);
    _undoStack.clear();
    _syncAll(clearUndo: true, justEvaluated: false);
  }

  Future<void> discardSavedSession() => _sessions.clearSession();

  Future<List<String>> loadSavedNumbers() => _sessions.loadSavedNumbers();

  /// Saves the currently displayed result (spec §27).
  Future<void> saveCurrentResult() {
    if (state.errorMessage != null) return Future<void>.value();
    return _sessions.saveNumber(state.resultPreview);
  }

  Future<void> removeSavedNumber(String value) =>
      _sessions.removeSavedNumber(value);

  /// Saves one tape entry's result (Quick Scan long-press menu, spec §9).
  Future<void> saveTapeEntry(String id) {
    final int index = _engine.tape.indexWhere((e) => e.id == id);
    if (index == -1) return Future<void>.value();
    return _sessions
        .saveNumber(NumberFormatter.format(_engine.tape[index].result));
  }

  /// Human-readable steps for the currently shown result (spec §25), or
  /// null when it can't be explained safely — then the UI shows the
  /// result without steps, never invented ones.
  List<String>? explainResult() {
    if (state.errorMessage != null) return null;
    final String expr = _engine.justEvaluated
        ? _engine.lastEvaluatedExpression
        : _engine.rawExpression;
    if (expr.isEmpty) return null;
    return StepExplainer.explain(expr);
  }

  /// Payload for sharing the current result as a card (spec §12).
  SharePayload resultSharePayload() {
    final String expr = _engine.justEvaluated
        ? CalculatorEngine.toDisplayString(_engine.lastEvaluatedExpression)
        : state.expression;
    return SharePayload(
      title: 'CALCONE',
      rows: <String>[expr],
      total: '= ${state.resultPreview}',
    );
  }

  /// Payload for sharing the whole tape (spec §13).
  SharePayload calculationSharePayload() {
    return SharePayload(
      title: 'CALCULATION',
      rows: <String>[
        for (final CalculationEntry e in _engine.tape) _shareLine(e),
      ],
      total: 'TOTAL: ${NumberFormatter.format(tapeTotal)}',
    );
  }

  /// One share line per entry: a bare value on its own, or
  /// "expression = result" when the entry was a real calculation.
  String _shareLine(CalculationEntry e) {
    final String resultStr = NumberFormatter.format(e.result);
    if (e.expression.replaceAll(',', '') == resultStr.replaceAll(',', '')) {
      return resultStr;
    }
    return '${e.displayExpression} = $resultStr';
  }

  void _pushUndo(String label, void Function() restore) {
    _undoStack.add(_UndoEntry(label, restore));
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    state = state.copyWith(undoRequest: UndoRequest(label));
  }

  void _syncTape() {
    state = state.copyWith(
      tape: _engine.tape,
      clearError: true,
    );
    _schedulePersist();
  }

  void _syncAll({bool clearUndo = false, bool? justEvaluated}) {
    final String expr = _engine.rawExpression;
    String preview = state.resultPreview;
    if (expr.isEmpty) {
      preview = '0';
    } else {
      final Rational? live = _engine.previewResult();
      if (live != null) preview = NumberFormatter.format(live);
    }
    state = state.copyWith(
      expression: _engine.displayExpression,
      resultPreview: preview,
      tape: _engine.tape,
      clearError: true,
      justEvaluated: justEvaluated,
      clearUndo: clearUndo,
    );
  }

  /// Live-updates the expression line and a best-effort preview of the
  /// result as the user types, without committing to the tape. Evaluation
  /// errors while mid-typing (e.g. a trailing operator) are expected: the
  /// previous preview is kept until the expression becomes valid again.
  void _syncLivePreview() {
    _syncAll();
    _schedulePersist();
  }

  /// Persists the session (spec §19), debounced so every keystroke
  /// doesn't hit storage (spec §35).
  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), () {
      _sessions.saveSession(_engine.tape, _engine.rawExpression);
    });
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}

final StateNotifierProvider<CalculatorController, CalculatorUiState>
    calculatorControllerProvider =
    StateNotifierProvider<CalculatorController, CalculatorUiState>(
  (ref) => CalculatorController(),
);
