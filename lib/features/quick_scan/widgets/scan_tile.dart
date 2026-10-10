import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../engines/decomposition/expression_decomposer.dart';

/// One term in the Quick Scan grid (spec §8): the term's source small,
/// its value prominent. Deliberately card-free — no borders unless
/// selected.
class ScanTile extends StatelessWidget {
  const ScanTile({
    super.key,
    required this.term,
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
    this.compact = false,
  });

  final ExpressionTerm term;
  final bool selected;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails details) onLongPressStart;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: EdgeInsets.all(compact ? 6 : 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer.withOpacity(0.5)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              term.source,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              NumberFormatter.format(term.value),
              style: (compact ? textTheme.titleMedium : textTheme.titleLarge)
                  ?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
