import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 邀请流程详解页面（双视角完整流程）
///
/// 依据：docs/superpowers/specs/2026-09-09-invitation-flow-detail-design.md
/// 从邀请页「邀请流程」卡片进入，展示从分享邀请码到双方获得全部奖励的
/// 完整链路：邀请人 6 步 + 被邀请人 4 步 + 奖励对照 + 规则说明。
class InvitationFlowDetailPage extends StatelessWidget {
  const InvitationFlowDetailPage({super.key});

  // 邀请人视角：完整 6 步
  static const List<_FlowStepData> _inviterSteps = [
    _FlowStepData(
      icon: Icons.share,
      title: '分享邀请码',
      desc: '复制邀请码或生成邀请海报，通过微信/QQ 发给好友。邀请码永久有效',
    ),
    _FlowStepData(
      icon: Icons.person_add,
      title: '好友激活邀请码',
      desc: '好友在「输入邀请码」中输入你的邀请码完成激活。一码一绑，激活后不可更换',
      reward: '好友 +50 积分',
    ),
    _FlowStepData(
      icon: Icons.fitness_center,
      title: '好友完成首次训练',
      desc: '好友完成至少 1 组动作的有效训练，训练数据将加密写入激活凭证',
    ),
    _FlowStepData(
      icon: Icons.qr_code_2,
      title: '好友出示激活凭证',
      desc: '好友在「我的激活凭证」生成 FIT-ACT 识别码发给你。凭证含加密签名的训练数据快照，可放心展示',
    ),
    _FlowStepData(
      icon: Icons.verified,
      title: '你确认记录成果',
      desc: '在「记录邀请成果」中扫码或输入好友的识别码，系统自动校验训练达标与防自邀',
    ),
    _FlowStepData(
      icon: Icons.card_giftcard,
      title: '奖励自动到账',
      desc: '按累计邀请档位自动发放积分、徽章与皮肤，无需手动领取',
      reward: '1/3/5/10 人档位：最高 1200 积分',
    ),
  ];

  // 被邀请人视角：4 步
  static const List<_FlowStepData> _inviteeSteps = [
    _FlowStepData(
      icon: Icons.redeem,
      title: '获取好友邀请码',
      desc: '向好友索取 FIT-INV-XXXXXX 格式的邀请码',
    ),
    _FlowStepData(
      icon: Icons.input,
      title: '输入激活',
      desc: '在「输入邀请码」中输入邀请码，激活后立即到账',
      reward: '你 +50 积分',
    ),
    _FlowStepData(
      icon: Icons.fitness_center,
      title: '完成首次训练',
      desc: '完成至少 1 组动作的有效训练，满足凭证达标条件',
    ),
    _FlowStepData(
      icon: Icons.qr_code_2,
      title: '出示激活凭证',
      desc: '生成 FIT-ACT 识别码发给邀请你的好友。好友确认后，双方奖励全部到账',
    ),
  ];

  // 奖励对照（与邀请页奖励规则档位一致）
  static const List<_RewardTierData> _rewardTiers = [
    _RewardTierData(count: 1, inviter: '100 积分 + 引路人徽章', invitee: '50 积分'),
    _RewardTierData(count: 3, inviter: '300 积分 + 布道者徽章', invitee: '50 积分'),
    _RewardTierData(count: 5, inviter: '600 积分 + 传道者徽章 + 限定对手皮肤', invitee: '50 积分'),
    _RewardTierData(count: 10, inviter: '1200 积分 + LiftTrack 大使称号', invitee: '50 积分'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '邀请流程详解',
            subtitle: '从分享到双方获奖的完整链路',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineCard(colors, '邀请人视角', Icons.person, _inviterSteps),
                  const SizedBox(height: 16),
                  _buildTimelineCard(colors, '被邀请人视角', Icons.group, _inviteeSteps),
                  const SizedBox(height: 16),
                  _buildRewardTableCard(colors),
                  const SizedBox(height: 16),
                  _buildRulesCard(colors),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 视角时间线卡片（标题 + 竖向步骤）
  Widget _buildTimelineCard(
      LiftTrackColors colors, String title, IconData titleIcon, List<_FlowStepData> steps) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return _buildTimelineItem(
                colors, entry.value, entry.key == steps.length - 1);
          }),
        ],
      ),
    );
  }

  /// 单个时间线节点（圆形图标 + 连接线 + 内容）
  Widget _buildTimelineItem(LiftTrackColors colors, _FlowStepData step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, color: colors.accentGlow, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: colors.borderColor),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.desc,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (step.reward != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
                      ),
                      child: Text(
                        step.reward!,
                        style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 奖励对照卡片：4 档 ×（邀请人 / 被邀请人）两列
  Widget _buildRewardTableCard(LiftTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '奖励对照',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._rewardTiers.map((t) => _buildRewardTierItem(colors, t)),
        ],
      ),
    );
  }

  Widget _buildRewardTierItem(LiftTrackColors colors, _RewardTierData t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${t.count}',
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '累计邀请 ${t.count} 人',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('邀请人', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        t.inviter,
                        style: TextStyle(color: colors.textPrimary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('被邀请人', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        t.invitee,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 规则说明卡片
  Widget _buildRulesCard(LiftTrackColors colors) {
    const rules = [
      '邀请码永久有效，格式 FIT-INV-XXXXXX',
      '一码一绑：每位用户仅能激活一个邀请码，激活后不可更换',
      '防自邀：不能激活自己的邀请码或确认自己的凭证',
      '激活凭证每次生成均反映最新训练数据',
      '邀请奖励为档位制：累计 1/3/5/10 人时分别发放，非每人均有积分',
    ];
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '规则说明',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: colors.accentGlow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _FlowStepData {
  final IconData icon;
  final String title;
  final String desc;
  final String? reward;

  const _FlowStepData({
    required this.icon,
    required this.title,
    required this.desc,
    this.reward,
  });
}

class _RewardTierData {
  final int count;
  final String inviter;
  final String invitee;

  const _RewardTierData({
    required this.count,
    required this.inviter,
    required this.invitee,
  });
}
