import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import 'calculator_controller.dart';
import 'widgets/calculation_display.dart';
import 'widgets/keypad.dart';
import 'widgets/peek_handle.dart';

/// The entire home screen (spec §4): title, display, peek handle, keypad.
/// Nothing else. Scientific mode, converter, finance tools, history — all
/// of it stays reachable through contextual interaction, not permanent
/// chrome on this screen.
class BasicCalculatorScreen extends ConsumerWidget {
  const BasicCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalculatorUiState state = ref.watch(calculatorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  CalculationDisplay(
                    expression: state.expression,
                    result: state.resultPreview,
                    errorMessage: state.errorMessage,
                  ),
                  const PeekHandle(),
                  const SizedBox(height: AppConstants.spaceSm),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppConstants.spaceSm),
              child: Keypad(),
            ),
          ],
        ),
      ),
    );
  }
}
