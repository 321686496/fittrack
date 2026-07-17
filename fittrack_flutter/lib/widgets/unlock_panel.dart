import 'package:flutter/material.dart';
import '../services/points_service.dart';
import '../services/ad_service.dart';
import '../themes/app_themes.dart';

class UnlockPanel {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String description,
    required int pointsCost,
    required String featureId,
  }) async {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final adsEnabled = AdService.adsEnabled;
    final currentPoints = PointsService.instance.points;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Icons.lock_outline, size: 40, color: colors.accentGlow),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(
              color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(
              color: colors.textSecondary, fontSize: 13,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (adsEnabled) ...[
              _buildOption(
                ctx, colors,
                icon: Icons.ondemand_video,
                label: '看广告免费解锁',
                subtitle: '观看15秒广告即可解锁',
                onTap: () async {
                  final adResult = await AdService.instance.showRewardedVideo();
                  if (adResult == AdResult.success || adResult == AdResult.notAvailable) {
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Divider(color: colors.borderColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('或', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                ),
                Expanded(child: Divider(color: colors.borderColor)),
              ]),
              const SizedBox(height: 12),
            ],
            _buildOption(
              ctx, colors,
              icon: Icons.stars,
              label: '消耗 $pointsCost 积分解锁',
              subtitle: currentPoints >= pointsCost
                ? '当前积分：$currentPoints'
                : '积分不足（当前：$currentPoints）',
              enabled: currentPoints >= pointsCost,
              onTap: () async {
                final ok = await PointsService.instance.unlockFeature(featureId, pointsCost);
                if (ok && ctx.mounted) {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  static Widget _buildOption(
    BuildContext ctx,
    FitTrackColors colors, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? colors.accentGlow.withOpacity(0.08) : colors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? colors.accentGlow.withOpacity(0.3) : colors.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: enabled ? colors.accentGlow : colors.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(
                    color: enabled ? colors.textPrimary : colors.textMuted,
                    fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                  Text(subtitle, style: TextStyle(
                    color: colors.textMuted, fontSize: 12,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
