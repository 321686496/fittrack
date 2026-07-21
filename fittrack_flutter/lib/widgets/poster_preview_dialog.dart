import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../themes/app_themes.dart';
import '../utils/platform_utils.dart';
import 'common_widgets.dart';

/// 海报预览统一弹窗
///
/// 提供三个能力：
/// 1. 居中展示 PNG 海报图片（80% 宽度，高度自适应）
/// 2. 保存按钮：Android/iOS 走 `ImageGallerySaver` 保存到相册；OHOS 平台
///    降级为 `File.copy` 到临时目录并 Toast 提示路径（按钮文案改为"保存到本地"）
/// 3. 分享按钮：调用 `share_plus` 的 `Share.shareXFiles` 拉起系统分享 sheet
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
        final ft = Theme.of(ctx).extension<FitTrackColors>()!;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部：标题 + 关闭按钮
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  color: ft.bgCard,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
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
                    ),
                  ],
                ),
              ),
              // 中间：海报图片预览（80% 宽度，高度自适应）
              ClipRRect(
                child: Image.file(
                  File(imagePath),
                  width: MediaQuery.of(ctx).size.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
              // 底部：两个操作按钮
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: ft.bgCard,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _saveToGallery(ctx, imagePath),
                        icon: Icon(Icons.download_rounded,
                            color: ft.purpleColor),
                        label: Text(
                          isOhos ? '保存到本地' : '保存到相册',
                          style: TextStyle(color: ft.purpleColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: ft.purpleColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareToPlatform(ctx, imagePath),
                        icon: const Icon(Icons.share_rounded,
                            color: Colors.white),
                        label: const Text('分享',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ft.purpleColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 保存海报到相册（Android/iOS）或本地临时目录（OHOS 降级）
  static Future<void> _saveToGallery(
    BuildContext ctx,
    String imagePath,
  ) async {
    try {
      if (isOhos) {
        final dir = await getTemporaryDirectory();
        final saved = await File(imagePath).copy(
          '${dir.path}/fittrack_saved_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        if (!ctx.mounted) return;
        FitToast.success(ctx, '海报已保存到：${saved.path}');
      } else {
        final result = await ImageGallerySaver.saveFile(imagePath);
        if (!ctx.mounted) return;
        if (result is Map &&
            result['isSuccess'] == true) {
          FitToast.success(ctx, '已保存到相册');
        } else {
          FitToast.error(ctx, '保存失败，请重试');
        }
      }
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '保存失败：$e');
    }
  }

  /// 拉起系统分享 sheet
  static Future<void> _shareToPlatform(
    BuildContext ctx,
    String imagePath,
  ) async {
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'FitTrack 燃力',
      );
    } catch (e) {
      if (ctx.mounted) FitToast.error(ctx, '分享失败：$e');
    }
  }
}
