package com.lt.lifttrack

import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.lt.lifttrack.rest.RestOngoingService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val ALARM_CHANNEL_NAME = "com.lt.lifttrack/alarm"
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

        // LiveView Channel（休息倒计时前台服务）
        val liveViewChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.lt.lifttrack/liveview"
        )
        liveViewChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startRestLiveView" -> {
                    val exerciseName = call.argument<String>("exerciseName") ?: ""
                    // C1 修复：Dart 侧传入的 millisecondsSinceEpoch 约 1.78e12，超出 Int32.MAX，
                    // StandardMessageCodec 以 INT64 编码，Android 侧解码为 java.lang.Long，
                    // 必须用 call.argument<Long> 接收，否则 ClassCastException 或 null → 0L。
                    val restEndTimeMs = call.argument<Long>("restEndTimeMs") ?: 0L
                    val intent = Intent(this@MainActivity, RestOngoingService::class.java).apply {
                        action = RestOngoingService.ACTION_START_REST
                        putExtra(RestOngoingService.EXTRA_EXERCISE_NAME, exerciseName)
                        putExtra(RestOngoingService.EXTRA_REST_END_TIME, restEndTimeMs)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopRestLiveView" -> {
                    val intent = Intent(this@MainActivity, RestOngoingService::class.java).apply {
                        action = RestOngoingService.ACTION_STOP_REST
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Widget Channel（桌面卡片数据推送）
        val widgetChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.lt.lifttrack/widget"
        )
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "pushCardData" -> {
                    val jsonStr = call.arguments as? String
                    if (jsonStr != null) {
                        com.lt.lifttrack.widget.WidgetDataStore.saveState(this@MainActivity, jsonStr)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Expected JSON string", null)
                    }
                }
                "clearCardData" -> {
                    com.lt.lifttrack.widget.WidgetDataStore.clearState(this@MainActivity)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
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

        // 处理 fittrack://invite URL
        val data = intent.data
        if (data != null && data.scheme == "fittrack" && data.host == "invite") {
            val messenger = flutterEngine?.dartExecutor?.binaryMessenger
            if (messenger != null) {
                val inviteChannel = MethodChannel(messenger, "com.lt.lifttrack/invite")
                inviteChannel.invokeMethod("onInviteUrl", data.toString())
            }
        }

        // 处理通知点击（targetPage / cardAction）
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
