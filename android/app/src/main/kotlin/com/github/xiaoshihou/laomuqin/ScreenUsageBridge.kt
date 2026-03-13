package com.github.xiaoshihou.laomuqin

import android.app.AlarmManager
import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

object ScreenUsageBridge {
    const val CHANNEL_NAME = "laomuqin/screen_usage"
    private const val PREFS_NAME = "screen_usage_snapshots"
    private const val PREF_KEY = "daily_snapshots"
    private const val NOTIFICATION_CHANNEL_ID = "screen_usage_collection"
    const val NOTIFICATION_ID = 42002

    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun openUsageAccessSettings(activity: MainActivity) {
        activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    fun scheduleNextMidnightCollection(context: Context) {
        if (!hasUsageAccess(context)) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, ScreenUsageMidnightReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val nextMidnight = ZonedDateTime.now()
            .plusDays(1)
            .toLocalDate()
            .atStartOfDay(ZoneId.systemDefault())
            .plusMinutes(1)
            .toInstant()
            .toEpochMilli()

        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            nextMidnight,
            pendingIntent,
        )
    }

    fun collectPreviousDayAndReschedule(context: Context) {
        if (hasUsageAccess(context)) {
            val todayStart = startOfDay(System.currentTimeMillis())
            val previousDayStart = todayStart.minusDays(1)
            val snapshot = queryDaySnapshot(
                context,
                previousDayStart.toInstant().toEpochMilli(),
                todayStart.toInstant().toEpochMilli(),
            )
            val snapshots = loadStoredSnapshots(context).associateBy { it.dayStartEpochMs }.toMutableMap()
            snapshots[snapshot.dayStartEpochMs] = snapshot
            saveStoredSnapshots(context, snapshots.values.toList())
        }
        scheduleNextMidnightCollection(context)
    }

    fun getRecentSnapshots(context: Context, days: Int): Map<String, Any> {
        if (!hasUsageAccess(context)) {
            return mapOf("granted" to false, "snapshots" to emptyList<Map<String, Any>>())
        }

        val snapshotsByDay = loadStoredSnapshots(context)
            .associateBy { it.dayStartEpochMs }
            .toMutableMap()
        val recentDays = recentDayStarts(days)
        val now = System.currentTimeMillis()

        for (dayStart in recentDays) {
            val dayStartMs = dayStart.toInstant().toEpochMilli()
            val dayEndMs = if (dayStart == startOfDay(now)) {
                now
            } else {
                dayStart.plusDays(1).toInstant().toEpochMilli()
            }
            val existing = snapshotsByDay[dayStartMs]
            if (existing == null || dayStart == startOfDay(now)) {
                snapshotsByDay[dayStartMs] = queryDaySnapshot(context, dayStartMs, dayEndMs)
            }
        }

        saveStoredSnapshots(context, snapshotsByDay.values.toList())

        return mapOf(
            "granted" to true,
            "snapshots" to recentDays.mapNotNull { day ->
                snapshotsByDay[day.toInstant().toEpochMilli()]?.toMap()
            },
        )
    }

    fun buildNotification(context: Context) =
        NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(context.getString(R.string.screen_usage_notification_title))
            .setContentText(context.getString(R.string.screen_usage_notification_text))
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    fun ensureNotificationChannel(context: Context) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID) != null) return

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            context.getString(R.string.screen_usage_notification_channel_name),
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = context.getString(R.string.screen_usage_notification_channel_desc)
        manager.createNotificationChannel(channel)
    }

    private fun queryDaySnapshot(
        context: Context,
        startMs: Long,
        endMs: Long,
    ): StoredScreenUsageDaySnapshot {
        val usageStatsManager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val rawStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startMs,
            endMs,
        )
        val aggregated = mutableMapOf<String, Long>()
        for (stat in rawStats) {
            val totalTime = totalForegroundTime(stat)
            if (totalTime <= 0L) continue
            aggregated[stat.packageName] = (aggregated[stat.packageName] ?: 0L) + totalTime
        }
        val entries = aggregated.entries
            .filter { it.value > 0L }
            .sortedByDescending { it.value }
            .map { (packageName, totalForegroundMs) ->
                StoredScreenUsageAppEntry(
                    packageName = packageName,
                    appLabel = resolveAppLabel(context, packageName),
                    totalForegroundMs = totalForegroundMs,
                )
            }
        return StoredScreenUsageDaySnapshot(
            dayStartEpochMs = startMs,
            totalForegroundMs = entries.sumOf { it.totalForegroundMs },
            entries = entries,
        )
    }

    private fun totalForegroundTime(stat: UsageStats): Long {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            stat.totalTimeVisible.takeIf { it > 0L } ?: stat.totalTimeInForeground
        } else {
            stat.totalTimeInForeground
        }
    }

    private fun resolveAppLabel(context: Context, packageName: String): String {
        return try {
            val appInfo = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: PackageManager.NameNotFoundException) {
            packageName
        }
    }

    private fun loadStoredSnapshots(context: Context): List<StoredScreenUsageDaySnapshot> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREF_KEY, null) ?: return emptyList()
        val array = JSONArray(raw)
        return List(array.length()) { index ->
            StoredScreenUsageDaySnapshot.fromJson(array.getJSONObject(index))
        }
    }

    private fun saveStoredSnapshots(
        context: Context,
        snapshots: List<StoredScreenUsageDaySnapshot>,
    ) {
        val sorted = snapshots.sortedBy { it.dayStartEpochMs }
        val array = JSONArray()
        sorted.forEach { array.put(it.toJson()) }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PREF_KEY, array.toString())
            .apply()
    }

    private fun startOfDay(epochMs: Long): ZonedDateTime {
        return Instant.ofEpochMilli(epochMs)
            .atZone(ZoneId.systemDefault())
            .toLocalDate()
            .atStartOfDay(ZoneId.systemDefault())
    }

    private fun recentDayStarts(days: Int): List<ZonedDateTime> {
        val today = startOfDay(System.currentTimeMillis())
        return List(days) { index ->
            today.minusDays((days - index - 1).toLong())
        }
    }
}

data class StoredScreenUsageAppEntry(
    val packageName: String,
    val appLabel: String,
    val totalForegroundMs: Long,
) {
    fun toJson() = JSONObject()
        .put("packageName", packageName)
        .put("appLabel", appLabel)
        .put("totalForegroundMs", totalForegroundMs)

    fun toMap(): Map<String, Any> = mapOf(
        "packageName" to packageName,
        "appLabel" to appLabel,
        "totalForegroundMs" to totalForegroundMs,
    )

    companion object {
        fun fromJson(json: JSONObject) = StoredScreenUsageAppEntry(
            packageName = json.getString("packageName"),
            appLabel = json.getString("appLabel"),
            totalForegroundMs = json.getLong("totalForegroundMs"),
        )
    }
}

data class StoredScreenUsageDaySnapshot(
    val dayStartEpochMs: Long,
    val totalForegroundMs: Long,
    val entries: List<StoredScreenUsageAppEntry>,
) {
    fun toJson() = JSONObject()
        .put("dayStartEpochMs", dayStartEpochMs)
        .put("totalForegroundMs", totalForegroundMs)
        .put(
            "entries",
            JSONArray().apply { entries.forEach { put(it.toJson()) } },
        )

    fun toMap(): Map<String, Any> = mapOf(
        "dayStartEpochMs" to dayStartEpochMs,
        "totalForegroundMs" to totalForegroundMs,
        "entries" to entries.map { it.toMap() },
    )

    companion object {
        fun fromJson(json: JSONObject): StoredScreenUsageDaySnapshot {
            val entriesJson = json.getJSONArray("entries")
            val entries = List(entriesJson.length()) { index ->
                StoredScreenUsageAppEntry.fromJson(entriesJson.getJSONObject(index))
            }
            return StoredScreenUsageDaySnapshot(
                dayStartEpochMs = json.getLong("dayStartEpochMs"),
                totalForegroundMs = json.getLong("totalForegroundMs"),
                entries = entries,
            )
        }
    }
}
