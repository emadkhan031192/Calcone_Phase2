import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../sharing/share_sheet.dart';
import '../calculator_controller.dart';

/// The top of the screen: the expression line (right-aligned,
/// auto-scrolled to the end, faded on the left edge — operators in blue,
/// the last number in full text color) above the large result.
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
    this.errorMessage,
  });

  final String expression;
  final String result;
  final String? errorMessage;

  static const Set<String> _operators = <String>{'+', '−', '×', '÷'};
  static final RegExp _tokenPattern = RegExp(r'[\d,\.]+%?|[+−×÷()%]');
  static final RegExp _numberPattern = RegExp(r'^[\d,\.]+%?$');

  /// Splits the display expression into styled spans: operators blue,
  /// the last number in full text color, earlier numbers muted.
  List<TextSpan> _expressionSpans(
    String expr,
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

    const TextStyle base = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 26,
      fontWeight: FontWeight.w500,
      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    );

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (expression.isNotEmpty)
            ShaderMask(
              // Fade the left edge so long expressions never clip digits.
              shaderCallback: (Rect bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[Colors.transparent, Colors.black],
                stops: <double>[0.0, 0.14],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: RichText(
                  text: TextSpan(
                    children: _expressionSpans(
                      expression,
                      scheme.primary,
                      p.muted,
                      scheme.onSurface,
                      p.muted,
                    ),
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            label: errorMessage != null
                ? 'Error: $errorMessage'
                : 'Result: $result',
            child: _ResultArea(
              text: errorMessage ?? result,
              isError: errorMessage != null,
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
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.hasError) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
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
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.hasError) return;
    final List<String>? steps = controller.explainResult();
    final String? choice = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 200, 100, 200),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'copy', child: Text('Copy')),
        const PopupMenuItem<String>(value: 'share', child: Text('Share')),
        const PopupMenuItem<String>(value: 'save', child: Text('Save')),
        if (steps != null)
          const PopupMenuItem<String>(
              value: 'steps', child: Text('Show Steps')),
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
            const SnackBar(
              content: Text('Saved'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      case 'steps':
        if (steps != null) _showSteps(context, steps);
    }
  }

  void _showSteps(BuildContext context, List<String> steps) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Steps'),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ResultArea extends StatelessWidget {
  const _ResultArea({
    required this.text,
    required this.isError,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final String text;
  final bool isError;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextStyle style = isError
        ? TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: scheme.error,
          )
        : TextStyle(
            fontFamily: 'Outfit',
            fontSize: CalcDims.resultFontSize,
            fontWeight: FontWeight.w500,
            letterSpacing: -3,
            height: 1.05,
            color: scheme.onSurface,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          );

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

  bool _fits(String text, TextStyle style, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width <= maxWidth;
  }
}
