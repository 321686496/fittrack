import 'package:flutter/material.dart';
import 'poster_theme.dart';

/// 健身卡海报（海报5，对应 HTML #5）
///
/// 宽度 1080、高度 1920 固定（9:16）。使用 [PosterBackground] 跟随主题。
/// 布局：品牌头 + 卡类型徽标、坚持标题、渐变大数字（天）、进度卡片、
/// 双数据卡、卡类型/到期标签、底部二维码。
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
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final gymName = (card['gymName'] as String?) ?? '健身房';
    final address = (card['address'] as String?) ?? '';
    final cardType = (card['cardType'] as String?) ?? '月卡';
    final startMs = card['startDate'] as int? ?? 0;
    final endMs = card['endDate'] as int? ?? 0;
    final totalCount = (card['totalCount'] as int?) ?? 0;
    final remainingCount = (card['remainingCount'] as int?) ?? 0;

    // 坚持天数 / 总天数 / 进度
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
    if (usedDays <= 0) usedDays = 1;
    if (totalDays <= 0) totalDays = usedDays;
    final progress = (usedDays / totalDays).clamp(0.0, 1.0);
    final remainingDays = (totalDays - usedDays).clamp(0, 99999);
    final isCountCard = cardType == '次卡';

    // 大数字
    final bigValue = isCountCard ? '$remainingCount' : '$usedDays';
    final bigUnit = isCountCard ? '次' : '天';
    final bigLabel = isCountCard ? '剩余可用' : '累计坚持';

    // 双数据卡
    final v1 = isCountCard ? remainingCount : remainingDays;
    final l1 = isCountCard ? '剩余次数' : '剩余天数';
    final v2 = isCountCard ? totalCount : totalDays;
    final l2 = isCountCard ? '购买次数' : '总天数';

    // 到期日期
    final expireLabel = endMs > 0 ? _formatDate(endMs) : '';

    return SizedBox(
      width: posterWidth,
      height: posterHeight,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            PosterBrandHeader(
              colors: colors,
              subtitle: 'GYM CARD',
              trailing: cardType.isNotEmpty
                  ? PostBadge(text: '$cardType · 通用', colors: colors)
                  : null,
            ),
            // ── 坚持标题 ─────────────────────────
            SizedBox(height: px(16)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '我在 $gymName\n',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(18),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  TextSpan(
                    text: '坚持训练',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(18),
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // ── 渐变大数字 ───────────────────────
            SizedBox(height: px(18)),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bigValue,
                    style: TextStyle(
                      fontSize: px(64),
                      fontWeight: FontWeight.w900,
                      height: 1,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ).createShader(
                          const Rect.fromLTWH(0, 0, 400, 80),
                        ),
                    ),
                  ),
                  SizedBox(width: px(8)),
                  Padding(
                    padding: EdgeInsets.only(bottom: px(6)),
                    child: Text(
                      bigUnit,
                      style: TextStyle(
                        fontSize: px(20),
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: px(2)),
            Center(
              child: Text(
                bigLabel,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: px(10),
                  letterSpacing: 4,
                ),
              ),
            ),
            // ── 进度卡片 ─────────────────────────
            SizedBox(height: px(16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(px(14)),
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(px(16)),
                border: Border.all(color: colors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withOpacity(0.10),
                    blurRadius: px(9),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: px(8),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: 1,
                            child: Container(color: colors.cardBg),
                          ),
                          FractionallySizedBox(
                            widthFactor: progress.toDouble(),
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
                  SizedBox(height: px(10)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% 完成',
                        style: TextStyle(
                          fontSize: px(11),
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isCountCard
                            ? '已用 ${(totalCount - v1).clamp(0, 99999)}'
                            : '剩余 $v1 天',
                        style: TextStyle(
                          fontSize: px(11),
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── 双数据卡 ─────────────────────────
            SizedBox(height: px(12)),
            Row(
              children: [
                _buildStat('$v1', l1, colors),
                SizedBox(width: px(9)),
                _buildStat('$v2', l2, colors),
              ],
            ),
            // ── 到期标签 ─────────────────────────
            SizedBox(height: px(14)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PostBadge(text: cardType, colors: colors),
                if (expireLabel.isNotEmpty) ...[
                  SizedBox(width: px(6)),
                  PostBadge(text: '$expireLabel 到期', colors: colors),
                ],
              ],
            ),
            // ── 详细地址 ─────────────────────────
            if (address.isNotEmpty) ...[
              SizedBox(height: px(12)),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: px(12), vertical: px(9)),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(px(12)),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: px(14), color: colors.brand),
                    SizedBox(width: px(8)),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: px(11),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // ── 底部二维码 ───────────────────────
            const Spacer(),
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://gym',
              hint: 'LiftTrack 训练',
              sub: '坚持 · 看到变化',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, PosterColors colors) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: px(12), vertical: px(12)),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(px(16)),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(9)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: px(18),
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: px(8)),
            Text(
              label,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: px(9),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }
}