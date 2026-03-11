import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import 'asr_settings_page.dart';
import 'settings_viewmodel.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SettingsView();
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewModel = context.watch<SettingsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    Widget sectionCard(List<Widget> tiles) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: tiles),
        );

    Widget divider() => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: colorScheme.outlineVariant.withAlpha(128),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ASR section
          sectionCard([
            ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => SwitchListTile(
                title: Text(l10n.settingsAsr),
                subtitle: Text(
                  l10n.settingsAsrDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                value: viewModel.asrEnabled,
                onChanged: (_) => viewModel.toggleAsr.execute(),
              ),
            ),
            if (viewModel.asrEnabled) ...[
              divider(),
              ListTile(
                title: Text(l10n.settingsAsrModel),
                subtitle: Text(
                  l10n.settingsAsrModelDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AsrSettingsPage(viewModel: viewModel),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          // Theme section
          sectionCard([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTheme,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  ListenableBuilder(
                    listenable: viewModel,
                    builder: (_, _) => _ThemeModeSelector(
                      current: viewModel.themeMode,
                      onChanged: (mode) =>
                          viewModel.setThemeMode.execute(mode),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.current,
    required this.onChanged,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    Widget option(ThemeMode mode, String label, IconData icon) {
      final selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(ThemeMode.system, l10n.settingsThemeSystem,
            Icons.brightness_auto_outlined),
        const SizedBox(width: 8),
        option(ThemeMode.light, l10n.settingsThemeLight,
            Icons.light_mode_outlined),
        const SizedBox(width: 8),
        option(ThemeMode.dark, l10n.settingsThemeDark,
            Icons.dark_mode_outlined),
      ],
    );
  }
}


