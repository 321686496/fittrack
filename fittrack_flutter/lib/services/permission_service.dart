import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限管理服务 - 集中处理 HarmonyOS 权限申请与状态检查
class PermissionService {
  PermissionService._();

  /// 是否为支持权限处理的平台（移动端 + HarmonyOS）
  static bool get _isPermissionPlatform {
    print("kis web: $kIsWeb");
    final isOhos=Platform.isOhos;
    print("platform is harmony: $isOhos");
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isFuchsia || Platform.isOhos;
  }

  /// 请求通知权限，返回是否已授予
  static Future<bool> requestNotification() async {
    print("start check notification permission....");
    if (!_isPermissionPlatform) return true;
    try {
      final status = await Permission.notification.status;
      print("notification permission is $status");
      if (status.isGranted) return true;
      final result = await Permission.notification.request();
      print("notification permission is $result");
      if (result.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      print("check notification permission.... $result.isGranted");
      return result.isGranted;
    } catch (_) {
      print("check notification permission not permission...., $_");
      return false;
    }
  }

  /// 检查通知权限是否已授予
  static Future<bool> isNotificationGranted() async {
    if (!_isPermissionPlatform) return true;
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// 应用启动时请求核心权限（通知）
  /// 注意：振动权限只需在 module.json5 中声明即可，
  /// HapticFeedback 不需要运行时权限申请
  static Future<void> requestCorePermissions() async {
    if (!_isPermissionPlatform) return;
    try {
      await [Permission.notification].request();
    } catch (_) {
      // 不支持的平台静默忽略
    }
  }

  /// 显示权限被拒绝的提示对话框
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
    required String reason,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionName权限被拒绝'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (_isPermissionPlatform) {
                try {
                  await openAppSettings();
                } catch (_) {}
              }
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}
