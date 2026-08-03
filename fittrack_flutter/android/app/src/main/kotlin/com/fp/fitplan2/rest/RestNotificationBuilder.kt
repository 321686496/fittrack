// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestNotificationBuilder.kt
package com.fp.fitplan2.rest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.fp.fitplan2.MainActivity
import com.fp.fitplan2.R

object RestNotificationBuilder {
    private const val CHANNEL_ID = "rest_countdown"
    private const val CHANNEL_NAME = "休息倒计时"

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW  // 不发声，只显示
            ).apply {
                description = "组间休息倒计时实况通知"
                setShowBadge(false)
            }
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    fun buildRestNotification(
        context: Context,
        exerciseName: String,
        restEndTimeMs: Long
    ): Notification {
        // 点击跳转回训练页
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            putExtra("targetPage", "training")
            putExtra("cardAction", "resume")
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            context, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // "结束休息"操作
        val skipIntent = Intent(context, RestOngoingService::class.java).apply {
            action = RestOngoingService.ACTION_SKIP_REST
        }
        val skipPendingIntent = PendingIntent.getService(
            context, 1, skipIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 使用 RemoteViews + Chronometer 实现倒计时
        val remoteViews = RemoteViews(context.packageName, R.layout.widget_rest_notification)
        remoteViews.setTextViewText(R.id.rest_exercise_name, exerciseName)

        // 设置 Chronometer 倒计时
        val elapsedRealtime = android.os.SystemClock.elapsedRealtime()
        val restEndElapsed = elapsedRealtime + (restEndTimeMs - System.currentTimeMillis())
        remoteViews.setChronometer(R.id.rest_chronometer, restEndElapsed, null, true)

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(remoteViews)
            .setOngoing(true)
            .setContentIntent(contentPendingIntent)
            .addAction(R.mipmap.ic_launcher, "结束休息", skipPendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .build()
    }

    const val NOTIFICATION_ID = 2001
}
