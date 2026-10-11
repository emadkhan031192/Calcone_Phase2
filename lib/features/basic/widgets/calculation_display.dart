import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../sharing/share_sheet.dart';
import '../calculator_controller.dart';

/// The top of the screen: the full expression (wrapped, right-aligned —
/// never clipped; operators in blue, the last number in full text color,
/// regular weight) above the large result.
///
/// Gestures: tap the result to copy it, long-press for the contextual
/// actions (Copy / Save / Show Steps), swipe left to copy and swipe right
/// to share when the result fits on screen. When the result is long enough
/// to need shrinking, the directional swipes yield and the long-press menu
/// remains the alternative.
class CalculationDisplay extends ConsumerWidget {
  const CalculationDisplay({
    super.key,
    required this.expression,
    required this.result,
    this.errorKey,
    this.compact = false,
  });

  final String expression;
  final String result;

  /// Key into [AppStrings.error], or null when there is no error.
  final String? errorKey;

  /// Smaller result for landscape.
  final bool compact;

  static const Set<String> _operators = <String>{'+', '−', '×', '÷'};
  static final RegExp _tokenPattern = RegExp(r'[\d,\.]+%?|[+−×÷()%]');
  static final RegExp _numberPattern = RegExp(r'^[\d,\.]+%?$');

  /// Splits the display expression into styled spans: operators blue,
  /// the last number in full text color, earlier numbers muted.
  List<TextSpan> _expressionSpans(
    String expr,
    TextStyle base,
    Color operatorColor,
    Color numberColor,
    Color lastNumberColor,
    Color muted,
  ) {
    final List<String> tokens = _tokenPattern
        .allMatches(expr)
        .map((RegExpMatch m) => m.group(0)!)
        .toList();

    int lastNumber = -1;
    for (int i = tokens.length - 1; i >= 0; i--) {
      if (_numberPattern.hasMatch(tokens[i])) {
        lastNumber = i;
        break;
      }
    }

    return <TextSpan>[
      for (int i = 0; i < tokens.length; i++)
        TextSpan(
          text: tokens[i],
          style: base.copyWith(
            color: _operators.contains(tokens[i])
                ? operatorColor
                : _numberPattern.hasMatch(tokens[i])
                    ? (i == lastNumber ? lastNumberColor : numberColor)
                    : muted,
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppStrings strings = ref.watch(stringsProvider);
    final AppSettings settings = ref.watch(settingsProvider);
    final String? errorMessage =
        errorKey == null ? null : strings.error(errorKey!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (expression.isNotEmpty)
            // The whole calculation, wrapped above the result so the
            // user always sees it — never faded or clipped.
            RichText(
              textAlign: TextAlign.right,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: _expressionSpans(
                  expression,
                  TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: rs(settings, 26),
                    fontWeight: exprWeight(settings),
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures()
                    ],
                  ),
                  scheme.primary,
                  p.muted,
                  scheme.onSurface,
                  p.muted,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            label: errorMessage != null
                ? '${strings.errorPrefix}$errorMessage'
                : '${strings.resultPrefix}$result',
            child: _ResultArea(
              text: errorMessage ?? result,
              isError: errorMessage != null,
              compact: compact,
              onTap: () => _copyResult(context, ref),
              onLongPress: () => _resultMenu(context, ref),
              onSwipeLeft: () => _copyResult(context, ref),
              onSwipeRight: () => _shareResult(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _copyResult(BuildContext context, WidgetRef ref) {
    final AppStrings strings = ref.read(stringsProvider);
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.hasError) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.copiedClipboard),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareResult(BuildContext context, WidgetRef ref) {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.hasError) return;
    if (controller.currentExpression.isEmpty && !controller.justEvaluated) {
      return;
    }
    showShareSheet(context, controller.resultSharePayload());
  }

  Future<void> _resultMenu(BuildContext context, WidgetRef ref) async {
    final AppStrings strings = ref.read(stringsProvider);
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.hasError) return;
    final List<String>? steps = controller.explainResult();
    final String? choice = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 200, 100, 200),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(value: 'copy', child: Text(strings.copy)),
        PopupMenuItem<String>(value: 'share', child: Text(strings.share)),
        PopupMenuItem<String>(value: 'save', child: Text(strings.save)),
        if (steps != null)
          PopupMenuItem<String>(value: 'steps', child: Text(strings.showSteps)),
      ],
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case 'copy':
        _copyResult(context, ref);
      case 'share':
        _shareResult(context, ref);
      case 'save':
        await controller.saveCurrentResult();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.saved),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      case 'steps':
        if (steps != null) _showSteps(context, steps, strings);
    }
  }

  void _showSteps(
      BuildContext context, List<String> steps, AppStrings strings) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(strings.steps),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${i + 1}. ${steps[i]}'),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.close),
          ),
        ],
      ),
    );
  }
}

class _ResultArea extends ConsumerWidget {
  const _ResultArea({
    required this.text,
    required this.isError,
    required this.compact,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final String text;
  final bool isError;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppSettings settings = ref.watch(settingsProvider);
    final TextStyle style = isError
        ? TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: scheme.error,
          )
        : _resultStyle(context, settings);

    // Shrinks for long numbers so nothing clips; animates on change.
    final Widget textWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        text,
        key: ValueKey<String>(text),
        style: style,
        maxLines: 1,
        textAlign: TextAlign.right,
      ),
    );

    final Widget shrunk = SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: textWidget,
      ),
    );

    if (isError) return Align(alignment: Alignment.centerRight, child: shrunk);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_fits(text, style, constraints.maxWidth)) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onLongPress: onLongPress,
            onHorizontalDragEnd: (DragEndDetails details) {
              final double velocity = details.primaryVelocity ?? 0;
              if (velocity < 0) {
                onSwipeLeft();
              } else if (velocity > 0) {
                onSwipeRight();
              }
            },
            child: shrunk,
          );
        }
        // Too long to fit even shrunk: horizontal scrolling wins over
        // swipes; the long-press menu stays available as the alternative.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: textWidget,
          ),
        );
      },
    );
  }

  TextStyle _resultStyle(BuildContext context, AppSettings settings) {
    return TextStyle(
      fontFamily: 'Outfit',
      fontSize: compact
          ? rs(settings, CalcDims.resultFontSize) * 0.62
          : rs(settings, CalcDims.resultFontSize),
      fontWeight: resultWeight(settings),
      letterSpacing: -3,
      height: 1.05,
      color: Theme.of(context).colorScheme.onSurface,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
  }

  bool _fits(String text, TextStyle style, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width <= maxWidth;
  }
}
