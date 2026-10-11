import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/number_formatter.dart';
import '../../models/calculation_entry.dart';
import '../basic/calculator_controller.dart';

/// Minimal history: the session's past calculations, newest first.
/// Tap one to load its expression back into the calculator.
Future<void> showHistorySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => const _HistorySheetBody(),
  );
}

class _HistorySheetBody extends ConsumerWidget {
  const _HistorySheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppStrings strings = ref.watch(stringsProvider);
    final List<CalculationEntry> entries =
        ref.watch(calculatorControllerProvider).tape.reversed.toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext ctx, ScrollController scrollController) => Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: <Widget>[
                Text(
                  strings.history,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entries.length}',
                  style: textTheme.labelSmall?.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      strings.noCalculationsYet,
                      style: textTheme.bodyMedium?.copyWith(color: p.muted),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext ctx, int i) {
                      final CalculationEntry e = entries[i];
                      return _HistoryRow(entry: e);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.entry});

  final CalculationEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label:
          ref.watch(stringsProvider).loadCalculation(entry.displayExpression),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref
              .read(calculatorControllerProvider.notifier)
              .loadExpression(entry.expression);
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: p.keyNumber,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.displayExpression,
                  style: textTheme.bodyMedium?.copyWith(color: p.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                NumberFormatter.format(entry.result),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
