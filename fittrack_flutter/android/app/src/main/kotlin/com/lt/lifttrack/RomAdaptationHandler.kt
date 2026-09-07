package com.lt.lifttrack

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RomAdaptationHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.lt.lifttrack/rom_adaptation"

        private val OEM_KEYWORDS = listOf(
            "xiaomi", "redmi", "poco",
            "huawei", "honor",
            "oppo", "realme", "oneplus",
            "vivo", "iqoo",
            "meizu", "samsung"
        )

        fun isOemRom(): Boolean {
            val manufacturer = Build.MANUFACTURER.lowercase()
            return OEM_KEYWORDS.any { manufacturer.contains(it) }
        }

        fun getManufacturer(): String {
            return Build.MANUFACTURER ?: ""
        }

        /**
         * 是否为 HarmonyOS 设备。
         * 用于 Android 包(兼容层)跑在鸿蒙机上的场景：手机扫码(mobile_scanner)在鸿蒙
         * 上无原生实现，应直接走相册兜底，避免弹出相机权限。此处按系统 Build 标记识别，
         * 仅在确为鸿蒙(HarmonyOS)时返回 true；普通华为 EMUI 安卓机不满足标记，仍走相机。
         */
        fun isHarmonyOS(): Boolean {
            val fingerprint = Build.FINGERPRINT?.lowercase() ?: ""
            val display = Build.DISPLAY?.lowercase() ?: ""
            val release = Build.VERSION.RELEASE?.lowercase() ?: ""
            val incremental = Build.VERSION.INCREMENTAL?.lowercase() ?: ""
            val marketing = try {
                Build.VERSION.MARKETING_NAME?.lowercase() ?: ""
            } catch (_: Exception) {
                ""
            }
            Log.d(
                "RomAdaptation", "harmony-detect fingerprint=$fingerprint " +
                    "display=$display release=$release incremental=$incremental " +
                    "marketing=$marketing manufacturer=${Build.MANUFACTURER} model=${Build.MODEL}"
            )
            val hit = listOf(fingerprint, display, release, incremental, marketing)
                .any { it.contains("harmony") || it.contains("鸿蒙") }
            // 鸿蒙的发行名称通常直接为 "HarmonyOS"，SDK 版本号带 3/4/5
            val sdkIsHarmony = release.startsWith("harmonyos")
            if (hit || sdkIsHarmony) {
                Log.d("RomAdaptation", "harmony-detect = true")
            }
            return hit || sdkIsHarmony
        }

        fun getGuidanceTitle(): String {
            val m = Build.MANUFACTURER.lowercase()
            return when {
                m.contains("xiaomi") || m.contains("redmi") || m.contains("poco") -> "小米/红米手机需要手动开启自启动"
                m.contains("huawei") -> "华为手机需要手动开启后台运行"
                m.contains("honor") -> "荣耀手机需要手动开启自启动"
                m.contains("oppo") || m.contains("realme") -> "OPPO/Realme 手机需要手动开启自启动"
                m.contains("oneplus") -> "一加手机需要手动关闭电池优化"
                m.contains("vivo") || m.contains("iqoo") -> "vivo/iQOO 手机需要手动开启自启动"
                m.contains("meizu") -> "魅族手机需要手动开启后台运行"
                m.contains("samsung") -> "三星手机需要关闭电池优化"
                else -> "请确保 LiftTrack 允许后台运行"
            }
        }

        fun getGuidanceSteps(): String {
            val m = Build.MANUFACTURER.lowercase()
            return when {
                m.contains("xiaomi") || m.contains("redmi") || m.contains("poco") ->
                    "1. 长按应用图标 → 应用信息\n2. 省电策略 → 无限制\n3. 自启动 → 允许\n4. 最近任务 → 锁定 LiftTrack"
                m.contains("huawei") ->
                    "1. 设置 → 应用 → 应用启动管理\n2. 找到 LiftTrack\n3. 关闭「自动管理」\n4. 手动管理 → 允许自启动 + 允许后台活动"
                m.contains("honor") ->
                    "1. 设置 → 应用 → 应用启动管理\n2. 找到 LiftTrack\n3. 允许自启动 + 允许后台活动"
                m.contains("oppo") || m.contains("realme") ->
                    "1. 设置 → 应用管理 → LiftTrack\n2. 耗电保护 → 允许后台运行\n3. 自启动管理 → 允许"
                m.contains("oneplus") ->
                    "1. 设置 → 电池 → LiftTrack\n2. 优化电池使用 → 不优化"
                m.contains("vivo") || m.contains("iqoo") ->
                    "1. 设置 → 应用与权限 → 自启动\n2. 允许 LiftTrack 自启动\n3. 设置 → 电池 → 后台高耗电 → 允许"
                m.contains("meizu") ->
                    "1. 设置 → 应用管理 → LiftTrack\n2. 后台管理 → 允许后台运行"
                m.contains("samsung") ->
                    "1. 设置 → 电池 → LiftTrack\n2. 允许后台活动\n3. 不受电池优化限制"
                else -> "请确保 LiftTrack 允许后台运行和自启动"
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isOemRom" -> result.success(isOemRom())
            "getManufacturer" -> result.success(getManufacturer())
            "isHarmonyOS" -> result.success(isHarmonyOS())
            "getGuidanceTitle" -> result.success(getGuidanceTitle())
            "getGuidanceSteps" -> result.success(getGuidanceSteps())
            "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
            "requestIgnoreBatteryOptimizations" -> {
                requestIgnoreBatteryOptimizations()
                result.success(true)
            }
            "openAppSettings" -> {
                openAppSettings()
                result.success(true)
            }
            "openAutoStartSettings" -> {
                openAutoStartSettings()
                result.success(true)
            }
            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        return try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(context.packageName)
        } catch (e: Exception) {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            }
        } catch (e: Exception) {
            try { openAppSettings() } catch (_: Exception) {}
        }
    }

    private fun openAppSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APPLICATIONS_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (_: Exception) {}
        }
    }

    private fun openAutoStartSettings() {
        try {
            val manufacturer = Build.MANUFACTURER.lowercase()
            val intent = Intent().addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            when {
                manufacturer.contains("xiaomi") -> {
                    intent.component = android.content.ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.autostart.AutoStartManagementActivity"
                    )
                }
                manufacturer.contains("huawei") -> {
                    intent.component = android.content.ComponentName(
                        "com.huawei.systemmanager",
                        "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                }
                manufacturer.contains("honor") -> {
                    intent.component = android.content.ComponentName(
                        "com.hihonor.systemmanager",
                        "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity"
                    )
                }
                manufacturer.contains("oppo") || manufacturer.contains("realme") -> {
                    intent.component = android.content.ComponentName(
                        "com.coloros.safecenter",
                        "com.coloros.safecenter.permission.startup.FakeActivity"
                    )
                }
                manufacturer.contains("vivo") || manufacturer.contains("iqoo") -> {
                    intent.component = android.content.ComponentName(
                        "com.iqoo.secure",
                        "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"
                    )
                }
                manufacturer.contains("meizu") -> {
                    intent.component = android.content.ComponentName(
                        "com.meizu.safe",
                        "com.meizu.safe.security.SHOW_APPSEC"
                    )
                    intent.putExtra("packageName", context.packageName)
                }
                else -> { openAppSettings(); return }
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            try { openAppSettings() } catch (_: Exception) {}
        }
    }

    private fun openBatteryOptimizationSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            }
        } catch (e: Exception) {
            try { openAppSettings() } catch (_: Exception) {}
        }
    }
}
