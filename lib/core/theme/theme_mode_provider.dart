import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App theme mode: follows the system by default, with a manual override
/// from the top-bar toggle. Persisted on device.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (Ref ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const String _key = 'calcone_theme_mode';

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null) return;
    state = ThemeMode.values.firstWhere(
      (ThemeMode m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  /// Cycles system → light → dark → system.
  Future<void> cycle() async {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.name);
  }

  String get label => switch (state) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}
