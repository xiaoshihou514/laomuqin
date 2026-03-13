package com.github.xiaoshihou.laomuqin

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ScreenUsageBridge.CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isUsageAccessGranted" -> {
                    result.success(ScreenUsageBridge.hasUsageAccess(this))
                }

                "openUsageAccessSettings" -> {
                    ScreenUsageBridge.openUsageAccessSettings(this)
                    result.success(null)
                }

                "scheduleMidnightCollection" -> {
                    ScreenUsageBridge.scheduleNextMidnightCollection(this)
                    result.success(null)
                }

                "getRecentSnapshots" -> {
                    val days = call.argument<Int>("days") ?: 7
                    result.success(ScreenUsageBridge.getRecentSnapshots(this, days))
                }

                else -> result.notImplemented()
            }
        }
    }
}
