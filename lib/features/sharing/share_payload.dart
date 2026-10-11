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
  });

  final String title;
  final List<String> rows;
  final String? total;

  /// The full expression with display glyphs, rendered with blue
  /// operators on the branded card.
  final String? expression;

  /// Number of tape entries (shows the "N ENTRIES" chip on the card).
  final int? entryCount;

  String get text {
    final StringBuffer sb = StringBuffer()
      ..writeln(title)
      ..writeln();
    for (final String row in rows) {
      sb.writeln(row);
    }
    if (total != null) {
      sb.writeln('────────────');
      sb.writeln(total);
    }
    return sb.toString().trimRight();
  }
}
