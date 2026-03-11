import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/asr_setting.dart';
import '../../l10n/app_localizations.dart';
import '../main/widgets/model_download_dialog.dart';
import 'settings_viewmodel.dart';

/// ASR model configuration page.
///
/// Lets the user pick one of the built-in presets and auto-download the model
/// files.  Already-downloaded models show a ✓ badge and skip re-downloading.
class AsrSettingsPage extends StatefulWidget {
  const AsrSettingsPage({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  State<AsrSettingsPage> createState() => _AsrSettingsPageState();
}

class _AsrSettingsPageState extends State<AsrSettingsPage> {
  int _selectedPreset = 0;
  bool _saving = false;
  String? _destDir;

  @override
  void initState() {
    super.initState();
    _loadDestDir();
    _loadExisting();
  }

  Future<void> _loadDestDir() async {
    final dir = await getApplicationSupportDirectory();
    if (mounted) setState(() => _destDir = dir.path);
  }

  void _loadExisting() {
    final json = widget.viewModel.asrModelSettingsJson;
    if (json == null) return;
    try {
      final s = AsrSetting.fromJson(json);
      final idx = kAsrPresets.indexWhere((p) => p.modelType == s.modelType);
      if (idx >= 0) setState(() => _selectedPreset = idx);
    } catch (_) {}
  }

  AsrPreset get _preset => kAsrPresets[_selectedPreset];

  bool _isDownloaded(AsrPreset preset) {
    if (_destDir == null) return false;
    return preset.isDownloaded(_destDir!);
  }

  Future<void> _downloadAndSave(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final destDir = _destDir;
    if (destDir == null) return;
    final preset = _preset;

    // Capture messenger before any async gaps.
    final messenger = ScaffoldMessenger.of(context);

    final url = preset.githubUrl;

    if (!preset.isDownloaded(destDir)) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ModelDownloadDialog(urls: [url], destDir: destDir),
      );
      if (ok != true) return;
    }

    setState(() => _saving = true);
    final setting = preset.buildSetting(destDir);
    await widget.viewModel.saveAsrModelSettings.execute(setting.toJson());
    if (mounted) {
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.asrSettingsSaved)));
    }
  }

  void _reset() {
    widget.viewModel.saveAsrModelSettings.execute(null);
    setState(() => _selectedPreset = 0);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.asrSettingsReset)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.asrSettingsTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: l10n.asrSettingsReset,
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.asrSettingsSelectPreset,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...kAsrPresets.asMap().entries.map((entry) {
              final idx = entry.key;
              final preset = entry.value;
              final isSelected = idx == _selectedPreset;
              final downloaded = _isDownloaded(preset);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: isSelected ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedPreset = idx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    preset.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  if (downloaded) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.download_done,
                                      size: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                preset.desc,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            // Size / download info
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.asrSettingsDownloadHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_saving || _destDir == null)
                  ? null
                  : () => _downloadAndSave(context, l10n),
              icon: Icon(
                _isDownloaded(_preset) ? Icons.check : Icons.download_outlined,
              ),
              label: Text(
                _isDownloaded(_preset)
                    ? l10n.asrSaveAndDownload
                    : l10n.asrSaveAndDownload,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.asrSettingsReset),
            ),
          ],
        ),
      ),
    );
  }
}
