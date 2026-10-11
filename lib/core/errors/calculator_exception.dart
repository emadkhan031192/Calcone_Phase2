import '../l10n/app_strings.dart';

/// All calculator-related failures surface as a [CalculatorException].
/// The UI layer must never show a raw stack trace or a Dart error string
/// to the user (see spec §31).
///
/// The exception carries a [messageKey]; UI code renders it via
/// [localized] so errors follow the app language. [message] keeps the
/// English text for tests and non-UI use.
class CalculatorException implements Exception {
  const CalculatorException(this.messageKey);

  final String messageKey;

  static const Map<String, String> _english = {
    'divisionByZero': 'Cannot divide by zero.',
    'malformedExpression':
        'That expression isn\'t valid. Check your operators and try again.',
    'emptyInput': 'Enter a number to calculate.',
    'unmatchedParentheses':
        'Check your parentheses — one of them isn\'t closed.',
    'overflow': 'That number is too large to display.',
    'unsupportedOperation': 'That operation isn\'t supported yet.',
    'invalidAngleValue': 'That value is out of range for this function.',
  };

  String get message => _english[messageKey] ?? messageKey;

  String localized(AppStrings strings) => strings.error(messageKey);

  static const CalculatorException divisionByZero =
      CalculatorException('divisionByZero');

  static const CalculatorException malformedExpression =
      CalculatorException('malformedExpression');

  static const CalculatorException emptyInput =
      CalculatorException('emptyInput');

  static const CalculatorException unmatchedParentheses =
      CalculatorException('unmatchedParentheses');

  static const CalculatorException overflow = CalculatorException('overflow');

  static const CalculatorException unsupportedOperation =
      CalculatorException('unsupportedOperation');

  static const CalculatorException invalidAngleValue =
      CalculatorException('invalidAngleValue');

  @override
  String toString() => message;
}
