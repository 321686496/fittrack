package com.lt.lifttrack

import android.content.Context
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 持久设备标识通道
 *
 * 返回 Settings.Secure.ANDROID_ID：同签名 + 同账户 + 同设备下稳定，
 * 卸载重装后保持不变（用于邀请码防刷：设备身份跨重装不变）。
 * 调用方在底层不可用时（如返回空）回退到本地随机 deviceId。
 */
class DeviceIdentityHandler(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL_NAME = "com.lt.lifttrack/device_identity"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPersistentDeviceId" -> result.success(getPersistentDeviceId())
            else -> result.notImplemented()
        }
    }

    private fun getPersistentDeviceId(): String {
        return try {
            Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: ""
        } catch (e: Exception) {
            ""
        }
    }
}