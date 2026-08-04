import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../services/achievement_service.dart';
=======
import 'package:flutter/rendering.dart';
>>>>>>> ff02925ef0f479da86b563fa97e773c6e4509bc6
import '../services/poster_generator.dart';
import '../themes/app_themes.dart';
import 'common_widgets.dart';
import 'poster_preview_dialog.dart';

/// 海报截图辅助工具
///
/// 提供统一的"离屏渲染 → 截图 → 预览弹窗"流程，
/// 替代原来的整页跳转模式，避免页面切换带来的体验问题。
///
/// 支持：
/// - 宽度固定、高度随内容自适应（移除写死的 1920 高度）
/// - 自动显示/隐藏 loading 弹窗
/// - 截图完成后弹出 PosterPreviewDialog
class PosterCaptureHelper {
  PosterCaptureHelper._();

  /// 生成海报并弹出预览弹窗
  ///
  /// [context] 调用方 BuildContext
  /// [posterWidget] 海报内容组件（宽度固定，高度自适应）
  /// [posterWidth] 海报宽度（像素）
  /// [title] 预览弹窗标题
  /// [fileNamePrefix] 临时文件名前缀
  /// [onError] 截图失败回调（可选）
  static Future<void> captureAndPreview(
    BuildContext context, {
    required Widget posterWidget,
    required double posterWidth,
    required String title,
    String fileNamePrefix = 'fittrack_poster',
    void Function(String error)? onError,
  }) async {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    // 显示 loading 弹窗
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colors.accentGlow,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '正在生成海报...',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);

    // 用 Overlay + Positioned(offscreen) 渲染海报
    // 仅固定宽度，高度随内容自适应（不指定 height 和 bottom）
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -posterWidth,
        top: 0,
        width: posterWidth,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: posterWidget,
          ),
        ),
      ),
    );

    // OHOS 引擎 bug 修复：OHOS Flutter 引擎在帧绘制时会重入触发
    // MouseTracker.updateAllDevices，导致 !_debugDuringDeviceUpdate 断言失败。
    // 该断言错误会中断帧绘制，导致 endOfFrame 卡住、海报截图失败。
    // 临时屏蔽该错误，确保帧绘制正常完成。
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final errorStr = details.exception.toString();
      if (errorStr.contains('_debugDuringDeviceUpdate') ||
          errorStr.contains('MouseTracker')) {
        return;
      }
      originalOnError?.call(details);
    };

    try {
      overlay.insert(entry);
<<<<<<< HEAD
      // 等待 OverlayEntry 完成挂载与首帧 build，否则 boundaryKey.currentContext
      // 为 null 会导致 PosterGenerator.capture 内 findRenderObject 抛异常。
      await WidgetsBinding.instance.endOfFrame;
=======

      // 轮询等待 RepaintBoundary 完成 layout + paint
      // 原固定 endOfFrame×2 + delay×100ms 在部分设备上不可靠：
      // showDialog 与 overlay.insert 同帧竞争、OHOS MouseTracker bug
      // 中断帧绘制等情况都会导致 boundary 未 paint 就执行 toImage()。
      await _waitForBoundaryReady(boundaryKey);
>>>>>>> ff02925ef0f479da86b563fa97e773c6e4509bc6

      // paint 等待已统一收敛到 PosterGenerator.capture 内部，
      // 此处不再使用固定 50ms 等待（首帧 paint 未完成时调用 toImage 会触发
      // '!debugNeedsPaint' 断言）。
      final imagePath = await PosterGenerator.capture(
        boundaryKey,
        fileNamePrefix: fileNamePrefix,
      );
      entry.remove();
      if (!context.mounted) return;

      // 分享成功：记录到成就系统（评估 share_first / share_3 / share_10）
      await AchievementService.instance.recordShare();
      if (!context.mounted) return;

      // 关闭 loading 弹窗
      Navigator.of(context, rootNavigator: true).pop();

      // 弹出预览弹窗
      await PosterPreviewDialog.show(
        context,
        imagePath: imagePath,
        title: title,
      );
    } catch (e, st) {
      debugPrint(' PosterCaptureHelper 海报生成失败: $e\n$st');
      entry.remove();
      if (!context.mounted) return;

      // 关闭 loading 弹窗
      Navigator.of(context, rootNavigator: true).pop();

      final msg = '海报生成失败：$e';
      if (onError != null) {
        onError(msg);
      } else {
        FitToast.error(context, msg);
      }
    } finally {
      // 恢复原始错误处理
      FlutterError.onError = originalOnError;
    }
  }

  /// 轮询等待 RepaintBoundary 就绪（已挂载且完成 paint）
  ///
  /// 每轮迭代：主动 scheduleFrame → endOfFrame → 短延迟 → 检查
  /// debugNeedsPaint。最多重试 [maxAttempts] 次，确保在各类设备上
  /// 都能可靠完成 paint 后再截图。
  static Future<void> _waitForBoundaryReady(
    GlobalKey key, {
    int maxAttempts = 10,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      // 主动调度帧，确保 overlay entry 被处理
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 30));

      final ctx = key.currentContext;
      if (ctx == null) continue;

      final ro = ctx.findRenderObject();
      if (ro is! RenderRepaintBoundary) continue;

      // debugNeedsPaint 仅在 debug 模式可安全访问（release 模式
      // 跳过检查，依赖多帧等待保证 paint 完成）
      bool needsPaint = false;
      assert(() {
        needsPaint = ro.debugNeedsPaint;
        return true;
      }());

      if (!needsPaint) return;
    }
    // 超过最大重试次数，仍然继续尝试截图（让 toImage 自行决定）
  }
}
