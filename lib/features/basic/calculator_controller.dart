import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/calculator_exception.dart';
import '../../engines/calculator/calculator_engine.dart';
import '../../models/calculation_entry.dart';

/// Immutable snapshot of everything the Basic Calculator screen needs to
/// render. Rebuilt after every user action.
class CalculatorUiState {
  const CalculatorUiState({
    required this.expression,
    required this.resultPreview,
    required this.tape,
    this.errorMessage,
    this.justEvaluated = false,
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

  CalculatorUiState copyWith({
    String? expression,
    String? resultPreview,
    List<CalculationEntry>? tape,
    String? errorMessage,
    bool clearError = false,
    bool? justEvaluated,
  }) {
    return CalculatorUiState(
      expression: expression ?? this.expression,
      resultPreview: resultPreview ?? this.resultPreview,
      tape: tape ?? this.tape,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      justEvaluated: justEvaluated ?? this.justEvaluated,
    );
  }
}

/// Bridges the UI-agnostic [CalculatorEngine] to Flutter's widget tree.
/// Every public method here corresponds to exactly one user gesture.
class CalculatorController extends StateNotifier<CalculatorUiState> {
  CalculatorController() : _engine = CalculatorEngine(), super(CalculatorUiState.initial());

  final CalculatorEngine _engine;

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

  void inputOpenParen() {
    _engine.inputOpenParen();
    _syncLivePreview();
  }

  void inputCloseParen() {
    _engine.inputCloseParen();
    _syncLivePreview();
  }

  void backspace() {
    _engine.backspace();
    _syncLivePreview();
  }

  void clearCurrent() {
    _engine.clearCurrent();
    state = CalculatorUiState(
      expression: '',
      resultPreview: '0',
      tape: _engine.tape,
    );
  }

  void clearAll() {
    _engine.clearAll();
    state = CalculatorUiState.initial();
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
    } on CalculatorException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void repeatLastOperation() {
    final String? result = _engine.repeatLastOperation();
    if (result == null) return;
    state = state.copyWith(
      expression: _engine.displayExpression,
      resultPreview: result,
      tape: _engine.tape,
      clearError: true,
      justEvaluated: true,
    );
  }

  /// Live-updates the expression line and a best-effort preview of the
  /// result as the user types, without committing to the tape. Evaluation
  /// errors while mid-typing (e.g. a trailing operator) are expected and
  /// silently ignored here — they only matter when the user presses "=".
  void _syncLivePreview() {
    state = state.copyWith(
      expression: _engine.displayExpression,
      clearError: true,
      justEvaluated: false,
    );
  }
}

final StateNotifierProvider<CalculatorController, CalculatorUiState> calculatorControllerProvider =
    StateNotifierProvider<CalculatorController, CalculatorUiState>(
  (ref) => CalculatorController(),
);
