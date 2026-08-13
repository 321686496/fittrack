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
class OpponentDetailPage extends StatefulWidget {
  const OpponentDetailPage({super.key});

  @override
  State<OpponentDetailPage> createState() => _OpponentDetailPageState();
}

class _OpponentDetailPageState extends State<OpponentDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _purchaseSkin(String goodId) async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    final ok = await VirtualGoodsStore.unlock(goodId);
    if (!mounted) return;
    if (ok) {
      FitToast.success(context, '解锁成功');
      setState(() {});
    } else {
      FitToast.warning(context, '积分不足或暂不可购买');
    }
    setState(() => _unlocking = false);
  }

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
    final skinId = opp.appliedSkinId;
    final hasSkin = skinId.isNotEmpty;
    final cardTheme = hasSkin ? OpponentSkinConfig.byId(skinId).cardTheme : null;

    // 启停呼吸光效（限定皮肤闪烁）
    if (cardTheme != null && cardTheme.showShimmer) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat(reverse: true);
      }
    } else {
      if (_shimmerController.isAnimating) _shimmerController.stop();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: cardTheme != null
            ? LinearGradient(
                colors: cardTheme.gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: cardTheme == null ? colors.bgCard : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardTheme?.borderColor ?? colors.borderColor,
          width: cardTheme != null ? 1.5 : 1,
        ),
        boxShadow: cardTheme != null
            ? [
                BoxShadow(
                  color: cardTheme.glowColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 240×240 人物图（带光晕）
          Stack(
            alignment: Alignment.center,
            children: [
              if (cardTheme != null)
                // 皮肤光晕背景
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardTheme.glowColor.withOpacity(0.15),
                  ),
                ),
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
            ],
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
              if (cardTheme != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cardTheme.badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${cardTheme.badgeEmoji} ${OpponentSkinConfig.byId(skinId).name}',
                    style: TextStyle(
                      color: cardTheme.badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
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
    final skinId = opp.appliedSkinId;
    final hasSkin = skinId.isNotEmpty;
    final borderColor = hasSkin
        ? OpponentSkinConfig.byId(skinId).cardTheme.borderColor
        : colors.borderColor;

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
              _buildStatItem(colors, '${opp.weeklyTrainings}', '次训练', borderColor),
              _buildStatItem(colors, '${opp.weeklyWeight}', 'kg 总量', borderColor),
              _buildStatItem(colors, '${opp.weeklyDuration}', '分钟时长', borderColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(LiftTrackColors colors, String value, String label, Color borderColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withOpacity(0.5), width: 1),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(
              color: colors.accentGlow, fontSize: 20, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
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
    // 当前皮肤 OpponentSkinConfig（用于 cardTheme / signatureMove）
    final appliedSkinCfg = skinId.isNotEmpty ? OpponentSkinConfig.byId(skinId) : null;
    final cardTheme = appliedSkinCfg?.cardTheme;
    final isAmbassador = skinId == 'skin_ambassador';

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
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: cardTheme != null
                      ? LinearGradient(
                          colors: cardTheme.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: cardTheme == null ? colors.accentGlow.withOpacity(0.08) : null,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cardTheme?.borderColor ?? colors.accentGlow.withOpacity(0.3),
                    width: cardTheme != null ? 1.5 : 1,
                  ),
                  boxShadow: cardTheme != null
                      ? [
                          BoxShadow(
                            color: cardTheme.glowColor.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
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
                            Text('招式：${appliedSkinCfg?.signatureMove ?? ''}', style: TextStyle(
                              color: cardTheme?.glowColor ?? colors.accentGlow,
                              fontSize: 11, fontWeight: FontWeight.w600,
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
              // 限定款角标（ambassador 当前应用时）
              if (isAmbassador)
                Positioned(
                  top: 6,
                  right: 6,
                  child: BadgeWidget(text: '限定', variant: BadgeVariant.accent),
                ),
              // ambassador 金色光晕呼吸动画
              if (isAmbassador && cardTheme != null && cardTheme.showShimmer)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (_, __) {
                        final t = _shimmerController.value;
                        final opacity = 0.3 + 0.7 * (0.5 - (t - 0.5).abs()) * 2;
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cardTheme.glowColor.withOpacity(opacity.clamp(0.0, 1.0)),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 所有皮肤列表（含价格 / 购买按钮）
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
    final skinCfg = OpponentSkinConfig.byId(good.id);
    final cardTheme = skinCfg.cardTheme;
    final isAmbassador = good.id == 'skin_ambassador';

    return GestureDetector(
      onTap: unlocked ? null : () => _showSkinPreview(colors, good, skinCfg),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: unlocked ? colors.accentGlow.withOpacity(0.06) : colors.bgSecondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked ? (cardTheme.borderColor) : colors.borderColor,
            width: unlocked ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(good.emoji, style: TextStyle(
                  fontSize: 24,
                  color: unlocked ? null : colors.textMuted,
                )),
                if (isAmbassador && !unlocked)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: BadgeWidget(text: '限定', variant: BadgeVariant.accent),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(good.name, style: TextStyle(
              color: unlocked ? colors.textPrimary : colors.textMuted,
              fontSize: 10, fontWeight: FontWeight.w600,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (unlocked)
              Icon(
                Icons.check_circle,
                size: 12,
                color: cardTheme.glowColor,
              )
            else if (good.isPurchasableWithPoints)
              // 未解锁且可购买：显示价格 + 购买按钮
              _buildPurchaseButton(colors, good, cardTheme)
            else
              // 未解锁且不可购买（限定款）：显示解锁条件
              Text(
                good.unlockCondition ?? '',
                style: TextStyle(color: colors.textMuted, fontSize: 9),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  /// 弹出底部 sheet 预览未解锁皮肤
  void _showSkinPreview(
      LiftTrackColors colors, VirtualGood good, OpponentSkinConfig skinCfg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SkinPreviewSheet(
        colors: colors,
        good: good,
        skinCfg: skinCfg,
        unlocking: _unlocking,
        onPurchase: () {
          Navigator.of(ctx).pop();
          _purchaseSkin(good.id);
        },
        onInvite: () {
          Navigator.of(ctx).pop();
          context.push('/invitation');
        },
      ),
    );
  }

  Widget _buildPurchaseButton(
      LiftTrackColors colors, VirtualGood good, SkinCardTheme? cardTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _unlocking ? null : () => _purchaseSkin(good.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: cardTheme?.borderColor ?? colors.accentGlow,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 4),
          minimumSize: const Size(0, 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          '${good.pointsCost}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// 皮肤预览底部弹层
class _SkinPreviewSheet extends StatelessWidget {
  final LiftTrackColors colors;
  final VirtualGood good;
  final OpponentSkinConfig skinCfg;
  final bool unlocking;
  final VoidCallback onPurchase;
  final VoidCallback onInvite;

  const _SkinPreviewSheet({
    required this.colors,
    required this.good,
    required this.skinCfg,
    required this.unlocking,
    required this.onPurchase,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final isAmbassador = good.id == 'skin_ambassador';
    final cardTheme = skinCfg.cardTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // 皮肤名称
            Text(skinCfg.name, style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            // OpponentRenderer 渲染
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: cardTheme.gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardTheme.borderColor, width: 2),
              ),
              child: OpponentRenderer(
                skinId: skinCfg.id,
                size: const Size(180, 180),
                animate: true,
              ),
            ),
            const SizedBox(height: 16),
            // 皮肤信息
            _infoRow(colors, '招牌动作', skinCfg.signatureMove),
            const SizedBox(height: 8),
            _infoRow(colors, '价格', skinCfg.pointsCost),
            if (good.unlockCondition != null) ...[
              const SizedBox(height: 8),
              _infoRow(colors, '解锁条件', good.unlockCondition!),
            ],
            const SizedBox(height: 20),
            // 购买/邀请按钮
            if (good.isPurchasableWithPoints)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: unlocking ? null : onPurchase,
                  icon: const Icon(Icons.stars, size: 18),
                  label: Text('积分购买 (${good.pointsCost})',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardTheme.borderColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (isAmbassador) ...[
              if (good.isPurchasableWithPoints)
                const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onInvite,
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('邀请好友解锁',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentGlow,
                    side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('关闭', style: TextStyle(color: colors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(LiftTrackColors colors, String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(
          color: colors.textSecondary, fontSize: 13,
        )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(
            color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
          ), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
