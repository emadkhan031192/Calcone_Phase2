import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/basic/basic_calculator_screen.dart';

void main() {
  runApp(const ProviderScope(child: CalcOneApp()));
}

class CalcOneApp extends ConsumerWidget {
  const CalcOneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);

    // Layout always stays LTR (calculator convention); only the strings
    // follow the language.
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const BasicCalculatorScreen(),
    );
  }
}
