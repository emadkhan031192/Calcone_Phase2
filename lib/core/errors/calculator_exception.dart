/// All calculator-related failures surface as a [CalculatorException] with a
/// friendly, user-facing [message]. The UI layer must never show a raw
/// stack trace or a Dart error string to the user (see spec §31).
class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  static const CalculatorException divisionByZero = CalculatorException(
    'Cannot divide by zero.',
  );

  static const CalculatorException malformedExpression = CalculatorException(
    'That expression isn\'t valid. Check your operators and try again.',
  );

  static const CalculatorException emptyInput = CalculatorException(
    'Enter a number to calculate.',
  );

  static const CalculatorException unmatchedParentheses = CalculatorException(
    'Check your parentheses — one of them isn\'t closed.',
  );

  static const CalculatorException overflow = CalculatorException(
    'That number is too large to display.',
  );

  static const CalculatorException unsupportedOperation = CalculatorException(
    'That operation isn\'t supported yet.',
  );

  static const CalculatorException invalidAngleValue = CalculatorException(
    'That value is out of range for this function.',
  );

  @override
  String toString() => message;
}
