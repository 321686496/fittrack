import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../themes/app_themes.dart';
import '../services/invitation_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// v1 邀请裂变页面
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E3
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.3
///
/// 三大区域：
/// 1. 我的邀请码（展示 + 分享）
/// 2. 裂变进度（里程碑解锁）
/// 3. 输入邀请码（被邀请人激活）
class InvitationPage extends StatefulWidget {
  const InvitationPage({super.key});

  @override
  State<InvitationPage> createState() => _InvitationPageState();
}

class _InvitationPageState extends State<InvitationPage> {
  final _activateController = TextEditingController();
  bool _activating = false;
  late String _myCode;
  Map<String, dynamic> _progress = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _myCode = InvitationService.instance.generateInvitationCode();
    _progress = InvitationService.instance.getReferralProgress();
    setState(() {});
  }

  @override
  void dispose() {
    _activateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '邀请有礼',
            subtitle: '邀请好友，双方得福利',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMyCodeCard(colors),
                  const SizedBox(height: 16),
                  _buildMilestonesCard(colors),
                  const SizedBox(height: 16),
                  _buildActivateCard(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 我的邀请码 ──────────────────────────────────────────────

  Widget _buildMyCodeCard(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '我的专属邀请码',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
            ),
            child: SelectableText(
              _myCode,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.accentGlow,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '分享给好友，好友输入你的邀请码激活后：\n• 你：解锁进阶教学 + 徽章\n• 好友：7天高级统计全开放体验',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(colors),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制'),
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
                  onPressed: () => _shareCode(),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('分享'),
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

  void _copyCode(FitTrackColors colors) {
    Clipboard.setData(ClipboardData(text: _myCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('邀请码已复制'),
        backgroundColor: colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareCode() {
    Share.share(
      '$_myCode\n'
      '来 FitTrack 一起训练！输入我的邀请码，咱俩都得福利～',
      subject: 'FitTrack 邀请码',
    );
  }

  // ── 裂变里程碑 ──────────────────────────────────────────────

  Widget _buildMilestonesCard(FitTrackColors colors) {
    final totalReferrals = _progress['totalReferrals'] as int? ?? 0;
    final nextMilestone = _progress['nextMilestone'] as int? ?? 1;
    final isAmbassador = _progress['isAmbassador'] == true;
    final adFreeReport = _progress['adFreeReport'] == true;

    final milestones = [
      _MilestoneData(1, '首次激活', '解锁3个进阶教学 + 引路人徽章', Icons.school, totalReferrals >= 1),
      _MilestoneData(3, '累计3人', '永久免广告看训练报告 + 布道者徽章', Icons.block, totalReferrals >= 3),
      _MilestoneData(5, '累计5人', '解锁高手教学专题 + 对手皮肤', Icons.emoji_events, totalReferrals >= 5),
      _MilestoneData(10, '累计10人', '燃力大使永久称号', Icons.military_tech, totalReferrals >= 10),
    ];

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '裂变进度',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalReferrals / $nextMilestone',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: nextMilestone > 0 ? (totalReferrals / nextMilestone).clamp(0.0, 1.0) : 1.0,
              minHeight: 8,
              backgroundColor: colors.bgSecondary,
              valueColor: AlwaysStoppedAnimation(colors.accentGlow),
            ),
          ),
          const SizedBox(height: 16),
          // 里程碑列表
          ...milestones.map((m) => _buildMilestoneItem(colors, m)),
          if (isAmbassador) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.purpleColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.purpleColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.military_tech, color: colors.purpleColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '已获得「燃力大使」永久称号',
                    style: TextStyle(
                      color: colors.purpleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (adFreeReport && !isAmbassador) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.successColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.successColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '已解锁永久免广告看训练报告',
                    style: TextStyle(
                      color: colors.successColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(FitTrackColors colors, _MilestoneData m) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: m.unlocked
                  ? colors.accentGlow.withOpacity(0.1)
                  : colors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              m.unlocked ? m.icon : Icons.lock_outline,
              size: 18,
              color: m.unlocked ? colors.accentGlow : colors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${m.count}人',
                      style: TextStyle(
                        color: m.unlocked ? colors.textPrimary : colors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      m.title,
                      style: TextStyle(
                        color: m.unlocked ? colors.textPrimary : colors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  m.desc,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (m.unlocked)
            Icon(Icons.check_circle, size: 18, color: colors.successColor),
        ],
      ),
    );
  }

  // ── 输入邀请码 ──────────────────────────────────────────────

  Widget _buildActivateCard(FitTrackColors colors) {
    final activatedCode = InvitationService.instance.getActivatedCode();

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '输入邀请码',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activatedCode != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: colors.successColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已激活邀请码',
                          style: TextStyle(
                            color: colors.successColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activatedCode,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '7天高级统计体验'
              '${InvitationService.instance.isAdvancedStatsTrialActive() ? "（生效中）" : "（已过期）"}\n'
              'v1 全部统计功能已免费开放',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ] else ...[
            Text(
              '输入好友的邀请码，激活后双方获得奖励',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _activateController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              ],
              decoration: InputDecoration(
                hintText: 'FIT-INV-XXXXXX',
                hintStyle: TextStyle(color: colors.textMuted, letterSpacing: 1),
                filled: true,
                fillColor: colors.bgSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _activating ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _activating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('立即激活', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _activate() async {
    final code = _activateController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入邀请码'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _activating = true);
    final result = await InvitationService.instance.activateInvitationCode(code);
    setState(() => _activating = false);

    if (!mounted) return;

    String msg;
    bool success = false;
    switch (result) {
      case InvitationResult.success:
        msg = '激活成功！已获得7天高级统计全开放体验';
        success = true;
        break;
      case InvitationResult.invalidFormat:
        msg = '格式错误：应为 FIT-INV-XXXXXX';
        break;
      case InvitationResult.invalidSignature:
        msg = '邀请码无效，请检查后重试';
        break;
      case InvitationResult.selfInvite:
        msg = '不能输入自己的邀请码哦';
        break;
      case InvitationResult.alreadyActivated:
        msg = '你已激活过邀请码（一码一绑）';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? colors.successColor : colors.bgElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      _loadData();
    }
  }

  FitTrackColors get colors => Theme.of(context).extension<FitTrackColors>()!;
}

class _MilestoneData {
  final int count;
  final String title;
  final String desc;
  final IconData icon;
  final bool unlocked;

  const _MilestoneData(this.count, this.title, this.desc, this.icon, this.unlocked);
}
