import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';

/// Settings bottom sheet (burger menu): font size, font weight,
/// language, theme, haptics, and Tape chip operators.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext ctx) => const _SettingsSheetBody(),
  );
}

class _SettingsSheetBody extends ConsumerWidget {
  const _SettingsSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final AppStrings s = ref.watch(stringsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.settings,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _SectionLabel(s.fontSize),
            _Segmented(
              labels: <String>[s.small, s.medium, s.large],
              selected: settings.fontSize,
              onSelect: notifier.setFontSize,
            ),
            const SizedBox(height: 12),
            _SectionLabel(s.fontWeight),
            _Segmented(
              labels: <String>[s.regular, s.medium, s.bold],
              selected: settings.fontWeight,
              onSelect: notifier.setFontWeight,
            ),
            const SizedBox(height: 12),
            _SectionLabel(s.language),
            _Segmented(
              labels: const <String>['English', 'اردو'],
              selected: settings.language == 'en' ? 0 : 1,
              onSelect: (int i) => notifier.setLanguage(i == 0 ? 'en' : 'ur'),
            ),
            const SizedBox(height: 12),
            _SectionLabel(s.theme),
            _Segmented(
              labels: <String>[s.system, s.light, s.dark],
              selected: settings.themeMode.index,
              onSelect: (int i) => notifier.setTheme(ThemeMode.values[i]),
            ),
            const SizedBox(height: 8),
            _SwitchRow(
              label: s.haptics,
              value: settings.haptics,
              onChanged: notifier.setHaptics,
            ),
            _SwitchRow(
              label: s.showChipOperators,
              value: settings.showChipOperators,
              onChanged: notifier.setShowChipOperators,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: p.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// A pill segmented control with 48dp touch targets.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final CalcPalette p = Theme.of(context).extension<CalcPalette>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: p.keyNumber,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                label: labels[i],
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    height: CalcDims.minTouchTarget,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? scheme.primary : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labels[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight:
                            i == selected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            i == selected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
