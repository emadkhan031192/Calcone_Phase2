import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings.dart';
import 'app_theme.dart';

enum KeyKind { number, function, op, clear, equals }

/// One calculator key: tonal color by kind, 28dp radius, scales to 0.96
/// on press with a light haptic tick (when haptics are enabled).
/// Label size follows the font-size setting, weight follows the
/// font-weight setting.
class CalcKey extends ConsumerStatefulWidget {
  const CalcKey({
    super.key,
    required this.onTap,
    this.onLongPress,
    this.label,
    this.icon,
    this.kind = KeyKind.number,
    this.semanticLabel,
    this.height,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final KeyKind kind;
  final String? semanticLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Overrides [CalcDims.keyHeight] (used for landscape).
  final double? height;

  @override
  ConsumerState<CalcKey> createState() => _CalcKeyState();
}

class _CalcKeyState extends ConsumerState<CalcKey> {
  bool _down = false;

  void _tick() {
    if (ref.read(settingsProvider).haptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _thunk() {
    if (ref.read(settingsProvider).haptics) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppSettings settings = ref.watch(settingsProvider);

    late final Color bg;
    late final Color fg;
    Gradient? gradient;
    double fontSize = 32;
    switch (widget.kind) {
      case KeyKind.number:
        bg = p.keyNumber;
        fg = p.keyNumberText;
      case KeyKind.function:
        bg = p.keyFunction;
        fg = p.keyFunctionText;
        fontSize = 28;
      case KeyKind.op:
        bg = p.keyOp;
        fg = p.keyOpText;
        fontSize = 34;
      case KeyKind.clear:
        bg = p.keyClear;
        fg = p.keyClearText;
        fontSize = 24;
      case KeyKind.equals:
        bg = p.equalsEnd;
        fg = p.equalsText;
        fontSize = 38;
        gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[p.equalsStart, p.equalsEnd],
        );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          _tick();
          widget.onTap();
        },
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _thunk();
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            height: widget.height ?? CalcDims.keyHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient == null ? bg : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(CalcDims.keyRadius),
              boxShadow: widget.kind == KeyKind.equals
                  ? <BoxShadow>[
                      BoxShadow(
                        color: p.equalsEnd.withAlpha(82),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: widget.icon != null
                ? Icon(widget.icon, size: 28, color: fg)
                : Text(
                    widget.label!,
                    style: TextStyle(
                      fontSize: rs(settings, fontSize),
                      fontWeight: keyWeight(settings),
                      color: fg,
                      fontFamily: 'Outfit',
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
