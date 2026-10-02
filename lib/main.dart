import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/basic/basic_calculator_screen.dart';

void main() {
  runApp(const ProviderScope(child: CalcOneApp()));
}

class CalcOneApp extends StatelessWidget {
  const CalcOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const BasicCalculatorScreen(),
    );
  }
}
