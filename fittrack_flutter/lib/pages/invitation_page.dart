import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../themes/app_themes.dart';
import '../services/invitation_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// v1.1 邀请有礼页面（4 区段结构）
///
/// 依据：v1.1 优化迭代需求 #5
/// 1. 邀请码大卡片（展示 + 复制 + 分享 + 有效期）
/// 2. 进度概览（已邀请 + 已获积分 + 4 档里程碑 + 整体进度条）
/// 3. 奖励规则说明（4 档奖励列表 + 双方获奖备注）
/// 4. 邀请流程图解（4 步水平流程：分享→注册→训练→获奖）
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
                  _buildCodeCard(colors),
                  const SizedBox(height: 16),
                  _buildProgressCard(colors),
                  const SizedBox(height: 16),
                  _buildRewardRulesCard(colors),
                  const SizedBox(height: 16),
                  _buildFlowCard(colors),
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

  // ── 1. 邀请码大卡片 ──────────────────────────────────────────────

  Widget _buildCodeCard(FitTrackColors colors) {
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
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accentGlow.withOpacity(0.12), colors.accentGlow.withOpacity(0.04)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentGlow.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                SelectableText(
                  _myCode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '永久有效',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(colors),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制邀请码'),
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

  // ── 2. 进度概览 ──────────────────────────────────────────────

  Widget _buildProgressCard(FitTrackColors colors) {
    final totalReferrals = _progress['totalReferrals'] as int? ?? 0;
    final totalPoints = _progress['totalPoints'] as int? ?? 0;
    final isAmbassador = _progress['isAmbassador'] == true;

    // 4 档里程碑
    final milestones = [
      _MilestoneData(1, '首次激活', totalReferrals >= 1),
      _MilestoneData(3, '累计 3 人', totalReferrals >= 3),
      _MilestoneData(5, '累计 5 人', totalReferrals >= 5),
      _MilestoneData(10, '累计 10 人', totalReferrals >= 10),
    ];

    // 整体进度（基于最高档 10 人）
    final overallProgress = (totalReferrals / 10).clamp(0.0, 1.0);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '进度概览',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 两列统计
          Row(
            children: [
              Expanded(
                child: _buildStatBox(colors, '已邀请人数', '$totalReferrals', '人', Icons.person_add),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(colors, '已获积分', '$totalPoints', '分', Icons.stars),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 档里程碑进度条
          Row(
            children: milestones.map((m) {
              final active = m.unlocked;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: active ? colors.accentGlow : colors.borderColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${m.count}',
                      style: TextStyle(
                        color: active ? colors.accentGlow : colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 整体进度条
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('整体进度', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              Text('${(overallProgress * 100).toInt()}%', style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 6,
              backgroundColor: colors.borderColor,
              valueColor: AlwaysStoppedAnimation(colors.accentGlow),
            ),
          ),
          if (isAmbassador) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.military_tech, color: colors.accentGlow, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '已获得「燃力大使」永久称号',
                    style: TextStyle(
                      color: colors.accentGlow,
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

  Widget _buildStatBox(FitTrackColors colors, String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colors.accentGlow, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: TextStyle(
                      color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(width: 2),
                    Text(unit, style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. 奖励规则说明 ──────────────────────────────────────────────

  Widget _buildRewardRulesCard(FitTrackColors colors) {
    final rules = [
      _RewardRule(1, '首次激活', '解锁 3 个进阶教学 + 引路人徽章', '7 天高级统计体验'),
      _RewardRule(3, '累计 3 人', '永久免广告看训练报告 + 布道者徽章', '7 天高级统计体验'),
      _RewardRule(5, '累计 5 人', '解锁高手教学专题 + 对手皮肤', '7 天高级统计体验'),
      _RewardRule(10, '累计 10 人', '燃力大使永久称号', '7 天高级统计体验'),
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
                '奖励规则',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((r) => _buildRewardRuleItem(colors, r)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: colors.accentGlow, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '好友输入你的邀请码激活后，双方均获得对应奖励。好友奖励为 7 天高级统计全开放体验。',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRuleItem(FitTrackColors colors, _RewardRule r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${r.count}',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: TextStyle(
                  color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 2),
                Text('你：${r.yourReward}', style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4)),
                Text('好友：${r.friendReward}', style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. 邀请流程图解 ──────────────────────────────────────────────

  Widget _buildFlowCard(FitTrackColors colors) {
    final steps = [
      _FlowStep(Icons.share, '分享邀请码', '微信/QQ/复制'),
      _FlowStep(Icons.person_add, '好友注册', '输入你的邀请码'),
      _FlowStep(Icons.fitness_center, '开始训练', '好友完成首次训练'),
      _FlowStep(Icons.card_giftcard, '双方获奖', '自动发放奖励'),
    ];

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '邀请流程',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isLast = idx == steps.length - 1;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(s.icon, color: colors.accentGlow, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(s.title, style: TextStyle(
                            color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600,
                          ), textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Text(s.desc, style: TextStyle(
                            color: colors.textMuted, fontSize: 10,
                          ), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 输入邀请码（保留原逻辑） ──────────────────────────────────────────────

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

    final colors = Theme.of(context).extension<FitTrackColors>()!;
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
}

class _MilestoneData {
  final int count;
  final String title;
  final bool unlocked;

  const _MilestoneData(this.count, this.title, this.unlocked);
}

class _RewardRule {
  final int count;
  final String title;
  final String yourReward;
  final String friendReward;

  const _RewardRule(this.count, this.title, this.yourReward, this.friendReward);
}

class _FlowStep {
  final IconData icon;
  final String title;
  final String desc;

  const _FlowStep(this.icon, this.title, this.desc);
}
