import 'package:flutter/material.dart';
import 'poster_theme.dart';

/// 健身卡分享海报（宽度固定 1080，高度随内容自适应）
///
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
class GymCardPoster extends StatelessWidget {
  final Map<String, dynamic> card;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const GymCardPoster({
    super.key,
    required this.card,
    this.themeId,
  });

  static const double posterWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final gymName = (card['gymName'] as String?) ?? '健身房';
    final cardType = (card['cardType'] as String?) ?? '';
    final cardName = (card['name'] as String?) ?? '';
    final startMs = card['startDate'] as int? ?? 0;
    final endMs = card['endDate'] as int? ?? 0;

    // 计算坚持天数与总天数
    final now = DateTime.now();
    int usedDays = 0;
    int totalDays = 0;
    if (startMs > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(startMs);
      usedDays = now.difference(start).inDays;
      if (usedDays < 0) usedDays = 0;
      if (endMs > 0) {
        final end = DateTime.fromMillisecondsSinceEpoch(endMs);
        totalDays = end.difference(start).inDays;
      }
    }
    if (totalDays <= 0) totalDays = usedDays > 0 ? usedDays : 1;
    final progress = (usedDays / totalDays).clamp(0.0, 1.0);
    final remainingDays = totalDays - usedDays;
    final remainingLabel =
        remainingDays > 0 ? '剩余 $remainingDays 天' : '已到期';

    return PosterBackground(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            PosterBrandHeader(colors: colors),
            const SizedBox(height: 48),
            // ── 标题 ─────────────────────────────────
            Text(
              '我在 $gymName',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '坚持训练',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 48),
            // ── 大数字（坚持天数）──────────────────────
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$usedDays',
                    style: TextStyle(
                      fontSize: 160,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ).createShader(
                          const Rect.fromLTWH(0, 0, 400, 160),
                        ),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '天',
                    style: TextStyle(
                      fontSize: 40,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '累计坚持',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 24,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // ── 进度卡片 ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: [
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 16,
                      child: Stack(
                        children: [
                          Container(color: Colors.white.withOpacity(0.08)),
                          FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.brand,
                                    colors.brandSecondary,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% 完成',
                        style: TextStyle(
                          fontSize: 24,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        remainingLabel,
                        style: TextStyle(
                          fontSize: 24,
                          color: remainingDays > 0
                              ? colors.textSecondary
                              : colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // ── 健身房信息 ───────────────────────────
            Center(
              child: Column(
                children: [
                  if (cardType.isNotEmpty)
                    Text(
                      cardType,
                      style: TextStyle(
                        fontSize: 28,
                        color: colors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (cardName.isNotEmpty && cardName != gymName) ...[
                    const SizedBox(height: 6),
                    Text(
                      cardName,
                      style: TextStyle(
                        fontSize: 22,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            // ── 底部二维码 ───────────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://gym',
              hint: 'LiftTrack 燃力训练',
            ),
          ],
        ),
      ),
    );
  }
}
