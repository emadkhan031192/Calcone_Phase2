import 'package:flutter/material.dart';

/// Sizes shared by keys, chips and sheets. Everything layout-related
/// reads from here — no magic numbers in widgets.
class CalcDims {
  static const double keyHeight = 72;
  static const double keyRadius = 28;
  static const double keyGap = 10;
  static const double chipHeight = 56;
  static const double chipRadius = 20;
  static const double sheetRadius = 32;
  static const double minTouchTarget = 48;

  /// Result on the main screen.
  static const double resultFontSize = 104;

  /// Total on the Tape sheet footer card.
  static const double tapeTotalFontSize = 44;

  /// Result on the share card.
  static const double shareResultFontSize = 88;
}

/// Extra colors that [ColorScheme] has no slot for: keys, tape groups,
/// the equals gradient, top-bar buttons and the share card.
///
/// All widget colors come from here (or the [ColorScheme]) — no hardcoded
/// hex in widgets.
class CalcPalette extends ThemeExtension<CalcPalette> {
  const CalcPalette({
    required this.muted,
    required this.topBarButtonBg,
    required this.topBarButtonIcon,
    required this.keyNumber,
    required this.keyNumberText,
    required this.keyFunction,
    required this.keyFunctionText,
    required this.keyOp,
    required this.keyOpText,
    required this.keyClear,
    required this.keyClearText,
    required this.equalsStart,
    required this.equalsEnd,
    required this.equalsText,
    required this.tapePillBg,
    required this.tapePillText,
    required this.tapeChipBg,
    required this.tapeChipText,
    required this.tapeSubtotal,
    required this.cardBorder,
    required this.cardGlowBlue,
    required this.cardGlowGreen,
    required this.cardGlowYellow,
    required this.cardGlowRed,
  });

  final Color muted;
  final Color topBarButtonBg;
  final Color topBarButtonIcon;

  final Color keyNumber;
  final Color keyNumberText;
  final Color keyFunction;
  final Color keyFunctionText;
  final Color keyOp;
  final Color keyOpText;
  final Color keyClear;
  final Color keyClearText;
  final Color equalsStart;
  final Color equalsEnd;
  final Color equalsText;

  final Color tapePillBg;
  final Color tapePillText;

  /// Tape groups cycle through these 4 colors: blue, green, yellow, red.
  final List<Color> tapeChipBg;
  final List<Color> tapeChipText;
  final List<Color> tapeSubtotal;

  /// Share card (always rendered light so shared images look the same
  /// on every device).
  final Color cardBorder;
  final Color cardGlowBlue;
  final Color cardGlowGreen;
  final Color cardGlowYellow;
  final Color cardGlowRed;

  Color groupBg(int i) => tapeChipBg[i % tapeChipBg.length];
  Color groupText(int i) => tapeChipText[i % tapeChipText.length];
  Color groupSubtotal(int i) => tapeSubtotal[i % tapeSubtotal.length];

  static const light = CalcPalette(
    muted: Color(0xFF5A6272),
    topBarButtonBg: Color(0xFFE9EDF6),
    topBarButtonIcon: Color(0xFF44505F),
    keyNumber: Color(0xFFE9EDF6),
    keyNumberText: Color(0xFF191C20),
    keyFunction: Color(0xFFDCE3F0),
    keyFunctionText: Color(0xFF2F3B52),
    keyOp: Color(0xFFD3E3FD),
    keyOpText: Color(0xFF0B57D0),
    keyClear: Color(0xFFFFDAD6),
    keyClearText: Color(0xFFBA1A1A),
    equalsStart: Color(0xFF3B7DF8),
    equalsEnd: Color(0xFF0B57D0),
    equalsText: Color(0xFFFFFFFF),
    tapePillBg: Color(0xFFD3E3FD),
    tapePillText: Color(0xFF0B57D0),
    tapeChipBg: <Color>[
      Color(0xFFD3E3FD),
      Color(0xFFC4EED0),
      Color(0xFFFFE8A3),
      Color(0xFFFFD9D4),
    ],
    tapeChipText: <Color>[
      Color(0xFF0A3A8F),
      Color(0xFF0A5224),
      Color(0xFF5E4000),
      Color(0xFF8C1D18),
    ],
    tapeSubtotal: <Color>[
      Color(0xFF0B57D0),
      Color(0xFF0D652D),
      Color(0xFF8A5A00),
      Color(0xFFB3261E),
    ],
    cardBorder: Color(0xFFD3E3FD),
    cardGlowBlue: Color(0xFF3B7DF8),
    cardGlowGreen: Color(0xFF2FB36D),
    cardGlowYellow: Color(0xFFF6B93B),
    cardGlowRed: Color(0xFFEF5B5B),
  );

  static const dark = CalcPalette(
    muted: Color(0xFFA9B1C3),
    topBarButtonBg: Color(0xFF2A2D36),
    topBarButtonIcon: Color(0xFFA9B1C3),
    keyNumber: Color(0xFF2A2D36),
    keyNumberText: Color(0xFFE3E2E9),
    keyFunction: Color(0xFF3A4152),
    keyFunctionText: Color(0xFFC9D6F0),
    keyOp: Color(0xFF1C3F7A),
    keyOpText: Color(0xFFD3E3FD),
    keyClear: Color(0xFF601410),
    keyClearText: Color(0xFFFFB4AB),
    equalsStart: Color(0xFFB9D2FC),
    equalsEnd: Color(0xFF8AB4F8),
    equalsText: Color(0xFF062E6F),
    tapePillBg: Color(0xFF1C3F7A),
    tapePillText: Color(0xFFD3E3FD),
    tapeChipBg: <Color>[
      Color(0xFF1C3F7A),
      Color(0xFF1E4D2E),
      Color(0xFF5A4300),
      Color(0xFF601410),
    ],
    tapeChipText: <Color>[
      Color(0xFFD3E3FD),
      Color(0xFFC4EED0),
      Color(0xFFFFE8A3),
      Color(0xFFFFD9D4),
    ],
    tapeSubtotal: <Color>[
      Color(0xFF8AB4F8),
      Color(0xFF6DD58C),
      Color(0xFFF8C65A),
      Color(0xFFFFB4AB),
    ],
    // The share card is always light, so these match [light].
    cardBorder: Color(0xFFD3E3FD),
    cardGlowBlue: Color(0xFF3B7DF8),
    cardGlowGreen: Color(0xFF2FB36D),
    cardGlowYellow: Color(0xFFF6B93B),
    cardGlowRed: Color(0xFFEF5B5B),
  );

  @override
  CalcPalette copyWith() => this;

  @override
  CalcPalette lerp(ThemeExtension<CalcPalette>? other, double t) =>
      other is CalcPalette ? (t < 0.5 ? this : other) : this;
}

/// Calcone's Pixel-style Material You theme.
///
/// Outfit everywhere (bundled in assets/fonts, so the app stays fully
/// offline), tabular numerals, weight 500 for numbers.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final CalcPalette palette = isDark ? CalcPalette.dark : CalcPalette.light;

    final ColorScheme scheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF8AB4F8),
            onPrimary: Color(0xFF062E6F),
            primaryContainer: Color(0xFF1C3F7A),
            onPrimaryContainer: Color(0xFFD3E3FD),
            surface: Color(0xFF111318),
            onSurface: Color(0xFFE3E2E9),
            surfaceContainerHighest: Color(0xFF2A2D36),
            error: Color(0xFFFFB4AB),
            errorContainer: Color(0xFF601410),
          )
        : const ColorScheme.light(
            primary: Color(0xFF0B57D0),
            onPrimary: Color(0xFFFFFFFF),
            primaryContainer: Color(0xFFD3E3FD),
            onPrimaryContainer: Color(0xFF0A3A8F),
            surface: Color(0xFFF8F9FF),
            onSurface: Color(0xFF191C20),
            surfaceContainerHighest: Color(0xFFE9EDF6),
            error: Color(0xFFBA1A1A),
            errorContainer: Color(0xFFFFDAD6),
          );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      // Bundled Outfit (assets/fonts/Outfit.ttf) — no network needed.
      fontFamily: 'Outfit',
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _textTheme(scheme),
      extensions: <ThemeExtension<dynamic>>[palette],
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          minimumSize:
              const Size(CalcDims.minTouchTarget, CalcDims.minTouchTarget),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.4),
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF1B1E26) : Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(CalcDims.sheetRadius),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextTheme _textTheme(ColorScheme scheme) {
    // Every style inherits Outfit from [fontFamily]; numbers request
    // tabular figures so columns of digits stay aligned.
    return TextTheme(
      // The big result — the single most important pixel on the screen.
      displayLarge: TextStyle(
        fontSize: CalcDims.resultFontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: -3,
        color: scheme.onSurface,
        height: 1.05,
        fontFeatures: _tabular,
      ),
      // The smaller expression line shown above the result.
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
        fontFeatures: _tabular,
      ),
      // Keypad digits.
      headlineSmall: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
        fontFeatures: _tabular,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        color: scheme.onSurfaceVariant.withOpacity(0.8),
      ),
    );
  }
}
