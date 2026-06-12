import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限管理服务 - 集中处理 HarmonyOS 权限申请与状态检查
class PermissionService {
  PermissionService._();

  /// 请求通知权限，返回是否已授予
  static Future<bool> requestNotification() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final result = await Permission.notification.request();
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return result.isGranted;
  }

  /// 检查通知权限是否已授予
  static Future<bool> isNotificationGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// 应用启动时请求核心权限（通知）
  /// 注意：振动权限只需在 module.json5 中声明即可，
  /// HapticFeedback 不需要运行时权限申请
  static Future<void> requestCorePermissions() async {
    await [Permission.notification].request();
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
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }
}
