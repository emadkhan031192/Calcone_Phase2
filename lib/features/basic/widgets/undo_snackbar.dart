import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calculator_controller.dart';

/// Shows the spec §18 undo snackbar whenever the controller posts an
/// [UndoRequest]. Register once per screen that can trigger destructive
/// actions; only the currently visible route shows it, so the main screen
/// and the Quick Scan sheet never double-present.
void listenForUndo(WidgetRef ref, BuildContext context) {
  ref.listen<UndoRequest?>(
    calculatorControllerProvider.select((s) => s.undoRequest),
    (UndoRequest? previous, UndoRequest? next) {
      if (next == null) return;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      final UndoRequest request = next;
      final CalculatorController controller =
          ref.read(calculatorControllerProvider.notifier);
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(request.label),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: controller.undo,
              ),
            ),
          )
          .closed
          .then((_) {
        // Don't clear a newer request that arrived while this one was up.
        if (identical(
          ref.read(calculatorControllerProvider).undoRequest,
          request,
        )) {
          controller.dismissUndo();
        }
      });
    },
  );
}
