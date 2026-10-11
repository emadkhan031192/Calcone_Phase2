import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/calc_key.dart';
import '../calculator_controller.dart';

/// The keypad: 4 columns, 10dp gaps, 72dp tall keys.
/// Row 1: AC, Delete (long-press clears all), %, ÷.
/// Rows 2–4: digits + × − +. Row 5: ( ), 0, ., = (bottom-right).
class Keypad extends ConsumerWidget {
  const Keypad({super.key, this.keyHeight});

  /// Overrides the key height (used for landscape).
  final double? keyHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(stringsProvider);
    final CalculatorController controller = ref.read(
      calculatorControllerProvider.notifier,
    );

    Widget key({
      String? label,
      IconData? icon,
      KeyKind kind = KeyKind.number,
      String? semanticLabel,
      required VoidCallback onTap,
      VoidCallback? onLongPress,
    }) =>
        Expanded(
          child: CalcKey(
            height: keyHeight,
            label: label,
            icon: icon,
            kind: kind,
            semanticLabel: semanticLabel,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        );

    Widget numberKey(String digit) => key(
          label: digit,
          onTap: () => controller.inputDigit(digit),
        );

    Widget operatorKey(String glyph, String internalOp) => key(
          label: glyph,
          kind: KeyKind.op,
          onTap: () => controller.inputOperator(internalOp),
        );

    const Widget gap = SizedBox(width: CalcDims.keyGap);

    List<Widget> row(List<Widget> keys) => <Widget>[
          for (int i = 0; i < keys.length; i++) ...<Widget>[
            if (i > 0) gap,
            keys[i],
          ],
        ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: row(<Widget>[
              key(
                label: 'AC',
                kind: KeyKind.clear,
                semanticLabel: s.allClear,
                onTap: controller.clearAll,
              ),
              key(
                icon: Icons.backspace_outlined,
                kind: KeyKind.clear,
                semanticLabel: s.deleteHint,
                onTap: controller.backspace,
                onLongPress: controller.clearAll,
              ),
              key(
                label: '%',
                kind: KeyKind.function,
                semanticLabel: s.percent,
                onTap: controller.inputPercent,
              ),
              operatorKey(AppConstants.glyphDivide, AppConstants.opDivide),
            ]),
          ),
          const SizedBox(height: CalcDims.keyGap),
          Row(
            children: row(<Widget>[
              numberKey('7'),
              numberKey('8'),
              numberKey('9'),
              operatorKey(AppConstants.glyphMultiply, AppConstants.opMultiply),
            ]),
          ),
          const SizedBox(height: CalcDims.keyGap),
          Row(
            children: row(<Widget>[
              numberKey('4'),
              numberKey('5'),
              numberKey('6'),
              operatorKey(AppConstants.glyphSubtract, AppConstants.opSubtract),
            ]),
          ),
          const SizedBox(height: CalcDims.keyGap),
          Row(
            children: row(<Widget>[
              numberKey('1'),
              numberKey('2'),
              numberKey('3'),
              operatorKey(AppConstants.glyphAdd, AppConstants.opAdd),
            ]),
          ),
          const SizedBox(height: CalcDims.keyGap),
          Row(
            children: row(<Widget>[
              key(
                label: '()',
                kind: KeyKind.function,
                semanticLabel: s.parenthesis,
                onTap: () => controller.inputSmartParen(),
              ),
              numberKey('0'),
              key(
                label: AppConstants.glyphDecimal,
                semanticLabel: s.decimalPoint,
                onTap: controller.inputDecimalPoint,
              ),
              key(
                label: AppConstants.glyphEquals,
                kind: KeyKind.equals,
                semanticLabel: s.equalsHint,
                onTap: controller.evaluate,
                onLongPress: controller.repeatLastOperation,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
