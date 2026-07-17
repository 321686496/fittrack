package com.fp.fitplan

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ALARM_CHANNEL_NAME = "com.fp.fitplan/alarm"
    private var alarmChannel: MethodChannel? = null
    private var romAdaptationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        alarmChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL_NAME)
        alarmChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleRestAlarm" -> {
                    val title = call.argument<String>("title") ?: "休息结束"
                    val content = call.argument<String>("content") ?: ""
                    val exerciseName = call.argument<String>("exerciseName") ?: ""
                    val triggerTimeInSeconds = call.argument<Int>("triggerTimeInSeconds")?.toLong() ?: 0L
                    val notificationId = call.argument<Int>("notificationId") ?: 1001

                    try {
                        val triggerAt = AlarmScheduler.scheduleRestAlarm(
                            context = this@MainActivity,
                            title = title,
                            content = content,
                            exerciseName = exerciseName,
                            triggerTimeInSeconds = triggerTimeInSeconds,
                            notificationId = notificationId
                        )
                        result.success(triggerAt)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                "cancelRestAlarm" -> {
                    try {
                        AlarmScheduler.cancelRestAlarm(this@MainActivity)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "cancelAllAlarms" -> {
                    try {
                        AlarmScheduler.cancelRestAlarm(this@MainActivity)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        romAdaptationChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            RomAdaptationHandler.CHANNEL_NAME
        )
        romAdaptationChannel?.setMethodCallHandler(RomAdaptationHandler(this))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        intent ?: return
        val targetPage = intent.getStringExtra("targetPage")
        val cardAction = intent.getStringExtra("cardAction")

        if (targetPage != null || cardAction != null) {
            val params = HashMap<String, Any>()
            targetPage?.let { params["targetPage"] = it }
            cardAction?.let { params["cardAction"] = it }

            alarmChannel?.invokeMethod("onCardClick", params)
        }
    }
}
