import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/calcone_logo.dart';
import 'share_payload.dart';

/// The branded calculation card: white with soft blue/green/yellow/red
/// radial glows, logo + wordmark, entries chip, an optional custom
/// title, the expression with blue operators, and the big result.
///
/// Always rendered light so the shared image looks the same on every
/// device. The share sheet captures this exact widget, so what you see
/// is what gets shared.
class ShareCard extends ConsumerWidget {
  const ShareCard({super.key, required this.payload});

  final SharePayload payload;

  static const Color _ink = Color(0xFF191C20);
  static const Color _muted = Color(0xFF5A6272);
  static const Color _blue = Color(0xFF0B57D0);

  static final RegExp _tokenPattern = RegExp(r'[\d,\.]+%?|[+−×÷()%]');
  static const Set<String> _operators = <String>{'+', '−', '×', '÷'};

  List<TextSpan> _expressionSpans(String expr, double fontSize) {
    final List<String> tokens = _tokenPattern
        .allMatches(expr)
        .map((RegExpMatch m) => m.group(0)!)
        .toList();
    final TextStyle base = TextStyle(
      fontFamily: 'Outfit',
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: _ink,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return <TextSpan>[
      for (final String t in tokens)
        TextSpan(
          text: t,
          style: base.copyWith(
            color: _operators.contains(t) ? _blue : _ink,
          ),
        ),
    ];
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color.withAlpha(36), color.withAlpha(0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const CalcPalette p = CalcPalette.light;
    final AppSettings settings = ref.watch(settingsProvider);
    final String? total = payload.total;
    String totalPrefix = '';
    String totalValue = total ?? '';
    if (total != null && total.startsWith('= ')) {
      totalPrefix = '= ';
      totalValue = total.substring(2);
    }

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.cardBorder, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -70,
              right: -70,
              child: _glow(p.cardGlowBlue, 200),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _glow(p.cardGlowGreen, 210),
            ),
            Positioned(
              bottom: -70,
              right: -50,
              child: _glow(p.cardGlowYellow, 190),
            ),
            Positioned(
              top: -60,
              left: -70,
              child: _glow(p.cardGlowRed, 180),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // Stretch: the Stack above loosens constraints, which
                // collapses Spacers — tight children keep the layout.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // Tight width so the wordmark ellipsizes instead of
                      // overflowing when the font runs wide.
                      const Expanded(
                        child: CalconeLogo(
                          squareSize: 18,
                          textColor: _ink,
                          accentColor: _blue,
                        ),
                      ),
                      if (payload.entryCount != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD3E3FD),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${payload.entryCount} ENTRIES',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: _blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (payload.displayTitle != null) ...<Widget>[
                    const SizedBox(height: 18),
                    Text(
                      payload.displayTitle!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: rs(settings, 22),
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: _expressionSpans(
                        payload.expression ?? payload.rows.join(' '),
                        rs(settings, 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFD3E3FD)),
                  const SizedBox(height: 18),
                  if (total != null)
                    // FittedBox shrinks the total to fit the card instead
                    // of truncating ("8,30...") when there are many digits.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: <TextSpan>[
                            if (totalPrefix.isNotEmpty)
                              TextSpan(
                                text: '= ',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: rs(settings, 44),
                                  fontWeight: FontWeight.w600,
                                  color: _blue,
                                ),
                              ),
                            TextSpan(
                              text: totalValue,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize:
                                    rs(settings, CalcDims.shareResultFontSize),
                                fontWeight: FontWeight.w700,
                                letterSpacing: -3,
                                height: 1.05,
                                color: _ink,
                                fontFeatures: const <FontFeature>[
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  const Text(
                    'MADE WITH CALCONE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
