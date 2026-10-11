import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../calculator_controller.dart';

/// The centered "TAPE n" pill beneath the result: the affordance that
/// opens the Tape sheet (tap or swipe up).
class PeekHandle extends ConsumerWidget {
  const PeekHandle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppStrings strings = ref.watch(stringsProvider);
    // Rebuilds with the calculator state; the count itself is derived.
    ref.watch(calculatorControllerProvider);
    final int count = ref
            .read(calculatorControllerProvider.notifier)
            .quickScanTerms
            ?.length ??
        0;

    return Semantics(
      button: true,
      label: count == 0 ? strings.openTape : strings.openTapeCount(count),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            minHeight: CalcDims.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: p.tapePillBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                count == 0 ? strings.tape : '${strings.tape} $count',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: p.tapePillText,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: p.tapePillText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
