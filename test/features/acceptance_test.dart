import 'package:calcone/features/basic/basic_calculator_screen.dart';
import 'package:calcone/features/basic/widgets/peek_handle.dart';
import 'package:calcone/features/quick_scan/widgets/scan_tile.dart';
import 'package:calcone/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder calcKey(String label) => find.byWidgetPredicate(
      (Widget w) => w is CalcButton && w.label == label,
    );

Future<void> tapKeys(WidgetTester tester, String keys) async {
  for (final String ch in keys.split('')) {
    await tester.tap(calcKey(ch));
    await tester.pump();
  }
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: BasicCalculatorScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('spec §45 acceptance flow', () {
    testWidgets(
        'enter values, evaluate, Quick Scan, edit an entry, total updates',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await pumpApp(tester);

      // 1. Enters 180 + 650 + 1200 + 450 + 320 + 750
      await tapKeys(tester, '180+650+1200+450+320+750');
      await tester.tap(calcKey('='));
      await tester.pumpAndSettle();

      // 2. Gets correct total.
      expect(find.text('3,550'), findsWidgets);

      // 3. Opens Quick Scan via the peek handle.
      await tester.tap(find.byType(PeekHandle));
      await tester.pumpAndSettle();
      expect(find.text('QUICK SCAN'), findsOneWidget);

      // 4. All inputs visible in the grid.
      for (final String v in <String>['180', '650', '450', '320']) {
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is ScanTile && w.entry.result.toString() == v,
          ),
          findsOneWidget,
        );
      }

      // 5-6. Taps 450, edits it to 540.
      await tester.tap(find.byWidgetPredicate(
        (Widget w) => w is ScanTile && w.entry.result.toString() == '450',
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '540');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // 7. Total automatically updates.
      expect(find.text('3,640'), findsWidgets);

      // 8-9. Share opens the clean card sheet (no keypad).
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();
      expect(find.text('SHARE'), findsOneWidget);
      expect(find.text('= 3,640'), findsOneWidget);
    });

    testWidgets('session is offered for restore after a restart',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await pumpApp(tester);

      await tapKeys(tester, '2+2');
      await tester.tap(calcKey('='));
      await tester.pumpAndSettle();
      // Let the debounced auto-save fire.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Simulate an app restart with a fresh widget tree.
      await tester.pumpWidget(Container());
      await pumpApp(tester);

      // 15-16. The restore prompt appears; continuing restores the tape.
      expect(find.text('Continue previous calculation?'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PeekHandle));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is ScanTile && w.entry.result.toString() == '4',
        ),
        findsOneWidget,
      );
    });
  });
}
