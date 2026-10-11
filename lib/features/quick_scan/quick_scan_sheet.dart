import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rational/rational.dart';

import '../../core/errors/calculator_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/number_formatter.dart';
import '../../engines/decomposition/expression_decomposer.dart';
import '../../features/basic/calculator_controller.dart';
import '../../features/basic/widgets/undo_snackbar.dart';
import '../../features/sharing/share_sheet.dart';
import 'widgets/scan_tile.dart';

/// Opens the Tape bottom sheet.
Future<void> showQuickScanSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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

const int _groupSize = 4;

class QuickScanSheet extends ConsumerStatefulWidget {
  const QuickScanSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<QuickScanSheet> createState() => _QuickScanSheetState();
}

class _QuickScanSheetState extends ConsumerState<QuickScanSheet> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    listenForUndo(ref, context);

    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    // Rebuild when the calculation changes.
    ref.watch(calculatorControllerProvider);
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<ExpressionTerm>? terms = controller.quickScanTerms;
    final Rational? total = controller.quickScanTotal;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: SizedBox(
            // Tight width so the Spacer pushes the buttons right.
            width: double.infinity,
            child: Row(
              children: <Widget>[
                Text(
                  'TAPE',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              _CountChip(count: terms?.length ?? 0),
              const Spacer(),
              _HeaderButton(
                icon: Icons.share_outlined,
                tooltip: 'Share calculation',
                background: p.tapePillBg,
                foreground: p.tapePillText,
                onPressed: terms == null
                    ? null
                    : () => showShareSheet(
                          context,
                          controller.calculationSharePayload(),
                        ),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.bookmark_border_rounded,
                tooltip: 'Saved numbers',
                background: p.keyNumber,
                foreground: p.topBarButtonIcon,
                onPressed: _showSavedNumbers,
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.delete_sweep_outlined,
                tooltip: 'Clear tape',
                background: p.keyClear,
                foreground: p.keyClearText,
                onPressed: terms == null
                    ? null
                    : () {
                        setState(() => _selectedIndex = null);
                        controller.clearAll();
                        Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
        ),
        Expanded(
          child: terms == null
              ? _emptyState(p, textTheme)
              : CustomScrollView(
                  controller: widget.scrollController,
                  slivers: <Widget>[
                    ..._groupedSlivers(terms, controller, p),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
        ),
        if (_selectedIndex != null && terms != null)
          _selectionBar(controller, terms, p),
        _totalCard(total, p),
      ],
    );
  }

  Widget _emptyState(CalcPalette p, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.calculate_outlined,
            size: 48,
            color: p.muted.withOpacity(0.5),
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
            style: textTheme.bodyMedium?.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }

  /// Entries in rows of 4; each group of 4 gets the next color in the
  /// blue → green → yellow → red cycle, with its own subtotal.
  List<Widget> _groupedSlivers(
    List<ExpressionTerm> terms,
    CalculatorController controller,
    CalcPalette p,
  ) {
    final List<Widget> slivers = <Widget>[];
    final TextTheme textTheme = Theme.of(context).textTheme;
    for (int g = 0; g * _groupSize < terms.length; g++) {
      final int start = g * _groupSize;
      final int end = (start + _groupSize).clamp(0, terms.length);
      final List<ExpressionTerm> group = terms.sublist(start, end);
      final Rational subtotal = group.fold<Rational>(
        Rational.zero,
        (Rational s, ExpressionTerm t) => s + t.value,
      );
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${start + 1}–$end',
                      style: textTheme.labelSmall?.copyWith(
                        color: p.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      NumberFormatter.format(subtotal),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.groupSubtotal(g),
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: CalcDims.keyGap,
                    crossAxisSpacing: CalcDims.keyGap,
                    mainAxisExtent: CalcDims.chipHeight,
                  ),
                  children: <Widget>[
                    for (int i = 0; i < group.length; i++)
                      _tile(context, terms, start + i, controller, g, p),
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
    List<ExpressionTerm> terms,
    int index,
    CalculatorController controller,
    int groupIndex,
    CalcPalette p,
  ) {
    return ScanTile(
      term: terms[index],
      groupIndex: groupIndex,
      palette: p,
      selected: _selectedIndex == index,
      onTap: () => setState(() {
        _selectedIndex = _selectedIndex == index ? null : index;
      }),
      onLongPressStart: (LongPressStartDetails details) =>
          _tileMenu(context, terms, index, controller, details.globalPosition),
    );
  }

  Future<void> _tileMenu(
    BuildContext context,
    List<ExpressionTerm> terms,
    int index,
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
    final ExpressionTerm term = terms[index];
    switch (choice) {
      case 'edit':
        await _editTerm(terms, index);
      case 'delete':
        setState(() => _selectedIndex = null);
        controller.deleteQuickScanTerm(index);
      case 'copy':
        _copyText(NumberFormatter.format(term.value), 'Copied');
      case 'save':
        await controller.saveQuickScanTerm(index);
        if (mounted) _copyText('', 'Saved');
    }
  }

  Future<void> _editTerm(List<ExpressionTerm> terms, int index) async {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => _EditTermDialog(
        initialText: terms[index].source,
        onSave: (String text) {
          controller.editQuickScanTerm(index, text);
          if (mounted) setState(() => _selectedIndex = null);
        },
      ),
    );
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
    List<ExpressionTerm> terms,
    CalcPalette p,
  ) {
    final int index = _selectedIndex!;
    final TextTheme textTheme = Theme.of(context).textTheme;
    Widget action(String label, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 18, color: p.topBarButtonIcon),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.keyNumber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        // Tight width: Padding loosens constraints, and in a loose Row
        // Expanded children size intrinsically instead of sharing space.
        width: double.infinity,
        child: Row(
          children: <Widget>[
            action('Edit', Icons.edit_outlined, () => _editTerm(terms, index)),
          action('Delete', Icons.delete_outline, () {
            setState(() => _selectedIndex = null);
            controller.deleteQuickScanTerm(index);
          }),
          action('Copy', Icons.copy_outlined, () {
            _copyText(NumberFormatter.format(terms[index].value), 'Copied');
            setState(() => _selectedIndex = null);
          }),
          action('Save', Icons.bookmark_border_rounded, () async {
            await controller.saveQuickScanTerm(index);
            if (mounted) {
              _copyText('', 'Saved');
              setState(() => _selectedIndex = null);
            }
          }),
          ],
        ),
      ),
    );
  }

  /// The TOTAL footer card: blue gradient, white text, 44sp total.
  Widget _totalCard(Rational? total, CalcPalette p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[p.equalsStart, p.equalsEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.equalsEnd.withAlpha(82),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        // Tight width so spaceBetween distributes across the full card.
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'TOTAL',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: p.equalsText,
              ),
            ),
            Flexible(
              child: Text(
                total == null ? '—' : NumberFormatter.format(total),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: CalcDims.tapeTotalFontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                  color: p.equalsText,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
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

/// Small "TAPE" count chip in the sheet header.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: scheme.primary,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// One 48dp tonal icon button in the sheet header.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: background.withOpacity(onPressed == null ? 0.4 : 1),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: SizedBox(
              width: CalcDims.minTouchTarget,
              height: CalcDims.minTouchTarget,
              child: Icon(icon, size: 22, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}

/// Edit dialog for one Tape term.
///
/// Owns its [TextEditingController] so disposal happens with the dialog's
/// own lifecycle — disposing it from the caller races the dialog route's
/// exit transition and crashes the text field.
class _EditTermDialog extends StatefulWidget {
  const _EditTermDialog({
    required this.initialText,
    required this.onSave,
  });

  final String initialText;

  /// Applies the edit; throws [CalculatorException] when the new text is
  /// invalid so the dialog can show the error instead of closing.
  final ValueChanged<String> onSave;

  @override
  State<_EditTermDialog> createState() => _EditTermDialogState();
}

class _EditTermDialogState extends State<_EditTermDialog> {
  late final TextEditingController _textController =
      TextEditingController(text: widget.initialText);
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      widget.onSave(_textController.text);
    } on CalculatorException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit value'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _textController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. 540',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(
            'The total recalculates automatically.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
