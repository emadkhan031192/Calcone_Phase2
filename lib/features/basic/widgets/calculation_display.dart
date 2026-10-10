import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../calculator_controller.dart';

/// The top of the screen: a smaller expression line, a large result, and
/// the peek handle beneath it (spec §5, §11). Horizontal scrolling keeps a
/// long expression from wrapping or forcing the font size down.
///
/// Gestures (spec §17): tap the result to copy it, long-press for the
/// contextual actions (Copy / Save / Show Steps), swipe left to copy and
/// swipe right to share when the result fits on screen. When the result
/// is long enough to need scrolling, the directional swipes yield to
/// scrolling and the long-press menu remains the alternative.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (expression.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                expression,
                style: textTheme.titleMedium,
                maxLines: 1,
              ),
            ),
          const SizedBox(height: AppConstants.spaceSm),
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
              onSwipeRight: () => ref
                  .read(calculatorControllerProvider.notifier)
                  .shareResultText(),
            ),
          ),
        ],
      ),
    );
  }

  void _copyResult(BuildContext context, WidgetRef ref) {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.state.errorMessage != null) return;
    Clipboard.setData(ClipboardData(text: result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _resultMenu(BuildContext context, WidgetRef ref) async {
    final CalculatorController controller =
        ref.read(calculatorControllerProvider.notifier);
    if (controller.state.errorMessage != null) return;
    final List<String>? steps = controller.explainResult();
    final String? choice = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 200, 100, 200),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'copy', child: Text('Copy')),
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? style = textTheme.displayLarge?.copyWith(
      color: isError ? scheme.error : scheme.onSurface,
      fontSize: isError ? 18 : textTheme.displayLarge?.fontSize,
      fontWeight: isError ? FontWeight.w500 : FontWeight.w300,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget textWidget = Text(text, style: style, maxLines: 1);
        if (_fits(text, style, constraints.maxWidth)) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isError ? null : onTap,
            onLongPress: isError ? null : onLongPress,
            onHorizontalDragEnd: isError
                ? null
                : (DragEndDetails details) {
                    final double velocity = details.primaryVelocity ?? 0;
                    if (velocity < 0) {
                      onSwipeLeft();
                    } else if (velocity > 0) {
                      onSwipeRight();
                    }
                  },
            child: Align(
              alignment: Alignment.centerRight,
              child: textWidget,
            ),
          );
        }
        // Too long to fit: horizontal scrolling wins over swipes; the
        // long-press menu stays available as the alternative.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: GestureDetector(
            onTap: isError ? null : onTap,
            onLongPress: isError ? null : onLongPress,
            child: textWidget,
          ),
        );
      },
    );
  }

  bool _fits(String text, TextStyle? style, double maxWidth) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width <= maxWidth;
  }
}
