import 'package:flutter/services.dart';

class ScreenUsagePlatformService {
  static const MethodChannel _channel = MethodChannel('laomuqin/screen_usage');

  Future<bool> isUsageAccessGranted() async {
    final granted =
        await _channel.invokeMethod<bool>('isUsageAccessGranted') ?? false;
    return granted;
  }

  Future<void> openUsageAccessSettings() async {
    await _channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<void> scheduleMidnightCollection() async {
    await _channel.invokeMethod<void>('scheduleMidnightCollection');
  }

  Future<Map<Object?, Object?>> getRecentSnapshots({required int days}) async {
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'getRecentSnapshots',
      {'days': days},
    );
    return result ?? <Object?, Object?>{};
  }
}
