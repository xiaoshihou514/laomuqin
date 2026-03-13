import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestNotification() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  Future<bool> isNotificationGranted() async {
    return Permission.notification.isGranted;
  }

  Future<bool> isIgnoreBatteryOptimizationsGranted() async {
    return Permission.ignoreBatteryOptimizations.isGranted;
  }
}
