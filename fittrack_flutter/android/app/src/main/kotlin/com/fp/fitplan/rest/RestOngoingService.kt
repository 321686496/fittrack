// fittrack_flutter/android/app/src/main/kotlin/com/fp/fitplan/rest/RestOngoingService.kt
package com.fp.fitplan.rest

import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationManagerCompat

class RestOngoingService : Service() {

    companion object {
        const val ACTION_START_REST = "com.fp.fitplan.action.START_REST"
        const val ACTION_STOP_REST = "com.fp.fitplan.action.STOP_REST"
        const val ACTION_SKIP_REST = "com.fp.fitplan.action.SKIP_REST"

        const val EXTRA_EXERCISE_NAME = "exercise_name"
        const val EXTRA_REST_END_TIME = "rest_end_time"

        // 静态状态，供 MethodChannel 访问
        @Volatile
        var isRunning = false
            private set
    }

    override fun onCreate() {
        super.onCreate()
        RestNotificationBuilder.createChannel(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_REST -> {
                val exerciseName = intent.getStringExtra(EXTRA_EXERCISE_NAME) ?: ""
                val restEndTimeMs = intent.getLongExtra(EXTRA_REST_END_TIME, 0L)

                val notification = RestNotificationBuilder.buildRestNotification(
                    this, exerciseName, restEndTimeMs
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        RestNotificationBuilder.NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                    )
                } else {
                    startForeground(RestNotificationBuilder.NOTIFICATION_ID, notification)
                }
                isRunning = true
            }
            ACTION_STOP_REST -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                NotificationManagerCompat.from(this)
                    .cancel(RestNotificationBuilder.NOTIFICATION_ID)
                isRunning = false
                stopSelf()
            }
            ACTION_SKIP_REST -> {
                // 通过 broadcast 通知 Flutter 侧 skipRest
                // MainActivity 的 alarm channel 会接收到 onCardClick
                val skipIntent = Intent("com.fp.fitplan.REST_ALARM").apply {
                    putExtra("targetPage", "training")
                    putExtra("cardAction", "skipRest")
                    setPackage(packageName)
                }
                sendBroadcast(skipIntent)
                stopForeground(STOP_FOREGROUND_REMOVE)
                NotificationManagerCompat.from(this)
                    .cancel(RestNotificationBuilder.NOTIFICATION_ID)
                isRunning = false
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
