package com.github.xiaoshihou.laomuqin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class ScreenUsageMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val serviceIntent = Intent(context, ScreenUsageCollectorService::class.java)
        ContextCompat.startForegroundService(context, serviceIntent)
    }
}
