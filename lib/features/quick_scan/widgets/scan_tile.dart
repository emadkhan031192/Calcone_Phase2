import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../engines/decomposition/expression_decomposer.dart';

/// One Tape entry chip: shows its number once (no duplicated labels),
/// with the operator sign (+/−) when [showOperator] is set so added and
/// subtracted terms are distinguishable. Groups cycle
/// blue → green → yellow → red. 64dp tall, 20dp radius, full 48dp+
/// touch target.
class ScanTile extends ConsumerWidget {
  const ScanTile({
    super.key,
    required this.term,
    required this.groupIndex,
    required this.palette,
    required this.selected,
    required this.showOperator,
    required this.onTap,
    required this.onLongPressStart,
  });

  final ExpressionTerm term;
  final int groupIndex;
  final CalcPalette palette;
  final bool selected;

  /// Whether to prefix the chip with its +/− sign.
  final bool showOperator;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details) onLongPressStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(stringsProvider);
    final AppSettings settings = ref.watch(settingsProvider);

    // Each number appears exactly once — strip the leading "+" the
    // source carries, then re-add the operator sign when requested.
    String text = term.source.replaceFirst(RegExp(r'^\+'), '');
    if (showOperator && term.sign.isNotEmpty) {
      text = '${term.sign == '-' ? '−' : term.sign}$text';
    }

    return Semantics(
      button: true,
      label: s.entry(NumberFormatter.format(term.value)),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        child: Container(
          height: CalcDims.chipHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? palette.chipGroupColor(groupIndex).withAlpha(64)
                : palette.chipGroupColor(groupIndex),
            borderRadius: BorderRadius.circular(CalcDims.chipRadius),
            border: selected
                ? Border.all(
                    color: palette.chipGroupColor(groupIndex), width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: rs(settings, CalcDims.chipFontSize),
                fontWeight: chipWeight(settings),
                color: Colors.white,
                fontFeatures: const <FontFeature>[
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
