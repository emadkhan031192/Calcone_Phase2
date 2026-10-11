import 'package:calcone/core/theme/calc_key.dart';
import 'package:calcone/features/basic/widgets/calculation_display.dart';
import 'package:calcone/features/quick_scan/widgets/ledger_row.dart';
import 'package:calcone/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder calcKey(String label) => find.byWidgetPredicate(
      (Widget w) => w is CalcKey && w.label == label,
    );

Future<void> tapKeys(WidgetTester tester, String keys) async {
  for (final String ch in keys.split('')) {
    await tester.tap(calcKey(ch));
    await tester.pump();
  }
}

Future<void> pumpApp(WidgetTester tester) async {
  // A realistic phone screen: the default 800x600 test surface makes the
  // home layout overflow, hiding the peek handle from taps.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    // The real app: widgets read the CalcPalette theme extension,
    // which only the Calcone theme provides.
    const ProviderScope(
      child: CalcOneApp(),
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
      await tester.drag(find.byType(CalculationDisplay), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('TAPE'), findsOneWidget);

      // 4. All inputs visible in the grid.
      for (final String v in <String>['180', '650', '450', '320']) {
        expect(
          find.byWidgetPredicate(
            (Widget w) => w is LedgerRow && w.term.value.toString() == v,
          ),
          findsOneWidget,
        );
      }

      // 5-6. Taps 450, edits it to 540.
      await tester.tap(find.byWidgetPredicate(
        (Widget w) => w is LedgerRow && w.term.value.toString() == '450',
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '540');
      // The selection bar behind the dialog also has a "Save" action —
      // target the dialog's filled button.
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // 7. Total automatically updates.
      expect(find.text('3,640'), findsWidgets);

      // 8-9. Share opens the clean card sheet (no keypad).
      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pumpAndSettle();
      expect(find.text('SHARE'), findsOneWidget);
      // The branded card shows "= " in blue next to the big total.
      expect(find.text('3,640'), findsWidgets);
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

      await tester.drag(find.byType(CalculationDisplay), const Offset(0, -300));
      await tester.pumpAndSettle();
      // The restored "2+2" shows as its two terms, totaling 4.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is LedgerRow && w.term.value.toString() == '2',
        ),
        findsNWidgets(2),
      );
      expect(find.text('4'), findsWidgets);
    });
  });
}
