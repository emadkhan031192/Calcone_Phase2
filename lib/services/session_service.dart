import 'dart:convert';

import 'package:rational/rational.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_entry.dart';

/// Persists the calculation session on-device (spec §19) and the user's
/// saved numbers (spec §27). Everything stays local — no accounts, no
/// network (spec §35–§37).
///
/// Tape entries are serialized losslessly: a [Rational] is stored as its
/// numerator/denominator pair, never as a rounded decimal string.
class SessionService {
  static const String _tapeKey = 'calcone.session.tape.v1';
  static const String _expressionKey = 'calcone.session.expression.v1';
  static const String _savedNumbersKey = 'calcone.saved-numbers.v1';

  /// Fire-and-forget save of the current session. Callers should not
  /// await this on every keystroke; debounce at the call site.
  Future<void> saveSession(
      List<CalculationEntry> tape, String expression) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      tape.map(_encodeEntry).toList(),
    );
    await prefs.setString(_tapeKey, encoded);
    await prefs.setString(_expressionKey, expression);
  }

  /// Returns the saved tape and in-progress expression. Empty when there
  /// is no saved session (or it can't be decoded).
  Future<({List<CalculationEntry> tape, String expression})>
      loadSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_tapeKey);
    final String expression = prefs.getString(_expressionKey) ?? '';
    if (encoded == null || encoded.isEmpty) {
      return (tape: <CalculationEntry>[], expression: expression);
    }
    try {
      final List<dynamic> decoded = jsonDecode(encoded) as List<dynamic>;
      final List<CalculationEntry> tape = decoded
          .whereType<Map<String, dynamic>>()
          .map(_decodeEntry)
          .whereType<CalculationEntry>()
          .toList();
      return (tape: tape, expression: expression);
    } catch (_) {
      return (tape: <CalculationEntry>[], expression: expression);
    }
  }

  Future<bool> hasSavedSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_tapeKey);
    return encoded != null && encoded.isNotEmpty && encoded != '[]';
  }

  Future<void> clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tapeKey);
    await prefs.remove(_expressionKey);
  }

  Future<List<String>> loadSavedNumbers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedNumbersKey) ?? <String>[];
  }

  Future<void> saveNumber(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> current =
        prefs.getStringList(_savedNumbersKey) ?? <String>[];
    if (!current.contains(value)) {
      current.add(value);
      await prefs.setStringList(_savedNumbersKey, current);
    }
  }

  Future<void> removeSavedNumber(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> current =
        prefs.getStringList(_savedNumbersKey) ?? <String>[];
    current.remove(value);
    await prefs.setStringList(_savedNumbersKey, current);
  }

  Map<String, dynamic> _encodeEntry(CalculationEntry e) => <String, dynamic>{
        'id': e.id,
        'expression': e.expression,
        'n': e.result.numerator.toString(),
        'd': e.result.denominator.toString(),
        'ts': e.timestamp.millisecondsSinceEpoch,
        if (e.label != null) 'label': e.label,
        'pinned': e.isPinned,
      };

  CalculationEntry? _decodeEntry(Map<String, dynamic> m) {
    try {
      final BigInt n = BigInt.parse(m['n'] as String);
      final BigInt d = BigInt.parse(m['d'] as String);
      return CalculationEntry(
        id: m['id'] as String,
        expression: m['expression'] as String,
        result: Rational(n, d),
        timestamp: DateTime.fromMillisecondsSinceEpoch(m['ts'] as int),
        label: m['label'] as String?,
        isPinned: m['pinned'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
