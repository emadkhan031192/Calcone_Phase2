import 'package:flutter/material.dart';

/// CalcOne's visual language: calm, premium, mathematical.
///
/// Deliberately restrained — one accent color, generous spacing, minimal
/// borders/shadows, no gradients. See spec §28.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF3B5BFD); // quiet indigo-blue accent

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(scheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      // The big result — the single most important pixel on the screen.
      displayLarge: TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.w300,
        letterSpacing: -1,
        color: scheme.onSurface,
        height: 1.05,
      ),
      // The smaller expression line shown above the result.
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      // Keypad digits.
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
      ),
    );
  }

  /// Keypad button colors, split by semantic role so features/basic doesn't
  /// need to know about the color scheme's internal naming.
  static Color numberKeyColor(ColorScheme scheme) => scheme.surfaceContainerHigh;
  static Color operatorKeyColor(ColorScheme scheme) => scheme.primaryContainer;
  static Color equalsKeyColor(ColorScheme scheme) => scheme.primary;
  static Color utilityKeyColor(ColorScheme scheme) => scheme.surfaceContainer;
}
