import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// The top of the screen: a smaller expression line, a large result, and
/// (once Quick Scan lands in Phase 2) a peek handle beneath it (spec §5,
/// §11). Horizontal scrolling keeps a long expression from wrapping or
/// forcing the font size down.
class CalculationDisplay extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
            label: errorMessage != null ? 'Error: $errorMessage' : 'Result: $result',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Text(
                errorMessage ?? result,
                style: textTheme.displayLarge?.copyWith(
                  color: errorMessage != null ? scheme.error : scheme.onSurface,
                  fontSize: errorMessage != null ? 18 : textTheme.displayLarge?.fontSize,
                  fontWeight: errorMessage != null ? FontWeight.w500 : FontWeight.w300,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
