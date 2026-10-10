/// What gets shared (spec §12–§14): a title, content rows, and an
/// optional total line. The same payload renders the image card and the
/// plain-text share, so the two never drift apart.
class SharePayload {
  const SharePayload({
    required this.title,
    required this.rows,
    this.total,
  });

  final String title;
  final List<String> rows;
  final String? total;

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
