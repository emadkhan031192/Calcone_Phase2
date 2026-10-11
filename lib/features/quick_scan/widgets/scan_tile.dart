import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../engines/decomposition/expression_decomposer.dart';

/// One term in the Tape grid: the number shown once, centered, in the
/// group's color. 56dp tall, 20dp radius.
class ScanTile extends StatelessWidget {
  const ScanTile({
    super.key,
    required this.term,
    required this.groupIndex,
    required this.palette,
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
  });

  final ExpressionTerm term;
  final int groupIndex;
  final CalcPalette palette;
  final bool selected;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details) onLongPressStart;

  /// The term's source with a redundant leading "+" removed, so each
  /// number appears once ("+45" → "45", "-20" and "3*4" stay as-is).
  String get displayText {
    final String s = term.source;
    return s.startsWith('+') ? s.substring(1) : s;
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = palette.groupBg(groupIndex);
    final Color fg = palette.groupText(groupIndex);

    return Semantics(
      button: true,
      label: 'Entry ${NumberFormatter.format(term.value)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: onLongPressStart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: CalcDims.chipHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? bg.withAlpha(140) : bg,
            borderRadius: BorderRadius.circular(CalcDims.chipRadius),
            border: selected
                ? Border.all(color: palette.groupSubtotal(groupIndex), width: 2)
                : null,
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: fg,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
