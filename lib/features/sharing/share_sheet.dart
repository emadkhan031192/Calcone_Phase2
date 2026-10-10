import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'share_card.dart';
import 'share_payload.dart';

/// Share sheet (spec §12–§14): a live preview of the clean calculation
/// card plus Share-as-image / Share-as-text / Copy-as-text actions. The
/// preview itself is the capture source, so what you see is what gets
/// shared — no UI contamination from the keypad.
Future<void> showShareSheet(BuildContext context, SharePayload payload) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SHARE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: _cardKey,
              child: ShareCard(payload: widget.payload),
            ),
            const SizedBox(height: 20),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: CircularProgressIndicator(),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _action(
                  context,
                  icon: Icons.image_outlined,
                  label: 'Image',
                  onPressed: _busy ? null : () => _shareImage(context),
                ),
                _action(
                  context,
                  icon: Icons.share_outlined,
                  label: 'Text',
                  onPressed: _busy ? null : () => _shareText(context),
                ),
                _action(
                  context,
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  onPressed: _busy ? null : () => _copyText(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
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
      await Share.shareXFiles(
        <XFile>[
          XFile.fromData(
            bytes,
            name: 'calcone.png',
            mimeType: 'image/png',
          ),
        ],
        text: widget.payload.text,
      );
    } catch (_) {
      // Image capture can fail on some devices — fall back to text so
      // sharing never dead-ends.
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
