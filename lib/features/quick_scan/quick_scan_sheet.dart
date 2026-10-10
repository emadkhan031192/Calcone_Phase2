import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rational/rational.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/calculator_exception.dart';
import '../../core/utils/number_formatter.dart';
import '../../features/basic/calculator_controller.dart';
import '../../features/basic/widgets/undo_snackbar.dart';
import '../../features/sharing/share_sheet.dart';
import '../../models/calculation_entry.dart';
import 'widgets/scan_tile.dart';

/// Opens the Quick Scan bottom sheet (spec §8–§11).
Future<void> showQuickScanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext ctx, ScrollController scrollController) =>
          QuickScanSheet(scrollController: scrollController),
    ),
  );
}

/// Entries with more than this many values switch to the grouped view
/// (spec §10).
const int _groupThreshold = 12;
const int _groupSize = 4;

class QuickScanSheet extends ConsumerStatefulWidget {
  const QuickScanSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<QuickScanSheet> createState() => _QuickScanSheetState();
}

class _QuickScanSheetState extends ConsumerState<QuickScanSheet> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    listenForUndo(ref, context);

    final CalculatorUiState state = ref.watch(calculatorControllerProvider);
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<CalculationEntry> tape = state.tape;
    final Rational total = controller.tapeTotal;

    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Row(
            children: <Widget>[
              Text(
                'QUICK SCAN',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${tape.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Share calculation',
                icon: const Icon(Icons.share_outlined),
                onPressed: tape.isEmpty
                    ? null
                    : () => showShareSheet(
                          context,
                          controller.calculationSharePayload(),
                        ),
              ),
              IconButton(
                tooltip: 'Saved numbers',
                icon: const Icon(Icons.bookmark_border_rounded),
                onPressed: _showSavedNumbers,
              ),
              IconButton(
                tooltip: 'Clear tape',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: tape.isEmpty
                    ? null
                    : () {
                        setState(() => _selectedId = null);
                        controller.clearTape();
                      },
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: tape.isEmpty
              ? _emptyState(scheme, textTheme)
              : CustomScrollView(
                  controller: widget.scrollController,
                  slivers: <Widget>[
                    if (tape.length <= _groupThreshold)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 130,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.15,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext ctx, int i) =>
                                _tile(ctx, tape[i], controller),
                            childCount: tape.length,
                          ),
                        ),
                      )
                    else
                      ..._groupedSlivers(tape, controller),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
        ),
        if (_selectedId != null)
          _selectionBar(controller, tape, scheme, textTheme),
        _totalBar(total, tape.isEmpty, scheme, textTheme),
      ],
    );
  }

  Widget _emptyState(ColorScheme scheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.calculate_outlined,
            size: 48,
            color: scheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Calculations you make will appear here\nfor fast visual scanning.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Long tapes are grouped visually with subtotals (spec §10) while
  /// every value stays tappable.
  List<Widget> _groupedSlivers(
    List<CalculationEntry> tape,
    CalculatorController controller,
  ) {
    final List<Widget> slivers = <Widget>[];
    for (int g = 0; g * _groupSize < tape.length; g++) {
      final int start = g * _groupSize;
      final int end = (start + _groupSize).clamp(0, tape.length);
      final List<CalculationEntry> group = tape.sublist(start, end);
      final Rational subtotal = group.fold<Rational>(
        Rational.zero,
        (Rational s, CalculationEntry e) => s + e.result,
      );
      final ColorScheme scheme = Theme.of(context).colorScheme;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${start + 1}–$end',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      NumberFormatter.format(subtotal),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: <Widget>[
                    for (final CalculationEntry e in group)
                      _tile(context, e, controller, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _tile(
    BuildContext context,
    CalculationEntry entry,
    CalculatorController controller, {
    bool compact = false,
  }) {
    return ScanTile(
      entry: entry,
      compact: compact,
      selected: _selectedId == entry.id,
      onTap: () => setState(() {
        _selectedId = _selectedId == entry.id ? null : entry.id;
      }),
      onLongPressStart: (LongPressStartDetails details) =>
          _tileMenu(context, entry, controller, details.globalPosition),
    );
  }

  Future<void> _tileMenu(
    BuildContext context,
    CalculationEntry entry,
    CalculatorController controller,
    Offset position,
  ) async {
    final String? choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        PopupMenuItem<String>(value: 'copy', child: Text('Copy')),
        PopupMenuItem<String>(value: 'save', child: Text('Save')),
      ],
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'edit':
        await _editEntry(entry);
      case 'delete':
        setState(() => _selectedId = null);
        controller.deleteTapeEntry(entry.id);
      case 'copy':
        _copyText(
          '${entry.displayExpression} = ${NumberFormatter.format(entry.result)}',
          'Copied',
        );
      case 'save':
        await controller.saveTapeEntry(entry.id);
        if (mounted) _copyText('', 'Saved');
    }
  }

  Future<void> _editEntry(CalculationEntry entry) async {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    final TextEditingController textController =
        TextEditingController(text: entry.displayExpression);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setDialog) => AlertDialog(
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. 2500*15%',
                  errorText: error,
                ),
                onSubmitted: (_) => _saveEdit(
                  ctx,
                  setDialog,
                  (String? e) => error = e,
                  controller,
                  entry,
                  textController.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The total recalculates automatically.',
                style: Theme.of(ctx).textTheme.labelSmall,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _saveEdit(
                ctx,
                setDialog,
                (String? e) => error = e,
                controller,
                entry,
                textController.text,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
  }

  void _saveEdit(
    BuildContext ctx,
    StateSetter setDialog,
    void Function(String?) setError,
    CalculatorController controller,
    CalculationEntry entry,
    String text,
  ) {
    try {
      controller.editTapeEntry(entry.id, _toRawExpression(text));
      if (mounted) setState(() => _selectedId = null);
      Navigator.of(ctx).pop();
    } on CalculatorException catch (e) {
      setDialog(() => setError(e.message));
    }
  }

  String _toRawExpression(String display) {
    return display
        .replaceAll(AppConstants.glyphMultiply, AppConstants.opMultiply)
        .replaceAll(AppConstants.glyphDivide, AppConstants.opDivide)
        .replaceAll(AppConstants.glyphSubtract, AppConstants.opSubtract);
  }

  void _copyText(String text, String message) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _selectionBar(
    CalculatorController controller,
    List<CalculationEntry> tape,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    final int index = tape.indexWhere((e) => e.id == _selectedId);
    if (index == -1) {
      _selectedId = null;
      return const SizedBox.shrink();
    }
    final CalculationEntry entry = tape[index];
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            onPressed: () => _editEntry(entry),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Delete'),
            onPressed: () {
              setState(() => _selectedId = null);
              controller.deleteTapeEntry(entry.id);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy'),
            onPressed: () => _copyText(
              '${entry.displayExpression} = ${NumberFormatter.format(entry.result)}',
              'Copied',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalBar(
    Rational total,
    bool empty,
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            'TOTAL',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            empty ? '—' : NumberFormatter.format(total),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavedNumbers() async {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    final List<String> numbers = await controller.loadSavedNumbers();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext ctx, StateSetter setDialog) => AlertDialog(
          title: const Text('Saved numbers'),
          content: SizedBox(
            width: double.maxFinite,
            child: numbers.isEmpty
                ? const Text(
                    'No saved numbers yet.\nLong-press the result and choose Save.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: numbers.length,
                    itemBuilder: (BuildContext ctx, int i) {
                      final String value = numbers[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          value,
                          textAlign: TextAlign.end,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Copy',
                              icon: const Icon(Icons.copy_outlined, size: 20),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: value));
                                Navigator.of(ctx).pop();
                                _copyText('', 'Copied');
                              },
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                await controller.removeSavedNumber(value);
                                setDialog(() => numbers.remove(value));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
