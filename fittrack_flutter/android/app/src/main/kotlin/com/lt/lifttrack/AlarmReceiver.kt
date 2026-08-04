package com.lt.lifttrack

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "rest_channel"
        const val CHANNEL_NAME = "训练休息提醒"
        const val CHANNEL_DESC = "组间休息结束时的提醒通知"
        const val NOTIFICATION_ID = 1001

        const val EXTRA_TITLE = "title"
        const val EXTRA_CONTENT = "content"
        const val EXTRA_EXERCISE_NAME = "exerciseName"
        const val EXTRA_NOTIFICATION_ID = "notificationId"
    }

    override fun onReceive(context: Context, intent: Intent) {
        android.util.Log.i("AlarmReceiver", "onReceive: action=${intent.action}, extras=${intent.extras}")
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "休息结束"
        val content = intent.getStringExtra(EXTRA_CONTENT) ?: "休息时间到了，继续训练吧！"
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, NOTIFICATION_ID)

        createNotificationChannel(context)
        showNotification(context, notificationId, title, content)
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESC
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 150, 300, 150, 300)
                setShowBadge(true)
            }
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(
        context: Context,
        notificationId: Int,
        title: String,
        content: String
    ) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("targetPage", "training")
            putExtra("cardAction", "resume")
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 300, 150, 300, 150, 300))
            .setContentIntent(pendingIntent)
            .setFullScreenIntent(pendingIntent, true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(notificationId, notification)
    }
}
