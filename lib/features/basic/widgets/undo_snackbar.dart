import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/settings/app_settings.dart';
import '../calculator_controller.dart';

String _undoLabel(AppStrings strings, String key) => switch (key) {
      'inputCleared' => strings.inputCleared,
      'cleared' => strings.cleared,
      'tapeCleared' => strings.tapeCleared,
      'entryDeleted' => strings.entryDeleted,
      'editUndone' => strings.editUndone,
      _ => key,
    };

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
      final AppStrings strings = ref.read(stringsProvider);
      final CalculatorController controller =
          ref.read(calculatorControllerProvider.notifier);
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(_undoLabel(strings, request.label)),
              action: SnackBarAction(
                label: strings.undo,
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
