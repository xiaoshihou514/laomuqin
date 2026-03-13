package com.github.xiaoshihou.laomuqin

import android.app.Service
import android.content.Intent
import android.os.IBinder

class ScreenUsageCollectorService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ScreenUsageBridge.ensureNotificationChannel(this)
        startForeground(
            ScreenUsageBridge.NOTIFICATION_ID,
            ScreenUsageBridge.buildNotification(this),
        )

        Thread {
            try {
                ScreenUsageBridge.collectPreviousDayAndReschedule(this)
            } finally {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf(startId)
            }
        }.start()

        return START_NOT_STICKY
    }
}
