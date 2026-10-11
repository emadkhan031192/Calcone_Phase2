import 'package:flutter/material.dart';

/// The Calcone brand mark: a 2x2 grid of rounded squares
/// (blue, green, yellow, red) plus the wordmark — "Calc" in the text
/// color, "one" in primary blue. All in Outfit.
class CalconeLogo extends StatelessWidget {
  const CalconeLogo({
    super.key,
    this.squareSize = 22,
    this.showWordmark = true,
    this.textColor,
    this.accentColor,
  });

  final double squareSize;
  final bool showWordmark;

  /// Explicit colors for fixed-theme surfaces (e.g. the share card,
  /// which is always light). Defaults to the ambient theme.
  final Color? textColor;
  final Color? accentColor;

  static const List<Color> _squares = <Color>[
    Color(0xFF3B7DF8), // blue
    Color(0xFF2FB36D), // green
    Color(0xFFF6B93B), // yellow
    Color(0xFFEF5B5B), // red
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double gap = squareSize * 0.14;
    final double r = squareSize * 0.28;

    Widget square(Color c) => Container(
          width: squareSize,
          height: squareSize,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    final Widget mark = SizedBox(
      width: squareSize * 2 + gap,
      height: squareSize * 2 + gap,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          for (final Color c in _squares) square(c),
        ],
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: squareSize * 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            children: <TextSpan>[
              TextSpan(
                text: 'Calc',
                style: TextStyle(color: textColor ?? scheme.onSurface),
              ),
              TextSpan(
                text: 'one',
                style: TextStyle(color: accentColor ?? scheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
