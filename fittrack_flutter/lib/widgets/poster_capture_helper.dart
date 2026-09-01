import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import 'package:flutter/rendering.dart';
import '../services/poster_generator.dart';
import '../themes/app_themes.dart';
import 'common_widgets.dart';
import 'poster_preview_dialog.dart';

/// 海报截图辅助工具
///
/// 提供统一的"屏上渲染 → 截图 → 预览弹窗"流程，
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
  /// [posterHeight] 海报高度（像素，可选；传入时固定高度）
  /// [title] 预览弹窗标题
  /// [fileNamePrefix] 临时文件名前缀
  /// [onError] 截图失败回调（可选）
  static Future<void> captureAndPreview(
    BuildContext context, {
    required Widget posterWidget,
    required double posterWidth,
    double? posterHeight,
    required String title,
    String fileNamePrefix = 'fittrack_poster',
    void Function(String error)? onError,
  }) async {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);

    // 海报必须渲染在可视区域内：
    // OHOS fork 引擎不会 paint 完全离屏（负坐标）的 RepaintBoundary，
    // 导致 debugNeedsPaint 永远为 true，截图轮询超时抛
    // "RepaintBoundary 尚未完成绘制，请重试"。
    // 因此海报放在 left:0/top:0（屏上），并用不透明遮罩盖住避免闪现。
    // 仅固定宽度，高度默认随内容自适应；传入 [posterHeight] 时固定高度。
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            width: posterWidth,
            // 不写死 height：Positioned 给子级"宽度固定、高度无界"的松约束。
            // 海报根组件为 SizedBox(width)+Column(mainAxisSize.min)，会按内容
            // 自适应出有限高度。注意：不能用 OverflowBox(maxHeight: Infinity)，
            // 它会把自己尺寸解析成 Infinity 导致 RenderConstrainedOverflowBox
            // 报"given an infinite size"。直接放 RepaintBoundary 即可。
            child: Material(
              color: Colors.transparent,
              child: RepaintBoundary(
                key: boundaryKey,
                child: posterWidget,
              ),
            ),
          ),
          // 不透明遮罩：盖住屏上的海报，视觉上无感
          Positioned.fill(
            child: ColoredBox(color: colors.bgSecondary),
          ),
          // 加载指示：点击分享立即出现 loading，避免"整屏纯色容器"的错觉。
          // 与海报同帧挂载在同一 OverlayEntry 内，规避 DialogRoute 与海报
          // entry 同帧插入 overlay 导致的 OHOS paint 竞态。
          Positioned.fill(
            child: PosterBusyOverlay(colors: colors),
          ),
        ],
      ),
    );

    // 插入海报 entry。loading 指示(PosterBusyOverlay)已同帧挂在同一 entry 内，
    // 规避 DialogRoute 与海报 entry 同帧插入 overlay 导致的 OHOS paint 竞态。
    overlay.insert(entry);

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
      // 诊断：hasSize 断言失败时，dump 海报子树渲染状态定位根因
      if (errorStr.contains('hasSize') && boundaryKey.currentContext != null) {
        debugPrint('=== [诊断] hasSize 断言失败，海报子树渲染树 ===');
        debugPrint(_dumpRenderTree(boundaryKey.currentContext!.findRenderObject()));
        final ho = Overlay.of(context).context.findRenderObject();
        debugPrint('=== [诊断] overlay 渲染树 ===');
        debugPrint(_dumpRenderTree(ho));
      }
      originalOnError?.call(details);
    };

    try {
      // 轮询等待 RepaintBoundary 完成 layout + paint
      await _waitForBoundaryReady(boundaryKey);
      if (!context.mounted) return;

      final imagePath = await PosterGenerator.capture(
        boundaryKey,
        fileNamePrefix: fileNamePrefix,
      );
      entry.remove();
      if (!context.mounted) return;

      // 分享成功：记录到成就系统（评估 share_first / share_3 / share_10）
      await AchievementService.instance.recordShare();
      if (!context.mounted) return;

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

  /// 递归 dump 渲染树（类型 + hasSize + size），用于诊断布局/paint 断言问题
  static String _dumpRenderTree(RenderObject? ro, {int depth = 0}) {
    if (ro == null) return '(null)';
    final buffer = StringBuffer();
    buffer.write('${'  ' * depth}${ro.runtimeType}');
    if (ro is RenderBox) {
      buffer.write(' hasSize=${ro.hasSize}'
          ' size=${ro.hasSize ? ro.size : 'N/A'}');
    } else {
      buffer.write(' (not RenderBox)');
    }
    if (ro.debugNeedsPaint) buffer.write(' needsPaint');
    buffer.write('\n');
    ro.visitChildren((child) {
      buffer.write(_dumpRenderTree(child, depth: depth + 1));
    });
    return buffer.toString();
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

/// 海报分享时的居中加载指示卡
///
/// 直接挂在分享 OverlayEntry 的 Stack 内（配合 [Positioned.fill] 使用），
/// 点击分享立即出现 loading，避免"整屏纯色容器填充页面"的观感。
/// 静态指示器（沙漏）：不使用 CircularProgressIndicator，因为它的持续动画
/// 会不断调度帧，使海报 RepaintBoundary 的 debugNeedsPaint 无法稳定为 false，
/// 导致截图轮询超时。
class PosterBusyOverlay extends StatelessWidget {
  final LiftTrackColors colors;
  final String text;

  const PosterBusyOverlay({
    super.key,
    required this.colors,
    this.text = '正在生成海报...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.accentGlow,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.hourglass_empty,
                color: colors.accentGlow,
                size: 22,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
