package com.lt.lifttrack

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object AlarmScheduler {

    private const val TAG = "AlarmScheduler"
    private const val REQUEST_CODE = 10001

    fun scheduleRestAlarm(
        context: Context,
        title: String,
        content: String,
        exerciseName: String,
        triggerTimeInSeconds: Long,
        notificationId: Int
    ): Long {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAtMillis = System.currentTimeMillis() + triggerTimeInSeconds * 1000

        // 先取消旧闹钟，再创建带 extras 的新 PendingIntent
        // 注意：必须在创建带 extras 的 PendingIntent 之前调用，否则
        // cancelRestAlarm 中使用 FLAG_NO_CREATE 不会影响新创建的 PI
        cancelRestAlarm(context)

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.lt.lifttrack.REST_ALARM"
            putExtra(AlarmReceiver.EXTRA_TITLE, title)
            putExtra(AlarmReceiver.EXTRA_CONTENT, content)
            putExtra(AlarmReceiver.EXTRA_EXERCISE_NAME, exerciseName)
            putExtra(AlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            // 使用 setAlarmClock：国产 ROM（小米/华为/OPPO/vivo）唯一不会拦截的闹钟 API
            // 1. 被系统视为"用户级闹钟"，不受自启动/电池优化限制
            // 2. Android 12+ 无需 SCHEDULE_EXACT_ALARM 权限
            // 3. 会在状态栏显示闹钟图标（用户可感知）
            val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, null)
            alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.i(TAG, "setAlarmClock scheduled at $triggerAtMillis (${triggerTimeInSeconds}s), title=$title")
        } catch (e: Exception) {
            Log.e(TAG, "setAlarmClock failed, falling back to setAndAllowWhileIdle", e)
            try {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } catch (e2: Exception) {
                Log.e(TAG, "setAndAllowWhileIdle also failed", e2)
            }
        }

        return triggerAtMillis
    }

    fun cancelRestAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.lt.lifttrack.REST_ALARM"
        }

        // 使用 FLAG_NO_CREATE：若 PendingIntent 不存在则返回 null，不创建/不修改已有 PI
        // 避免使用 FLAG_UPDATE_CURRENT 导致已有 PendingIntent 的 extras 被清空
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

        pendingIntent?.let {
            alarmManager.cancel(it)
            Log.i(TAG, "cancelRestAlarm: alarm cancelled")
        }
    }
}
