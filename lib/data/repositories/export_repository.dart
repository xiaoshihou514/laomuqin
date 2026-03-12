import '../../utils/command.dart';
import '../models/task.dart';
import '../services/export_service.dart';

class ExportRepository {
  ExportRepository(this._service);

  final ExportService _service;

  Future<Result<String>> exportTasksToDownloads(List<Task> tasks) async {
    try {
      final path = await _service.exportTasksToDownloads(tasks);
      return Result.ok(path);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
