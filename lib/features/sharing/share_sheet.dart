import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import 'share_card.dart';
import 'share_payload.dart';

/// Share sheet: a live preview of the branded calculation card plus
/// Share-as-image / Share-as-text / Copy-as-text actions. The preview
/// itself is the capture source, so what you see is what gets shared —
/// no UI contamination from the keypad.
///
/// Tapping Image or Text first asks for an optional title (e.g.
/// "Karyana Khata"), shown on the card and in the text share.
Future<void> showShareSheet(BuildContext context, SharePayload payload) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => _ShareSheetBody(payload: payload),
  );
}

class _ShareSheetBody extends ConsumerStatefulWidget {
  const _ShareSheetBody({required this.payload});

  final SharePayload payload;

  @override
  ConsumerState<_ShareSheetBody> createState() => _ShareSheetBodyState();
}

class _ShareSheetBodyState extends ConsumerState<_ShareSheetBody> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;
  String? _title;

  SharePayload get _titled => widget.payload.withTitle(_title);

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final AppStrings strings = ref.watch(stringsProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              strings.share,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: RepaintBoundary(
                key: _cardKey,
                child: ShareCard(payload: _titled),
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
                      label: strings.image,
                      semanticLabel: strings.shareAsImage,
                      palette: p,
                      onPressed:
                          _busy ? null : () => _shareImage(context, strings),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TonalAction(
                      icon: Icons.share_outlined,
                      label: strings.text,
                      semanticLabel: strings.shareAsText,
                      palette: p,
                      onPressed:
                          _busy ? null : () => _shareText(context, strings),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TonalAction(
                      icon: Icons.copy_outlined,
                      label: strings.copy,
                      semanticLabel: strings.copyAsText,
                      palette: p,
                      onPressed:
                          _busy ? null : () => _copyText(context, strings),
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

  /// Asks for an optional share title. Returns null when dismissed,
  /// the (possibly empty) title otherwise.
  Future<String?> _askTitle(AppStrings strings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String last = prefs.getString('calcone_last_share_title') ?? '';
    if (!mounted) return null;
    final TextEditingController controller =
        TextEditingController(text: _title ?? last);
    try {
      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(strings.shareTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: strings.shareTitleHint),
            onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: Text(strings.skip),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(strings.share),
            ),
          ],
        ),
      );
      if (result != null && result.isNotEmpty) {
        await prefs.setString('calcone_last_share_title', result);
      }
      return result;
    } finally {
      controller.dispose();
    }
  }

  Future<void> _shareImage(BuildContext context, AppStrings strings) async {
    final String? title = await _askTitle(strings);
    if (title == null || !mounted) return;
    setState(() {
      _title = title.isEmpty ? null : title;
      _busy = true;
    });
    try {
      final RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw StateError('image capture failed');
      final Uint8List bytes = byteData.buffer.asUint8List();
      if (bytes.isEmpty) throw StateError('empty capture');

      // XFile.fromData carries no path, which the Android share sheet
      // cannot resolve — write a real temp file instead.
      final Directory dir = await getTemporaryDirectory();
      final File file = File('${dir.path}/calcone_share.png');
      await file.writeAsBytes(bytes, flush: true);
      if (!await file.exists()) throw StateError('temp file missing');
      if (await file.length() == 0) throw StateError('temp file empty');

      await Share.shareXFiles(
        <XFile>[
          XFile(file.path, mimeType: 'image/png', name: 'calcone_share.png')
        ],
        text: _titled.text,
      );
    } catch (e) {
      // Sharing never dead-ends: report the cause (needed for diagnosis
      // on real devices), then fall back to text.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.imageShareFailed}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      await Share.share(_titled.text, subject: 'Calcone');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareText(BuildContext context, AppStrings strings) async {
    final String? title = await _askTitle(strings);
    if (title == null || !mounted) return;
    setState(() => _title = title.isEmpty ? null : title);
    await Share.share(_titled.text, subject: 'Calcone');
  }

  void _copyText(BuildContext context, AppStrings strings) {
    Clipboard.setData(ClipboardData(text: _titled.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.copiedClipboard),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// The primary Image action: blue gradient, white text, 56dp tall.
class _GradientAction extends StatelessWidget {
  const _GradientAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final CalcPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
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
            child: SizedBox(
              // Tight width (clamped from the button's tight width) so
              // the label can ellipsis instead of overflowing.
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 22, color: palette.equalsText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: palette.equalsText,
                      ),
                    ),
                  ),
                ],
              ),
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
    required this.semanticLabel,
    required this.palette,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final CalcPalette palette;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
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
            child: SizedBox(
              // Tight width (clamped from the button's tight width) so
              // the label can ellipsis instead of overflowing.
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 22, color: palette.topBarButtonIcon),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
