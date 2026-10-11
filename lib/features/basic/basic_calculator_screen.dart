import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calcone_logo.dart';
import '../history/history_sheet.dart';
import '../quick_scan/quick_scan_sheet.dart';
import '../settings/settings_sheet.dart';
import '../sharing/share_sheet.dart';
import 'calculator_controller.dart';
import 'widgets/calculation_display.dart';
import 'widgets/keypad.dart';
import 'widgets/undo_snackbar.dart';

/// The home screen: slim top bar (logo, language, settings, history,
/// theme), the display given all remaining space, the Tape pill, the
/// bilingual share strip, and the keypad. Landscape uses two panes.
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
    final AppStrings s = ref.read(stringsProvider);
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (!await controller.hasSavedSession()) return;
    if (!mounted) return;
    final bool? cont = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(s.previousSession),
        content: Text(s.continuePrevious),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.startNew),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.cont),
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

  void _openShare() {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    final payload = controller.quickScanTerms != null
        ? controller.calculationSharePayload()
        : controller.resultSharePayload();
    showShareSheet(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    listenForUndo(ref, context);
    final bool landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _topBar(context, ref),
            Expanded(
              child: landscape
                  ? _landscapeBody(context, ref)
                  : _portraitBody(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Slim top bar: logo left; settings, history and theme right.
  Widget _topBar(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppStrings s = ref.watch(stringsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 0),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: <Widget>[
            const Expanded(child: CalconeLogo(squareSize: 16)),
            _TopBarButton(
              icon: Icons.menu_rounded,
              tooltip: s.settings,
              semanticLabel: s.settings,
              palette: p,
              onPressed: () => showSettingsSheet(context),
            ),
            const SizedBox(width: 6),
            _TopBarButton(
              icon: Icons.history_rounded,
              tooltip: s.history,
              semanticLabel: s.openHistory,
              palette: p,
              onPressed: () => showHistorySheet(context),
            ),
            const SizedBox(width: 6),
            _TopBarButton(
              icon:
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: s.theme,
              semanticLabel: s.theme,
              palette: p,
              onPressed: notifier.cycleTheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _portraitBody(BuildContext context, WidgetRef ref) {
    final CalculatorUiState state = ref.watch(calculatorControllerProvider);
    return Column(
      children: <Widget>[
        // The display takes all remaining space; swipe up anywhere on it
        // opens the Tape sheet.
        Expanded(
          child: _swipeUpToTape(
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CalculationDisplay(
                  expression: state.expression,
                  result: state.resultPreview,
                  errorKey: state.errorKey,
                ),
              ],
            ),
          ),
        ),
        _tapeHint(context, ref),
        _shareStrip(context, ref),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Keypad(),
        ),
      ],
    );
  }

  /// Landscape: display + hints on the left, keypad on the right with
  /// responsive key heights.
  Widget _landscapeBody(BuildContext context, WidgetRef ref) {
    final CalculatorUiState state = ref.watch(calculatorControllerProvider);
    return Row(
      children: <Widget>[
        Expanded(
          flex: 5,
          child: _swipeUpToTape(
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CalculationDisplay(
                  expression: state.expression,
                  result: state.resultPreview,
                  errorKey: state.errorKey,
                  compact: true,
                ),
                _tapeHint(context, ref),
                _shareStrip(context, ref),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double keyHeight =
                  (constraints.maxHeight - 4 * CalcDims.keyGap) / 5;
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
                child: Keypad(keyHeight: keyHeight.clamp(48, 72)),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Swipe-up anywhere on the display opens the Tape sheet. The result
  /// area's own horizontal swipes (copy/share) are unaffected.
  Widget _swipeUpToTape(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (DragEndDetails details) {
        if ((details.primaryVelocity ?? 0) < -200) {
          showQuickScanSheet(context);
        }
      },
      child: child,
    );
  }

  /// Just a hint line where the pill was — tappable for discoverability.
  Widget _tapeHint(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppStrings s = ref.watch(stringsProvider);
    final int count = ref.watch(calculatorControllerProvider).tape.length;
    final String text = count == 0
        ? s.swipeUpForTape
        : '${s.tape} $count · ${s.swipeUpForTape}';
    return Semantics(
      button: true,
      label: count == 0 ? s.openTape : s.openTapeCount(count),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showQuickScanSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
          // Single wrapping Text — a Row(min) with a long Text does not
          // wrap under loose constraints and overflows.
          child: Text(
            '↑ $text',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.muted,
            ),
          ),
        ),
      ),
    );
  }

  /// Narrow bilingual strip — tap or swipe up opens the share sheet.
  Widget _shareStrip(BuildContext context, WidgetRef ref) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openShare,
      onVerticalDragEnd: (DragEndDetails details) {
        if ((details.primaryVelocity ?? 0) < -200) _openShare();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: p.keyNumber,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.ios_share_outlined,
              size: 15,
              color: p.topBarButtonIcon,
            ),
            const SizedBox(width: 6),
            // Always bilingual, per the request. Flexible so a wide
            // fallback font ellipsizes instead of overflowing the Row.
            Flexible(
              child: Text(
                'Share · شیئر کریں',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.topBarButtonIcon,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One 42dp tonal icon button for the top bar.
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
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onPressed,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, size: 21, color: palette.topBarButtonIcon),
            ),
          ),
        ),
      ),
    );
  }
}
