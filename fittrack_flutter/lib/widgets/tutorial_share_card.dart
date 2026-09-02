import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/tutorial_content.dart';
import '../services/invitation_service.dart';
import 'common_widgets.dart';
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

  /// 海报分享：复用 [PosterCaptureHelper.captureAndPreview] 的统一离屏渲染
  /// 流程（与邀请/计划/健身房海报一致），内部已处理：
  /// - OHOS 屏幕内渲染 + 遮罩（避免纯离屏 RepaintBoundary 不可 paint）
  /// - 内容自适应高度（Path B，OverflowBox 有限 maxHeight + 收缩截图），
  ///   步骤数与是否有图动态变化都不再触发 RenderFlex overflow
  /// - MouseTracker 断言屏蔽、paint 轮询等待、截图、预览弹窗、成就上报
  Future<void> _sharePoster(Tutorial t) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await PosterCaptureHelper.captureAndPreview(
        context,
        posterWidget: TutorialPoster(
          tutorial: t,
          inviteCode: _inviteCode,
          steps: _steps,
          qrData: 'fittrack://tutorial?id=${t.id}',
        ),
        posterWidth: TutorialPoster.posterWidth,
        title: '动作分享海报',
        fileNamePrefix: 'fittrack_tutorial',
      );
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
