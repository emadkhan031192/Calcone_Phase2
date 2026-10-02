import 'package:flutter/material.dart';

/// The small "there's more here" affordance beneath the result (spec §11).
///
/// Phase 1 renders it so the layout and visual language are final; the
/// swipe-up-to-open-Quick-Scan gesture itself is a Phase 2 deliverable
/// (spec §8–§10) and is intentionally not wired up yet. [onTap] is exposed
/// now so Phase 2 only has to add behaviour, not plumbing.
class PeekHandle extends StatelessWidget {
  const PeekHandle({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context)
        .colorScheme
        .onSurfaceVariant
        .withOpacity(0.5);
    return Semantics(
      button: onTap != null,
      label: 'Quick Scan handle',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.keyboard_arrow_up_rounded, color: color, size: 20),
        ),
      ),
    );
  }
}
