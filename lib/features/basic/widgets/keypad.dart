import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/calc_button.dart';
import '../calculator_controller.dart';

/// The four-row digit grid plus the equals bar — the entirety of what's
/// visible on the home screen (spec §4). A slim utility row (AC / ⌫) sits
/// above it: necessary for the app to actually function, but kept small
/// and muted so it doesn't compete with the grid.
class Keypad extends ConsumerWidget {
  const Keypad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalculatorController controller = ref.read(calculatorControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Color numberColor = AppTheme.numberKeyColor(scheme);
    final Color operatorColor = AppTheme.operatorKeyColor(scheme);
    final Color utilityColor = AppTheme.utilityKeyColor(scheme);
    final Color equalsColor = AppTheme.equalsKeyColor(scheme);

    Widget numberKey(String digit) => CalcButton(
          label: digit,
          backgroundColor: numberColor,
          foregroundColor: scheme.onSurface,
          onTap: () => controller.inputDigit(digit),
        );

    Widget operatorKey(String glyph, String internalOp) => CalcButton(
          label: glyph,
          backgroundColor: operatorColor,
          foregroundColor: scheme.onPrimaryContainer,
          onTap: () => controller.inputOperator(internalOp),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            CalcButton(
              label: 'AC',
              backgroundColor: utilityColor,
              foregroundColor: scheme.error,
              semanticLabel: 'All clear',
              onTap: controller.clearAll,
            ),
            CalcButton(
              label: 'C',
              backgroundColor: utilityColor,
              foregroundColor: scheme.onSurfaceVariant,
              semanticLabel: 'Clear',
              onTap: controller.clearCurrent,
            ),
            CalcButton(
              label: '⌫',
              backgroundColor: utilityColor,
              foregroundColor: scheme.onSurfaceVariant,
              semanticLabel: 'Backspace',
              onTap: controller.backspace,
            ),
            CalcButton(
              label: '( )',
              backgroundColor: utilityColor,
              foregroundColor: scheme.onSurfaceVariant,
              semanticLabel: 'Parenthesis',
              onTap: () => controller.inputOpenParen(),
              onLongPress: () => controller.inputCloseParen(),
            ),
          ],
        ),
        Row(children: <Widget>[
          numberKey('7'),
          numberKey('8'),
          numberKey('9'),
          operatorKey(AppConstants.glyphDivide, AppConstants.opDivide),
        ]),
        Row(children: <Widget>[
          numberKey('4'),
          numberKey('5'),
          numberKey('6'),
          operatorKey(AppConstants.glyphMultiply, AppConstants.opMultiply),
        ]),
        Row(children: <Widget>[
          numberKey('1'),
          numberKey('2'),
          numberKey('3'),
          operatorKey(AppConstants.glyphSubtract, AppConstants.opSubtract),
        ]),
        Row(children: <Widget>[
          numberKey('0'),
          CalcButton(
            label: AppConstants.glyphDecimal,
            backgroundColor: numberColor,
            foregroundColor: scheme.onSurface,
            onTap: controller.inputDecimalPoint,
          ),
          CalcButton(
            label: AppConstants.glyphPercent,
            backgroundColor: numberColor,
            foregroundColor: scheme.onSurface,
            onTap: controller.inputPercent,
          ),
          operatorKey(AppConstants.glyphAdd, AppConstants.opAdd),
        ]),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceXs,
            vertical: AppConstants.spaceXs,
          ),
          child: SizedBox(
            width: double.infinity,
            child: CalcButton(
              label: AppConstants.glyphEquals,
              backgroundColor: equalsColor,
              foregroundColor: scheme.onPrimary,
              semanticLabel: 'Equals',
              onTap: controller.evaluate,
              onLongPress: controller.repeatLastOperation,
            ),
          ),
        ),
      ],
    );
  }
}
