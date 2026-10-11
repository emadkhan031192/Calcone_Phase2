import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rational/rational.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../engines/decomposition/expression_decomposer.dart';

/// One Tape entry as a ledger row: entry number, the signed value, and
/// the running balance — like a shop khata. Tap selects, long-press
/// opens the edit menu. Minimum 48dp touch height.
class LedgerRow extends ConsumerWidget {
  const LedgerRow({
    super.key,
    required this.term,
    required this.index,
    required this.groupIndex,
    required this.runningTotal,
    required this.palette,
    required this.selected,
    required this.showOperator,
    required this.onTap,
    required this.onLongPressStart,
  });

  final ExpressionTerm term;

  /// Zero-based index across all terms (for the entry number).
  final int index;
  final int groupIndex;

  /// Cumulative total up to and including this entry.
  final Rational runningTotal;
  final CalcPalette palette;
  final bool selected;

  /// Whether to prefix the value with its +/− sign.
  final bool showOperator;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details) onLongPressStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings s = ref.watch(stringsProvider);
    final AppSettings settings = ref.watch(settingsProvider);

    // Each number appears exactly once — strip the leading "+" the
    // source carries, then re-add the operator sign when requested.
    String value = term.source.replaceFirst(RegExp(r'^\+'), '');
    if (showOperator && term.sign.isNotEmpty) {
      value = '${term.sign == '-' ? '−' : term.sign}$value';
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? palette.groupBg(groupIndex).withAlpha(70)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(
                    color: palette.groupSubtotal(groupIndex), width: 1.5)
                : null,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 30,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.muted,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: rs(settings, 22),
                    fontWeight: chipWeight(settings),
                    color: palette.groupSubtotal(groupIndex),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '= ${NumberFormatter.format(runningTotal)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: rs(settings, 15),
                  fontWeight: FontWeight.w500,
                  color: palette.muted,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
