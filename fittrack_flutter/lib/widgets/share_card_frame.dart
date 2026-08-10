import 'package:flutter/material.dart';
import 'poster_theme.dart';

/// 训练记录分享海报（宽度固定 1080，高度随内容自适应）
///
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
class ShareCardFrame extends StatelessWidget {
  final Map<String, dynamic> record;
  final Size size;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const ShareCardFrame({
    required this.record,
    this.size = const Size(1080, 1920),
    this.themeId,
    super.key,
  });

  /// 海报宽度常量（高度随内容自适应）
  static const double posterWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final name = record['name'] as String? ?? '训练完成';
    final totalWeight = record['totalWeight'] as int? ?? 0;
    final totalSets = record['totalSets'] as int? ?? 0;
    final duration = record['duration'] as int? ?? 0;
    final dateTs = record['date'] as int? ?? 0;
    final date = dateTs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dateTs)
        : DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final durationStr = '${(duration / 60).floor()}分钟';

    return PosterBackground(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            PosterBrandHeader(
              colors: colors,
              subtitle: '今日训练完成',
            ),
            const SizedBox(height: 72),
            // ── 训练名称（核心标题）──────────────────────
            Text(
              name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 56,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // 日期
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 22, color: colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // ── 核心数据：总重量（大数字）──────────────
            Center(
              child: Column(
                children: [
                  Text(
                    '$totalWeight',
                    style: TextStyle(
                      fontSize: 140,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ).createShader(
                          const Rect.fromLTWH(0, 0, 400, 140),
                        ),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '总重量 (kg)',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 26,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // ── 数据卡片网格（组数 + 时长）──────────────
            Row(
              children: [
                _buildStatCard(
                  Icons.repeat_rounded,
                  '$totalSets',
                  '总组数',
                  colors,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  Icons.timer_outlined,
                  durationStr,
                  '训练时长',
                  colors,
                ),
              ],
            ),
            const SizedBox(height: 48),
            // ── slogan ──────────────────────────────
            Center(
              child: Text(
                'LiftTrack · 记录每一组',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // ── 底部二维码 ───────────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://share',
              hint: '扫码开始训练',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, PosterColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: colors.brand, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
