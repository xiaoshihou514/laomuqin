import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Progress for a single file download.
class FileProgress {
  const FileProgress({
    required this.url,
    required this.stage,
    this.percent = 0,
  });

  final String url;
  final DownloadStage stage;

  /// 0–100
  final double percent;
}

enum DownloadStage { downloading, extracting, done, failed }

typedef ProgressCallback = void Function(List<FileProgress> progress);

/// Stateless service for downloading and extracting model archives.
abstract class DownloadService {
  /// Downloads each URL in [urls] to a temporary directory, then extracts
  /// archives into [destDir].
  ///
  /// Already-downloaded files (token file present) are skipped.
  /// Calls [onProgress] whenever any file's stage/percent changes.
  static Future<void> downloadAndExtract({
    required List<String> urls,
    required String destDir,
    required ProgressCallback onProgress,
  }) async {
    final tmp = await getApplicationCacheDirectory();
    final dest = Directory(destDir);
    if (!dest.existsSync()) dest.createSync(recursive: true);

    final progress = List<FileProgress>.generate(
      urls.length,
      (i) => FileProgress(url: urls[i], stage: DownloadStage.downloading),
    );

    final dio = Dio();

    for (final (i, url) in urls.indexed) {
      final base = p.basename(url);
      final tmpPath = p.join(tmp.path, base);
      final tmpFile = File(tmpPath);

      // Clean up stale partial downloads.
      if (tmpFile.existsSync()) tmpFile.deleteSync();

      try {
        await dio.download(
          url,
          tmpPath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final pct = (received / total * 10000).truncateToDouble() / 100;
              progress[i] = FileProgress(
                url: url,
                stage: DownloadStage.downloading,
                percent: pct,
              );
              onProgress(List.unmodifiable(progress));
            }
          },
        );

        // Extract if archive, otherwise just move.
        if (_isArchive(base)) {
          progress[i] = FileProgress(
            url: url,
            stage: DownloadStage.extracting,
            percent: 100,
          );
          onProgress(List.unmodifiable(progress));

          await extractFileToDisk(tmpPath, destDir);
        } else {
          File(tmpPath).renameSync(p.join(destDir, base));
        }

        // Clean up temp file.
        if (tmpFile.existsSync()) tmpFile.deleteSync();

        progress[i] = FileProgress(
          url: url,
          stage: DownloadStage.done,
          percent: 100,
        );
        onProgress(List.unmodifiable(progress));
      } catch (e) {
        progress[i] = FileProgress(
          url: url,
          stage: DownloadStage.failed,
          percent: progress[i].percent,
        );
        onProgress(List.unmodifiable(progress));
        rethrow;
      }
    }
  }

  static bool _isArchive(String filename) {
    const exts = [
      'tar.gz', 'tgz', 'tar.bz2', 'tbz', 'tar.xz', 'txz', 'tar', 'zip',
    ];
    return exts.any((e) => filename.endsWith(e));
  }
}
