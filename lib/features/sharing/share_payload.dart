/// What gets shared: a title, content rows, and an optional total line.
/// The same payload renders the image card and the plain-text share, so
/// the two never drift apart.
class SharePayload {
  const SharePayload({
    required this.title,
    required this.rows,
    this.total,
    this.expression,
    this.entryCount,
    this.displayTitle,
    this.steps,
  });

  final String title;
  final List<String> rows;
  final String? total;

  /// The full expression with display glyphs, rendered with blue
  /// operators on the branded card.
  final String? expression;

  /// Number of tape entries (shows the "N ENTRIES" chip on the card).
  final int? entryCount;

  /// Optional user-supplied title (e.g. "Karyana Khata") shown on the
  /// card and as the first line of the text share.
  final String? displayTitle;

  /// Step-by-step lines with running balances (e.g. "1. +75 = 120").
  /// When present, the text share uses these instead of [rows].
  final List<String>? steps;

  SharePayload withTitle(String? title) => SharePayload(
        title: this.title,
        rows: rows,
        total: total,
        expression: expression,
        entryCount: entryCount,
        steps: steps,
        displayTitle:
            title == null || title.trim().isEmpty ? null : title.trim(),
      );

  /// The title actually shown: the custom one when set.
  String get effectiveTitle => displayTitle ?? title;

  String get text {
    final StringBuffer sb = StringBuffer()
      ..writeln(effectiveTitle)
      ..writeln();
    for (final String row in steps ?? rows) {
      sb.writeln(row);
    }
    if (total != null) {
      sb.writeln('────────────');
      sb.writeln(total);
    }
    return sb.toString().trimRight();
  }
}
