import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../data/services/download_service.dart';
import '../../../l10n/app_localizations.dart';

/// Dialog that downloads and extracts model archives with progress indicators.
///
/// Returns `true` via [Navigator.pop] when all files are successfully downloaded.
/// Returns `false` or `null` on error/dismiss.
class ModelDownloadDialog extends StatefulWidget {
  const ModelDownloadDialog({
    super.key,
    required this.urls,
    required this.destDir,
  });

  final List<String> urls;
  final String destDir;

  @override
  State<ModelDownloadDialog> createState() => _ModelDownloadDialogState();
}

class _ModelDownloadDialogState extends State<ModelDownloadDialog> {
  List<FileProgress> _progress = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _progress = widget.urls
        .map((u) => FileProgress(url: u, stage: DownloadStage.downloading))
        .toList();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      await DownloadService.downloadAndExtract(
        urls: widget.urls,
        destDir: widget.destDir,
        onProgress: (list) {
          if (mounted) setState(() => _progress = list);
        },
      );
    } catch (e) {
      print(e);
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  bool get _allDone =>
      _progress.isNotEmpty &&
      _progress.every((fp) => fp.stage == DownloadStage.done);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = _errorMessage != null;

    return AlertDialog(
      title: Text(l10n.downloadTitle),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasError) ...[
              Icon(Icons.error_outline, color: colorScheme.error, size: 36),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ] else
              ..._progress.map((fp) => _ProgressRow(fp: fp, l10n: l10n)),
          ],
        ),
      ),
      actions: [
        if (_allDone || hasError)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_allDone),
            child: Text(l10n.downloadDismiss),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.fp, required this.l10n});

  final FileProgress fp;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseName = p.basename(fp.url);
    final short = baseName.length > 28
        ? '${baseName.substring(0, 12)}...${baseName.substring(baseName.length - 12)}'
        : baseName;

    final label = switch (fp.stage) {
      DownloadStage.downloading => l10n.downloadPerc(short, fp.percent),
      DownloadStage.extracting => l10n.downloadExtracting,
      DownloadStage.done => l10n.downloadDone,
      DownloadStage.failed => '失败',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: fp.percent / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(
              fp.stage == DownloadStage.done
                  ? colorScheme.primary
                  : colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
