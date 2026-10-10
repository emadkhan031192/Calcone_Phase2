import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import '../../core/utils/number_formatter.dart';
import '../../engines/calculator/calculator_engine.dart';
import '../../engines/decomposition/expression_decomposer.dart';
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

  /// Sum of every tape entry's exact result.
  Rational get tapeTotal => _engine.tape.fold<Rational>(
        Rational.zero,
        (Rational sum, CalculationEntry e) => sum + e.result,
      );

  /// The expression Quick Scan operates on: the last evaluated
  /// expression when the displayed result came from it, otherwise the
  /// in-progress expression.
  String get _quickScanExpression => _engine.justEvaluated
      ? _engine.lastEvaluatedExpression
      : _engine.rawExpression;

  /// The active calculation split into editable terms (spec §8–§9), or
  /// null when there is nothing to scan.
  List<ExpressionTerm>? get quickScanTerms {
    final String expr = _quickScanExpression;
    if (expr.isEmpty) return null;
    return ExpressionDecomposer.decompose(expr);
  }

  /// Exact total of the active terms (Quick Scan total, spec §8).
  Rational? get quickScanTotal {
    final List<ExpressionTerm>? terms = quickScanTerms;
    if (terms == null) return null;
    return terms.fold<Rational>(
      Rational.zero,
      (Rational sum, ExpressionTerm t) => sum + t.value,
    );
  }

  /// Replaces one Quick Scan term and recalculates (spec §9). An empty
  /// [newText] deletes the term. Throws [CalculatorException] when the
  /// rebuilt expression is invalid — the UI shows the message and keeps
  /// the old term.
  void editQuickScanTerm(int index, String newText) {
    if (newText.trim().isEmpty) {
      deleteQuickScanTerm(index);
      return;
    }
    _mutateTerms('Edit undone', (List<ExpressionTerm> terms) {
      if (index < 0 || index >= terms.length) return _joinTerms(terms);
      return _rebuildTerm(terms, index, newText);
    });
  }

  /// Deletes one Quick Scan term and recalculates (spec §9).
  void deleteQuickScanTerm(int index) {
    _mutateTerms('Entry deleted', (List<ExpressionTerm> terms) {
      if (index < 0 || index >= terms.length) return _joinTerms(terms);
      final List<ExpressionTerm> kept = <ExpressionTerm>[
        for (int i = 0; i < terms.length; i++)
          if (i != index) terms[i],
      ];
      return _joinTerms(kept);
    });
  }

  /// Saves one Quick Scan term's value (spec §9, §27).
  Future<void> saveQuickScanTerm(int index) {
    final List<ExpressionTerm>? terms = quickScanTerms;
    if (terms == null || index < 0 || index >= terms.length) {
      return Future<void>.value();
    }
    return _sessions.saveNumber(NumberFormatter.format(terms[index].value));
  }

  /// Applies [transform] to the active terms, recalculates, and makes the
  /// change undoable. Evaluated calculations are re-evaluated in place
  /// (the tape entry is replaced, not duplicated); in-progress input is
  /// just updated with a live preview.
  void _mutateTerms(
    String undoLabel,
    String Function(List<ExpressionTerm>) transform,
  ) {
    final List<ExpressionTerm>? terms = quickScanTerms;
    final String oldExpr = _quickScanExpression;
    if (terms == null || oldExpr.isEmpty) return;
    final bool wasEvaluated = _engine.justEvaluated;
    final String rebuilt = transform(terms);
    _pushUndo(undoLabel, () {
      if (wasEvaluated) {
        _syncEvaluated(_engine.reevaluateLast(oldExpr));
      } else {
        _engine.restoreExpression(oldExpr);
        _syncLivePreview();
      }
    });
    if (rebuilt.trim().isEmpty) {
      _engine.restoreExpression('');
      _syncLivePreview();
      _schedulePersist();
      return;
    }
    if (wasEvaluated) {
      _syncEvaluated(_engine.reevaluateLast(rebuilt));
    } else {
      _engine.restoreExpression(rebuilt);
      _syncLivePreview();
    }
    _schedulePersist();
  }

  String _joinTerms(List<ExpressionTerm> terms) {
    String joined = terms.map((ExpressionTerm t) => t.source).join();
    if (joined.startsWith('+')) joined = joined.substring(1);
    return joined;
  }

  String _rebuildTerm(
    List<ExpressionTerm> terms,
    int index,
    String newText,
  ) {
    final String t = newText.trim();
    String newSign;
    String newBody;
    if (t.startsWith('+') || t.startsWith('-')) {
      newSign = t[0];
      newBody = t.substring(1).trim();
    } else {
      newSign = terms[index].sign;
      newBody = t;
    }
    final List<String> parts = <String>[
      for (int i = 0; i < terms.length; i++)
        i == index ? '$newSign$newBody' : terms[i].source,
    ];
    String joined = parts.join();
    if (joined.startsWith('+')) joined = joined.substring(1);
    return joined;
  }

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
    state = state.copyWith(
      expression: '',
      resultPreview: '0',
      tape: _engine.tape,
      clearError: true,
      justEvaluated: false,
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
    state = state.copyWith(
      expression: '',
      resultPreview: '0',
      tape: _engine.tape,
      clearError: true,
      justEvaluated: false,
    );
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
    _syncAll(clearUndo: true);
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
    _syncAll(clearUndo: true);
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

  /// Payload for sharing the active calculation (spec §13): one row per
  /// term, then the total.
  SharePayload calculationSharePayload() {
    final List<ExpressionTerm>? terms = quickScanTerms;
    if (terms == null) {
      return const SharePayload(title: 'CALCULATION', rows: <String>[]);
    }
    return SharePayload(
      title: 'CALCULATION',
      rows: <String>[
        for (final ExpressionTerm t in terms) _termShareLine(t),
      ],
      total: 'TOTAL: ${NumberFormatter.format(quickScanTotal!)}',
    );
  }

  /// One share line per term: a bare value on its own, or
  /// "term = value" when the term was itself a calculation.
  String _termShareLine(ExpressionTerm term) {
    final String valueStr = NumberFormatter.format(term.value);
    if (term.source.replaceAll(',', '') == valueStr.replaceAll(',', '')) {
      return valueStr;
    }
    return '${term.source} = $valueStr';
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

  /// Refreshes the UI after an evaluation (or re-evaluation) with the
  /// given formatted result.
  void _syncEvaluated(String result) {
    state = state.copyWith(
      expression: _engine.displayExpression,
      resultPreview: result,
      tape: _engine.tape,
      clearError: true,
      justEvaluated: _engine.justEvaluated,
    );
  }

  void _syncAll({bool clearUndo = false}) {
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
      justEvaluated: _engine.justEvaluated,
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
