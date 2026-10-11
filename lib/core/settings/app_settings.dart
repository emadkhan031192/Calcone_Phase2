import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

/// Everything the user can tune: theme, language, font size/weight,
/// haptics, and Tape chip operators. Persisted on device.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    this.fontSize = 0,
    this.fontWeight = 2,
    this.haptics = true,
    this.showChipOperators = true,
  });

  final ThemeMode themeMode;

  /// 'en' or 'ur'.
  final String language;

  /// 0 = small, 1 = medium, 2 = large.
  final int fontSize;

  /// 0 = regular, 1 = medium, 2 = bold. Defaults to bold per the mockup.
  final int fontWeight;
  final bool haptics;
  final bool showChipOperators;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? language,
    int? fontSize,
    int? fontWeight,
    bool? haptics,
    bool? showChipOperators,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      haptics: haptics ?? this.haptics,
      showChipOperators: showChipOperators ?? this.showChipOperators,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (Ref ref) => SettingsNotifier(),
);

/// Localized strings for the current language.
final stringsProvider = Provider<AppStrings>(
  (Ref ref) => AppStrings(ref.watch(settingsProvider).language),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  static const String _kTheme = 'calcone_theme_mode';
  static const String _kLang = 'calcone_language';
  static const String _kFontSize = 'calcone_font_size';
  static const String _kFontWeight = 'calcone_font_weight';
  static const String _kHaptics = 'calcone_haptics';
  static const String _kChipOps = 'calcone_chip_operators';

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? themeRaw = prefs.getString(_kTheme);
    state = AppSettings(
      themeMode: themeRaw == null
          ? ThemeMode.system
          : ThemeMode.values.firstWhere(
              (ThemeMode m) => m.name == themeRaw,
              orElse: () => ThemeMode.system,
            ),
      language: prefs.getString(_kLang) ?? 'en',
      fontSize: prefs.getInt(_kFontSize) ?? 0,
      fontWeight: prefs.getInt(_kFontWeight) ?? 2,
      haptics: prefs.getBool(_kHaptics) ?? true,
      showChipOperators: prefs.getBool(_kChipOps) ?? true,
    );
  }

  Future<void> _save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme, state.themeMode.name);
    await prefs.setString(_kLang, state.language);
    await prefs.setInt(_kFontSize, state.fontSize);
    await prefs.setInt(_kFontWeight, state.fontWeight);
    await prefs.setBool(_kHaptics, state.haptics);
    await prefs.setBool(_kChipOps, state.showChipOperators);
  }

  void _update(AppSettings next) {
    state = next;
    _save();
  }

  /// Cycles system → light → dark → system.
  void cycleTheme() => _update(state.copyWith(
        themeMode: switch (state.themeMode) {
          ThemeMode.system => ThemeMode.light,
          ThemeMode.light => ThemeMode.dark,
          ThemeMode.dark => ThemeMode.system,
        },
      ));

  void setTheme(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void toggleLanguage() => _update(state.copyWith(
        language: state.language == 'en' ? 'ur' : 'en',
      ));

  void setLanguage(String code) => _update(state.copyWith(language: code));
  void setFontSize(int i) => _update(state.copyWith(fontSize: i));
  void setFontWeight(int i) => _update(state.copyWith(fontWeight: i));
  void setHaptics(bool v) => _update(state.copyWith(haptics: v));
  void setShowChipOperators(bool v) =>
      _update(state.copyWith(showChipOperators: v));

  String get themeLabel => switch (state.themeMode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };
}

/// Font-size multiplier from the setting: small 0.85, medium 1.0,
/// large 1.18.
double rs(AppSettings s, double base) =>
    base * const <double>[0.85, 1.0, 1.18][s.fontSize.clamp(0, 2)];

/// Absolute weight tiers. Bold is the default (matches the mockup).
FontWeight _tier(int weight, FontWeight regular, FontWeight medium) {
  return switch (weight.clamp(0, 2)) {
    0 => regular,
    1 => medium,
    _ => FontWeight.w700,
  };
}

FontWeight resultWeight(AppSettings s) =>
    _tier(s.fontWeight, FontWeight.w500, FontWeight.w600);
FontWeight keyWeight(AppSettings s) =>
    _tier(s.fontWeight, FontWeight.w500, FontWeight.w600);
FontWeight exprWeight(AppSettings s) =>
    _tier(s.fontWeight, FontWeight.w400, FontWeight.w400);
FontWeight chipWeight(AppSettings s) =>
    _tier(s.fontWeight, FontWeight.w500, FontWeight.w600);
