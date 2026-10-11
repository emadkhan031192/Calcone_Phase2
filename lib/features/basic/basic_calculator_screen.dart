import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../core/widgets/calcone_logo.dart';
import '../history/history_sheet.dart';
import '../quick_scan/quick_scan_sheet.dart';
import 'calculator_controller.dart';
import 'widgets/calculation_display.dart';
import 'widgets/keypad.dart';
import 'widgets/peek_handle.dart';
import 'widgets/undo_snackbar.dart';

/// The home screen: slim top bar (logo + history/theme buttons), the
/// display given all remaining space, the Tape pill, and the keypad.
/// Nothing else — no gap under the title.
class BasicCalculatorScreen extends ConsumerStatefulWidget {
  const BasicCalculatorScreen({super.key});

  @override
  ConsumerState<BasicCalculatorScreen> createState() =>
      _BasicCalculatorScreenState();
}

class _BasicCalculatorScreenState extends ConsumerState<BasicCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestore());
  }

  /// Offers to continue the previous session if one was auto-saved.
  /// Kept subtle: a single dialog on launch.
  Future<void> _maybeRestore() async {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (!await controller.hasSavedSession()) return;
    if (!mounted) return;
    final bool? cont = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Previous session'),
        content: const Text('Continue previous calculation?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Start New'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (cont == true) {
      await controller.restoreSavedSession();
    } else if (cont == false) {
      await controller.discardSavedSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    listenForUndo(ref, context);

    final CalculatorUiState state = ref.watch(calculatorControllerProvider);
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final ThemeModeNotifier themeModes = ref.read(themeModeProvider.notifier);
    ref.watch(themeModeProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Slim top bar: logo + wordmark left, History and Theme right.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: <Widget>[
                  const CalconeLogo(),
                  const Spacer(),
                  _TopBarButton(
                    icon: Icons.history_rounded,
                    tooltip: 'History',
                    semanticLabel: 'Open calculation history',
                    palette: p,
                    onPressed: () => showHistorySheet(context),
                  ),
                  const SizedBox(width: 8),
                  _TopBarButton(
                    icon: isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    tooltip: 'Theme: ${themeModes.label}',
                    semanticLabel:
                        'Toggle theme, currently ${themeModes.label}',
                    palette: p,
                    onPressed: () => themeModes.cycle(),
                  ),
                ],
              ),
            ),
            // The display takes all remaining space above the pill.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CalculationDisplay(
                    expression: state.expression,
                    result: state.resultPreview,
                    errorMessage: state.errorMessage,
                  ),
                ],
              ),
            ),
            // Centered Tape pill — swipe up (or tap) opens the sheet.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragEnd: (DragEndDetails details) {
                if ((details.primaryVelocity ?? 0) < -200) {
                  showQuickScanSheet(context);
                }
              },
              child: PeekHandle(
                onTap: () => showQuickScanSheet(context),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Keypad(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One 48dp tonal icon button for the top bar.
class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.icon,
    required this.tooltip,
    required this.semanticLabel,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String semanticLabel;
  final CalcPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: palette.topBarButtonBg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: SizedBox(
              width: CalcDims.minTouchTarget,
              height: CalcDims.minTouchTarget,
              child: Icon(icon, size: 24, color: palette.topBarButtonIcon),
            ),
          ),
        ),
      ),
    );
  }
}
