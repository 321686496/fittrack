import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../themes/app_themes.dart';
import '../data/tutorial_content.dart';
import '../services/invitation_service.dart';
import '../utils/platform_utils.dart';

/// v1 教学分享卡片 —— 底部弹层
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2-3.4
/// 验收标准：分享卡片包含动作名称 + 邀请码 FIT-INV-XXXXXX
///
/// v1.2 简化实现：文本分享 + 卡片预览（无图片生成）
/// V1-08a 阶段补充：二维码生成 + 图片渲染
class TutorialShareCardSheet extends StatefulWidget {
  final Tutorial tutorial;

  const TutorialShareCardSheet({super.key, required this.tutorial});

  @override
  State<TutorialShareCardSheet> createState() => _TutorialShareCardSheetState();
}

class _TutorialShareCardSheetState extends State<TutorialShareCardSheet> {
  late String _inviteCode;

  @override
  void initState() {
    super.initState();
    _inviteCode = InvitationService.instance.generateInvitationCode();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final t = widget.tutorial;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  onPressed: () => _shareText(t),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('立即分享'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.white,
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
    );
  }

  // ── 卡片预览（视觉化展示，未来可截图生成图片） ────────────

  Widget _buildPreviewCard(FitTrackColors colors, Tutorial t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accentGlow.withOpacity(0.12),
            colors.accentGlow.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部品牌
          Row(
            children: [
              Icon(Icons.fitness_center, size: 16, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                'FitTrack 燃力',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t.primaryMuscle.label,
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 动作名
          Text(
            t.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${t.difficulty.label} · ${t.equipment ?? "无器械"} · ${t.coachName}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          // 核心要点（取前3条）
          ...t.keyPoints.take(3).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: colors.accentGlow),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          // 分割线
          Container(
            height: 1,
            color: colors.borderColor,
          ),
          const SizedBox(height: 14),
          // 邀请码区域
          Row(
            children: [
              Icon(Icons.card_giftcard,
                  size: 16, color: colors.accentGlow),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '输入邀请码，双方得福利',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _inviteCode,
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              // V1-08a 二维码：fittrack://invite?code=FIT-INV-XXXXXX
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderColor),
                ),
                child: QrImageView(
                  data: 'fittrack://invite?code=$_inviteCode',
                  version: QrVersions.auto,
                  size: 48,
                  gapless: true,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: colors.textPrimary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 分享操作 ──────────────────────────────────────────────

  String _buildShareText(Tutorial t) {
    final points = t.keyPoints.take(3).map((p) => '• $p').join('\n');
    return '【FitTrack · ${t.name}】\n'
        '${t.primaryMuscle.label} · ${t.difficulty.label} · ${t.coachName}\n\n'
        '动作要点：\n$points\n\n'
        '输入我的邀请码 $_inviteCode，咱俩都得福利～\n'
        '一键激活：fittrack://invite?code=$_inviteCode\n'
        '（邀请码位于 FitTrack → 设置 → 邀请有礼）';
  }

  void _copyText(Tutorial t) {
    final text = _buildShareText(t);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.bgElevated,
      ),
    );
  }

  void _shareText(Tutorial t) {
    final text = _buildShareText(t);
    if (isOhos) {
      // OHOS: share_plus 无实现，降级为复制
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('已复制，请粘贴到聊天窗口分享'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.bgElevated,
        ),
      );
      return;
    }
    Share.share(text, subject: 'FitTrack · ${t.name}');
  }

  FitTrackColors get colors => Theme.of(context).extension<FitTrackColors>()!;
}
