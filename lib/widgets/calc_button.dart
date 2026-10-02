import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// A single calculator key. Deliberately minimal: no borders, no shadows —
/// just a filled rounded rect and a large, legible label (spec §28).
class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.onLongPress,
    required this.backgroundColor,
    required this.foregroundColor,
    this.semanticLabel,
    this.flex = 1,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color backgroundColor;
  final Color foregroundColor;
  final String? semanticLabel;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXs),
        child: Semantics(
          button: true,
          label: semanticLabel ?? label,
          child: Material(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              onLongPress: onLongPress,
              child: SizedBox(
                height: 64,
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: foregroundColor,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
