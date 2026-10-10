import 'package:flutter/material.dart';

import 'share_payload.dart';

/// The clean calculation card (spec §12): no keypad, no chrome — just the
/// numbers, in a calm typographic layout. Rendered with a fixed light
/// theme so the shared image looks the same on every device.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.payload});

  final SharePayload payload;

  static const Color _ink = Color(0xFF1A1C1E);
  static const Color _muted = Color(0xFF5A5E63);
  static const Color _accent = Color(0xFF3B5BFD);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E5E8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            payload.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: _accent,
            ),
          ),
          const SizedBox(height: 20),
          for (final String row in payload.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                row,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  color: _muted,
                ),
              ),
            ),
          if (payload.total != null) ...<Widget>[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE3E5E8)),
            const SizedBox(height: 12),
            Text(
              payload.total!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: _ink,
                letterSpacing: -0.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Calcone',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9AA0A6),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
