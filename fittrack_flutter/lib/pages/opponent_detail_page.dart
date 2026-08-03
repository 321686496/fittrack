import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/virtual_opponent.dart';
import '../data/virtual_goods.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/opponent/opponent_renderer.dart';
import '../widgets/opponent/opponent_skin_config.dart';

/// 对手详情页 —— P0 最小可用版
class OpponentDetailPage extends StatelessWidget {
  const OpponentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final settings = Storage.getSettings();
    final opponentJson = settings['virtualOpponentData'] as Map<String, dynamic>?;

    if (opponentJson == null) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: '对手详情',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text('对手尚未匹配', style: TextStyle(color: colors.textMuted)),
              ),
            ),
          ],
        ),
      );
    }

    final opponent = VirtualOpponent.fromJson(Map<String, dynamic>.from(opponentJson));
    final skinId = opponent.appliedSkinId;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '对手详情',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(colors, opponent),
                  const SizedBox(height: 16),
                  _buildWeeklyStatsCard(colors, opponent),
                  const SizedBox(height: 16),
                  if (opponent.currentStatus != null) ...[
                    _buildStatusCard(colors, opponent),
                    const SizedBox(height: 16),
                  ],
                  _buildSkinCard(colors, skinId, context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(LiftTrackColors colors, VirtualOpponent opp) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 240×240 人物图（Row 改 Column，避免溢出）
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: OpponentRenderer(
                skinId: opp.appliedSkinId,
                size: const Size(240, 240),
                autoTrain: true,
                showAura: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(opp.nickname, style: TextStyle(
            color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(opp.tier.label, style: TextStyle(
                  color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(opp.persona, style: TextStyle(
                  color: colors.textMuted, fontSize: 12,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard(LiftTrackColors colors, VirtualOpponent opp) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('本周战绩', style: TextStyle(
            color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(colors, '${opp.weeklyTrainings}', '次训练'),
              _buildStatItem(colors, '${opp.weeklyWeight}', 'kg 总量'),
              _buildStatItem(colors, '${opp.weeklyDuration}', '分钟时长'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(LiftTrackColors colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(
            color: colors.accentGlow, fontSize: 20, fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(LiftTrackColors colors, VirtualOpponent opp) {
    return CardWidget(
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, size: 18, color: colors.accentGlow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${opp.nickname}：${opp.currentStatus}',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinCard(LiftTrackColors colors, String skinId, BuildContext context) {
    final skin = skinId.isNotEmpty ? VirtualGoodsStore.byId(skinId) : null;
    final allSkins = VirtualGoodsStore.byCategory(GoodCategory.opponentSkin);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text('对手皮肤', style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          // 当前皮肤
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.accentGlow.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 96, height: 96,
                  child: OpponentRenderer(
                    skinId: skinId,
                    size: const Size(96, 96),
                    autoTrain: false,
                    showAura: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skin?.name ?? '默认皮肤', style: TextStyle(
                        color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
                      )),
                      if (skin != null) ...[
                        const SizedBox(height: 4),
                        Text('招式：${OpponentSkinConfig.byId(skinId).signatureMove}', style: TextStyle(
                          color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600,
                        )),
                        Text(skin.isLimited ? '限定款 · 邀请解锁' : '${skin.pointsCost} 积分', style: TextStyle(
                          color: colors.textMuted, fontSize: 11,
                        )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 所有皮肤列表
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: allSkins.map((s) {
              final unlocked = VirtualGoodsStore.isUnlocked(s.id) ||
                  (s.id == 'skin_ambassador' && Storage.getSettings()['unlockedOpponentSkin'] == true);
              return _buildSkinTile(colors, s, unlocked);
            }).toList(),
          ),
          const SizedBox(height: 12),
          // 去邀请入口
          if (skinId != 'skin_ambassador') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/invitation'),
                icon: const Icon(Icons.card_giftcard, size: 16),
                label: const Text('邀请好友解锁限定皮肤'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkinTile(LiftTrackColors colors, VirtualGood good, bool unlocked) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? colors.accentGlow.withOpacity(0.06) : colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? colors.accentGlow.withOpacity(0.3) : colors.borderColor,
        ),
      ),
      child: Column(
        children: [
          Text(good.emoji, style: TextStyle(
            fontSize: 24,
            color: unlocked ? null : colors.textMuted,
          )),
          const SizedBox(height: 4),
          Text(good.name, style: TextStyle(
            color: unlocked ? colors.textPrimary : colors.textMuted,
            fontSize: 10, fontWeight: FontWeight.w600,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            size: 12,
            color: unlocked ? colors.accentGlow : colors.textMuted,
          ),
        ],
      ),
    );
  }
}
