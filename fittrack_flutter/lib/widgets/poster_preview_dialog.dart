import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../services/permission_service.dart';
import '../services/poster_share_service.dart';
import '../themes/app_themes.dart';
import '../utils/platform_utils.dart';
import 'common_widgets.dart';

/// 海报预览统一弹窗
///
/// 提供三个能力：
/// 1. 居中展示 PNG 海报图片（卡片样式，圆角 + 内边距 + 阴影）
/// 2. 保存按钮：Android/iOS 走 `image_gallery_saver`；OHOS 走 MethodChannel
///    调用原生 `photoAccessHelper` 保存到系统相册
/// 3. 分享按钮：Android/iOS 走 `share_plus`；OHOS 走 MethodChannel 调用原生系统分享
///
/// 布局说明：
/// - 外层 Dialog 透明，内层是单一卡片容器（统一圆角 + 阴影 + bgCard 背景）
/// - 海报图片用 ConstrainedBox 限制最大高度，避免长海报在小屏上垂直溢出
/// - 底部按钮内容用 FittedBox(scaleDown) 包裹，窄屏自动缩小，避免水平 Overflow
class PosterPreviewDialog {
  PosterPreviewDialog._();

  /// 弹出海报预览弹窗
  ///
  /// [imagePath] PNG 文件绝对路径
  /// [title] 弹窗顶部标题
  static Future<void> show(
    BuildContext context, {
    required String imagePath,
    required String title,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final ft = Theme.of(ctx).extension<LiftTrackColors>()!;
        final mediaSize = MediaQuery.of(ctx).size;
        // 海报图片最大高度 = 屏幕高度 - 标题栏 - 底部按钮区 - 内边距
        final maxImageHeight = mediaSize.height - 220;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            // 统一卡片容器：圆角 + 阴影 + bgCard 背景
            decoration: BoxDecoration(
              color: ft.bgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 顶部：标题 + 关闭按钮 ──────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: ft.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: ft.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                // ── 中间：海报图片预览（卡片内嵌套，圆角 + 内边距）
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: maxImageHeight > 0 ? maxImageHeight : 400,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // ── 底部：两个操作按钮 ────────────────
                // 使用 FittedBox(scaleDown) 包裹内容，避免窄屏文本溢出
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _saveToGallery(ctx, imagePath),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ft.purpleColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_rounded,
                                    color: ft.purpleColor, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '保存到相册',
                                  style: TextStyle(color: ft.purpleColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _shareToPlatform(ctx, imagePath),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ft.purpleColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.share_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('分享', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 保存海报到相册
  ///
  /// 权限策略：
  /// - OHOS: 首次保存时通过 MethodChannel 请求 WRITE_IMAGEVIDEO 权限；
  ///   用户拒绝则提示去「设置」开启，不再重复弹窗。
  /// - Android (API < 29): 需 REQUEST_EXTERNAL_STORAGE 权限。
  /// - Android (API >= 29) / iOS: 系统自动处理，无需运行时申请。
  static Future<void> _saveToGallery(
    BuildContext ctx,
    String imagePath,
  ) async {
    try {
      if (isOhos) {
        // 1. 检查权限
        final hasPermission = await PosterShareService.checkWritePermission();
        if (!hasPermission) {
          // 2. 首次：请求权限
          final granted = await PosterShareService.requestWritePermission();
          if (!granted) {
            // 3. 用户拒绝：提示去设置开启
            if (!ctx.mounted) return;
            await PermissionService.showPermissionDeniedDialog(
              ctx,
              permissionName: '存储',
              reason: '保存海报到相册需要存储权限，请在「设置 > 应用 > LiftTrack > 权限管理」中开启「媒体和文件」权限后重试。',
            );
            return;
          }
        }
        // 4. 已授权，执行保存
        await PosterShareService.saveToGallery(imagePath);
        if (!ctx.mounted) return;
        FitToast.success(ctx, '已保存到相册');
      } else if (Platform.isAndroid) {
        // Android: API < 29 需运行时申请存储权限
        if (await _requestAndroidStoragePermission(ctx)) {
          final result = await ImageGallerySaver.saveFile(imagePath);
          if (!ctx.mounted) return;
          if (result is Map && result['isSuccess'] == true) {
            FitToast.success(ctx, '已保存到相册');
          } else {
            FitToast.error(ctx, '保存失败，请重试');
          }
        }
      } else {
        // iOS 及其他平台：系统自动处理权限
        final result = await ImageGallerySaver.saveFile(imagePath);
        if (!ctx.mounted) return;
        if (result is Map && result['isSuccess'] == true) {
          FitToast.success(ctx, '已保存到相册');
        } else {
          FitToast.error(ctx, '保存失败，请重试');
        }
      }
    } on PlatformException catch (e) {
      if (!ctx.mounted) return;
      final msg = e.message ?? e.code;
      // OHOS 原生返回 PERMISSION_DENIED 时，引导用户去设置
      if (e.code == 'PERMISSION_DENIED') {
        await PermissionService.showPermissionDeniedDialog(
          ctx,
          permissionName: '存储',
          reason: '保存海报到相册需要存储权限，请在「设置 > 应用 > LiftTrack > 权限管理」中开启「媒体和文件」权限后重试。',
        );
        return;
      }
      FitToast.error(ctx, '保存失败：$msg');
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '保存失败：$e');
    }
  }

  /// Android 存储权限请求（仅 API < 29 需要）
  ///
  /// 返回 true 表示已授权可继续保存；false 表示用户拒绝，
  /// 此时已弹出引导去设置的对话框。
  static Future<bool> _requestAndroidStoragePermission(
    BuildContext ctx,
  ) async {
    try {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;
      final result = await Permission.storage.request();
      if (result.isGranted) return true;
      if (!ctx.mounted) return false;
      // 用户拒绝（含永久拒绝）：引导去设置
      await PermissionService.showPermissionDeniedDialog(
        ctx,
        permissionName: '存储',
        reason: '保存海报到相册需要存储权限，请在系统设置中开启存储权限后重试。',
      );
      return false;
    } catch (_) {
      if (ctx.mounted) {
        FitToast.error(ctx, '获取存储权限失败');
      }
      return false;
    }
  }

  /// 拉起系统分享 sheet
  ///
  /// - Android/iOS: 使用 share_plus
  /// - OHOS: 使用 MethodChannel 调用原生系统分享
  static Future<void> _shareToPlatform(
    BuildContext ctx,
    String imagePath,
  ) async {
    try {
      if (isOhos) {
        // OHOS: 通过 MethodChannel 调用原生系统分享
        await PosterShareService.share(imagePath);
      } else {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'LiftTrack',
        );
      }
    } on PlatformException catch (e) {
      if (!ctx.mounted) return;
      final msg = e.message ?? e.code;
      FitToast.error(ctx, '分享失败：$msg');
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '分享失败：$e');
    }
  }
}
