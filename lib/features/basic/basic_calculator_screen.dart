import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../quick_scan/quick_scan_sheet.dart';
import 'calculator_controller.dart';
import 'widgets/calculation_display.dart';
import 'widgets/keypad.dart';
import 'widgets/peek_handle.dart';
import 'widgets/undo_snackbar.dart';

/// The entire home screen (spec §4): title, display, peek handle, keypad.
/// Nothing else. Scientific mode, converter, finance tools, history — all
/// of it stays reachable through contextual interaction, not permanent
/// chrome on this screen.
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

  /// Offers to continue the previous session if one was auto-saved
  /// (spec §19). Kept subtle: a single dialog on launch.
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
  Widget build(BuildContext context, WidgetRef ref) {
    listenForUndo(ref, context);

    final CalculatorUiState state = ref.watch(calculatorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  CalculationDisplay(
                    expression: state.expression,
                    result: state.resultPreview,
                    errorMessage: state.errorMessage,
                  ),
                  // Swipe up (or tap) opens Quick Scan; the sheet itself
                  // is dismissed by swiping down (spec §11, §17).
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
                  const SizedBox(height: AppConstants.spaceSm),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppConstants.spaceSm),
              child: Keypad(),
            ),
          ],
        ),
      ),
    );
  }
}
