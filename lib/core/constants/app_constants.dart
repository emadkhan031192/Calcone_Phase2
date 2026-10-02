/// Static, non-localizable constants shared across the app.
///
/// Anything that is user-facing copy and might eventually need translation
/// should still live here as a single source of truth for Phase 1; a real
/// localization pipeline (ARB files) is a later-phase concern.
abstract final class AppConstants {
  static const String appName = 'CalcOne';
  static const String appTagline = 'Simple outside. Genius inside.';

  // Operator glyphs shown on the keypad (kept distinct from the ASCII
  // operators the engine parses internally).
  static const String glyphAdd = '+';
  static const String glyphSubtract = '−';
  static const String glyphMultiply = '×';
  static const String glyphDivide = '÷';
  static const String glyphPercent = '%';
  static const String glyphEquals = '=';
  static const String glyphDecimal = '.';
  static const String glyphOpenParen = '(';
  static const String glyphCloseParen = ')';

  // Internal parser operators (ASCII, unambiguous).
  static const String opAdd = '+';
  static const String opSubtract = '-';
  static const String opMultiply = '*';
  static const String opDivide = '/';
  static const String opPercent = '%';

  static const int maxExpressionLength = 120;
  static const int maxDisplayDecimalPlaces = 10;

  // Spacing scale (dp) — generous, minimal-border design per spec §28.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Animation timings — fast and purposeful (spec §38).
  static const Duration animFast = Duration(milliseconds: 120);
  static const Duration animMedium = Duration(milliseconds: 220);
  static const Duration animSlow = Duration(milliseconds: 320);
}
