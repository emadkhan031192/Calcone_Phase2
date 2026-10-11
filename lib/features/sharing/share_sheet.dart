import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import 'share_card.dart';
import 'share_payload.dart';

/// Share sheet: a live preview of the branded calculation card plus
/// Share-as-image / Share-as-text / Copy-as-text actions. The preview
/// itself is the capture source, so what you see is what gets shared —
/// no UI contamination from the keypad.
Future<void> showShareSheet(BuildContext context, SharePayload payload) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => _ShareSheetBody(payload: payload),
  );
}

class _ShareSheetBody extends StatefulWidget {
  const _ShareSheetBody({required this.payload});

  final SharePayload payload;

  @override
  State<_ShareSheetBody> createState() => _ShareSheetBodyState();
}

class _ShareSheetBodyState extends State<_ShareSheetBody> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'SHARE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: ShareCard(payload: widget.payload),
              ),
            ),
            const SizedBox(height: 20),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: CircularProgressIndicator(),
              ),
            SizedBox(
              // Tight width so the flexed buttons distribute properly
              // (Padding loosens constraints, collapsing flex).
              width: double.infinity,
              child: Row(
                children: <Widget>[
                  // Image: blue gradient, wider than the tonal actions.
                  Expanded(
                    flex: 2,
                    child: _GradientAction(
                      icon: Icons.image_outlined,
                      label: 'Image',
                      palette: p,
                      onPressed: _busy ? null : () => _shareImage(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TonalAction(
                      icon: Icons.share_outlined,
                      label: 'Text',
                      palette: p,
                      onPressed: _busy ? null : () => _shareText(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TonalAction(
                      icon: Icons.copy_outlined,
                      label: 'Copy',
                      palette: p,
                      onPressed: _busy ? null : () => _copyText(context),
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

  Future<void> _shareImage(BuildContext context) async {
    setState(() => _busy = true);
    try {
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('image capture failed');
      final Uint8List bytes = byteData.buffer.asUint8List();

      // XFile.fromData carries no path, which the Android share sheet
      // cannot resolve — write a real temp file instead.
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/calcone_share.png');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'image/png')],
        text: widget.payload.text,
      );
    } catch (_) {
      // Sharing never dead-ends: say so, then fall back to text.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image share failed — shared as text instead'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      await Share.share(widget.payload.text, subject: 'Calcone');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText(BuildContext context) {
    return Share.share(widget.payload.text, subject: 'Calcone');
  }

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.payload.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

/// The primary Image action: blue gradient, white text, 56dp tall.
class _GradientAction extends StatelessWidget {
  const _GradientAction({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final CalcPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share as image',
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  palette.equalsStart,
                  palette.equalsEnd,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.equalsEnd.withAlpha(82),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 22, color: palette.equalsText),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: palette.equalsText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tonal Text / Copy actions.
class _TonalAction extends StatelessWidget {
  const _TonalAction({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final CalcPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label == 'Text' ? 'Share as text' : 'Copy as text',
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.5 : 1,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.keyNumber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 22, color: palette.topBarButtonIcon),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
