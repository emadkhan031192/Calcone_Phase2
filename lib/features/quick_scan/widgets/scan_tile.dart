import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../models/calculation_entry.dart';

/// One value in the Quick Scan grid (spec §8): the expression small, the
/// result prominent. Deliberately card-free — no borders unless selected.
class ScanTile extends StatelessWidget {
  const ScanTile({
    super.key,
    required this.entry,
    required this.selected,
    required this.onTap,
    required this.onLongPressStart,
    this.compact = false,
  });

  final CalculationEntry entry;
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
              entry.displayExpression,
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: compact ? 2 : 4),
            Text(
              NumberFormatter.format(entry.result),
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
