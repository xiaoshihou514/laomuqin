import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/task.dart';

class ExportService {
  Future<String> exportTasksToDownloads(List<Task> tasks) async {
    final downloadsDir = await _resolveDownloadsDirectory();
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(downloadsDir.path, 'laomuqin_tasks_$timestamp.json'));
    final payload = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'taskCount': tasks.length,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };

    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  Future<Directory> _resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final externalDirs = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (externalDirs != null && externalDirs.isNotEmpty) {
        return externalDirs.first;
      }

      final fallback = Directory('/storage/emulated/0/Download');
      if (await fallback.exists()) {
        return fallback;
      }

      throw const FileSystemException('Downloads directory is unavailable');
    }

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }

    throw const FileSystemException('Downloads directory is unavailable');
  }
}
