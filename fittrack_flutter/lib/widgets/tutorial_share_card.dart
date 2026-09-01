import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/tutorial_content.dart';
import '../services/invitation_service.dart';
import '../services/poster_generator.dart';
import 'common_widgets.dart';
import 'poster_preview_dialog.dart';
import 'poster_capture_helper.dart';
import 'poster_theme.dart';
import 'tutorial_poster.dart';

/// v1 教学分享卡片 —— 底部弹层
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2-3.4
/// 验收标准：分享卡片包含动作名称 + 邀请码 FIT-INV-XXXXXX
///
/// v1.2 简化实现：文本分享 + 卡片预览（无图片生成）
/// V1-08a 阶段补充：二维码生成 + 图片渲染
class TutorialShareCardSheet extends StatefulWidget {
  final Tutorial tutorial;

  /// 可选：显式训练步骤（含 title/desc/image）。
  /// 为空时按 [Tutorial] 名称从 MockData 匹配步骤。
  final List<Map<String, dynamic>>? steps;

  const TutorialShareCardSheet({super.key, required this.tutorial, this.steps});

  @override
  State<TutorialShareCardSheet> createState() => _TutorialShareCardSheetState();
}

class _TutorialShareCardSheetState extends State<TutorialShareCardSheet> {
  late String _inviteCode;
  bool _sharing = false;

  /// 展示用的训练步骤：优先用显式传入的 [steps]，否则按名称匹配
  List<Map<String, dynamic>> get _steps =>
      (widget.steps != null && widget.steps!.isNotEmpty)
          ? widget.steps!
          : _resolveSteps(widget.tutorial);

  @override
  void initState() {
    super.initState();
    _inviteCode = InvitationService.instance.generateInvitationCode();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final t = widget.tutorial;

    // 高度约束在屏幕 80% 以内，内容超高时内部滚动，避免底部溢出。
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // 顶部抓手
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 标题
          Row(
            children: [
              Icon(Icons.share_outlined, size: 18, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                '分享动作教学',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(Icons.close, size: 20, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 卡片预览
          _buildPreviewCard(colors, t),
          const SizedBox(height: 16),
          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyText(t),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制文本'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentGlow,
                    side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _sharing ? null : () => _sharePoster(t),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('立即分享'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 卡片预览（与 TutorialPoster 带图设计一致，预览下方即是海报） ──

  Widget _buildPreviewCard(LiftTrackColors colors, Tutorial t) {
    final pc = PosterColors.fromThemeId(null);
    final steps = _steps;
    final hasSteps = steps.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pc.brand.withOpacity(0.18), pc.brand.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pc.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 品牌头 + 肌群徽标
          Row(
            children: [
              Icon(Icons.fitness_center, size: 16, color: pc.brand),
              const SizedBox(width: 6),
              Text(
                'LiftTrack · TUTORIAL',
                style: TextStyle(
                  color: pc.brand,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pc.brand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.primaryMuscle.label,
                  style: TextStyle(
                    color: pc.brand,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 动作名
          Text(
            t.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pc.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${t.difficulty.label} · ${t.equipment ?? "无器械"} · ${t.coachName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: pc.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          // 步骤图（每行 2 个，展示全部步骤，行数随步骤数自适应）
          if (hasSteps) ...[
            for (int i = 0; i < steps.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stepPreview(steps, i),
                  if (i + 1 < steps.length) const SizedBox(width: 8),
                  if (i + 1 < steps.length) _stepPreview(steps, i + 1),
                ],
              ),
            ],
          ] else
            ...t.keyPoints.take(3).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: pc.brand),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          p,
                          style: TextStyle(color: pc.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 12),
          // 分割线
          Container(height: 1, color: pc.cardBorder),
          const SizedBox(height: 12),
          // 邀请码 + 二维码
          Row(
            children: [
              Icon(Icons.card_giftcard, size: 16, color: pc.brand),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '输入邀请码，双方得福利',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: pc.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _inviteCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pc.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // 二维码：fittrack://invite?code=FIT-INV-XXXXXX
              Container(
                width: 54,
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 8),
                  ],
                ),
                child: QrImageView(
                  data: 'fittrack://invite?code=$_inviteCode',
                  version: QrVersions.auto,
                  size: 46,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: pc.textPrimary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: pc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2×2 网格中的单个步骤图卡
  Widget _stepPreview(List<Map<String, dynamic>> steps, int index) {
    final pc = PosterColors.fromThemeId(null);
    final step = (index < steps.length) ? steps[index] : null;
    final image = (step?['image'] as String?) ?? '';
    final title = (step?['title'] as String?) ?? '';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: pc.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: pc.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) =>
                        Container(color: pc.cardBorder),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _stepNumBadge(pc, index + 1),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pc.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepNumBadge(PosterColors pc, int num) {
    return Container(
      width: 14,
      height: 14,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: pc.brand,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$num',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  // ── 分享操作 ──────────────────────────────────────────────

  String _buildShareText(Tutorial t) {
    final points = t.keyPoints.take(3).map((p) => '• $p').join('\n');
    return '【LiftTrack · ${t.name}】\n'
        '${t.primaryMuscle.label} · ${t.difficulty.label} · ${t.coachName}\n\n'
        '动作要点：\n$points\n\n'
        '输入我的邀请码 $_inviteCode，咱俩都得福利～\n'
        '一键激活：fittrack://invite?code=$_inviteCode\n'
        '（邀请码位于 LiftTrack → 设置 → 邀请有礼）';
  }

  void _copyText(Tutorial t) {
    final text = _buildShareText(t);
    Clipboard.setData(ClipboardData(text: text));
    FitToast.success(context, '已复制到剪贴板');
  }

  /// 海报分享：通过 [Overlay] 离屏渲染 [TutorialPoster]，
  /// 用 [PosterGenerator.capture] 截图，最后弹出 [PosterPreviewDialog]。
  ///
  /// 参考 Task 2 invitation_page._shareCode 的实现模式：
  /// - [OverlayEntry] + [Positioned] 移出可视区
  /// - [OverflowBox] 固定 1080×1920 海报尺寸
  /// - [RepaintBoundary] 包裹海报供截图
  /// - 多帧等待确保 layout + paint 完成
  Future<void> _sharePoster(Tutorial t) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundaryKey = GlobalKey();
      final overlay = Overlay.of(context);
      const posterWidth = TutorialPoster.posterWidth;

      late OverlayEntry entry;
      // 海报必须渲染在可视区域内：
      // OHOS fork 引擎不会 paint 完全离屏（负坐标）的 RepaintBoundary，
      // 导致 debugNeedsPaint 永远为 true，截图轮询超时抛
      // "RepaintBoundary 尚未完成绘制，请重试"。
      // 因此海报放在 left:0/top:0（屏上），并用不透明遮罩盖住避免闪现。
      // 仅固定宽度，高度随内容自适应（可变高度，能展示全部步骤）。
      entry = OverlayEntry(
        builder: (_) => Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: posterWidth,
              // 高度不写死：Positioned 给松约束，海报按内容自适应出有限高度。
              // 不能用 OverflowBox(maxHeight: Infinity)——它会把自身尺寸解析为
              // Infinity，触发 RenderConstrainedOverflowBox "given an infinite size"。
              child: Material(
                color: Colors.transparent,
                child: RepaintBoundary(
                  key: boundaryKey,
                  child: TutorialPoster(
                    tutorial: t,
                    inviteCode: _inviteCode,
                    steps: _steps,
                    qrData: 'fittrack://tutorial?id=${t.id}',
                  ),
                ),
              ),
            ),
            // 不透明遮罩：盖住屏上的海报，视觉上无感
            Positioned.fill(
              child: ColoredBox(color: colors.bgSecondary),
            ),
            // 加载指示：点击分享立即出现 loading，而非"整屏纯色容器"
            Positioned.fill(
              child: PosterBusyOverlay(colors: colors),
            ),
          ],
        ),
      );

      // OHOS 引擎 bug 修复：OHOS Flutter 引擎在帧绘制时会重入触发
      // MouseTracker.updateAllDevices，导致 !_debugDuringDeviceUpdate 断言失败。
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

      overlay.insert(entry);

      // paint 等待已统一收敛到 PosterGenerator.capture 内部，
      // 此处不再使用固定 30ms 等待（首帧 paint 未完成时调用 toImage 会触发
      // '!debugNeedsPaint' 断言）。
      try {
        final imagePath = await PosterGenerator.capture(
          boundaryKey,
          fileNamePrefix: 'fittrack_tutorial',
        );
        entry.remove();
        if (!mounted) return;
        await PosterPreviewDialog.show(
          context,
          imagePath: imagePath,
          title: '动作分享海报',
        );
      } catch (e) {
        entry.remove();
        if (!mounted) return;
        FitToast.error(context, '海报生成失败：$e');
      } finally {
        // 恢复原始错误处理
        FlutterError.onError = originalOnError;
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  /// 按动作名从 MockData 匹配该教程对应的训练步骤（title/desc/image）
  List<Map<String, dynamic>> _resolveSteps(Tutorial t) {
    final name = t.name.trim();
    if (name.isEmpty) return const [];
    for (final ex in MockData.exercises) {
      if ((ex['name'] as String?) == name) {
        final id = ex['id'] as String;
        return MockData.exerciseSteps[id] ?? const [];
      }
    }
    return const [];
  }

  LiftTrackColors get colors => Theme.of(context).extension<LiftTrackColors>()!;
}
