import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

/// 健身卡分享海报（1080×1920 竖版）
///
/// 用于 [GymCardPage] 卡片分享：
/// 调用方通过 [Overlay] + [OverflowBox] 离屏渲染本组件，
/// 用 [PosterGenerator.capture] 截图为 PNG 后弹出 [PosterPreviewDialog]。
///
/// 卡片数据字段（与 [Storage.getGymCards] 一致）：
/// - `gymName` (String?) 健身房名称
/// - `cardType` (String?) 卡类型（年卡/季卡/月卡/次卡/其他）
/// - `startDate` (int?) 开卡时间戳（毫秒）
/// - `endDate` (int?) 到期时间戳（毫秒）
///
/// 设计依据：docs/superpowers/plans/2026-07-21-app-optimization-batch.md Task 3b
class GymCardPoster extends StatelessWidget {
  final Map<String, dynamic> card;

  const GymCardPoster({super.key, required this.card});

  /// 海报尺寸常量，供调用方 [OverflowBox] 使用
  static const double posterWidth = 1080.0;
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
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

    return RepaintBoundary(
      child: Container(
        width: posterWidth,
        height: posterHeight,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ft.accentGlow.withOpacity(0.12),
              ft.bgCard,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            Row(
              children: [
                Icon(Icons.fitness_center, size: 28, color: ft.accentGlow),
                const SizedBox(width: 10),
                Text(
                  'FitTrack 燃力',
                  style: TextStyle(
                    color: ft.accentGlow,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 3,
              decoration: BoxDecoration(
                color: ft.accentGlow,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Spacer(flex: 2),
            // ── 标题"我在 X 健身房坚持训练" ──────────
            Text(
              '我在 $gymName',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '坚持训练',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const Spacer(),
            // ── 大数字（坚持天数）+ "天" ──────────────
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$usedDays',
                    style: TextStyle(
                      fontSize: 144,
                      fontWeight: FontWeight.bold,
                      color: ft.accentGlow,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '天',
                    style: TextStyle(
                      fontSize: 36,
                      color: ft.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // ── 进度条 ───────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(color: ft.borderColor.withOpacity(0.4)),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ft.purpleColor, ft.accentGlow],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% 完成',
                  style: TextStyle(
                    fontSize: 22,
                    color: ft.textSecondary,
                  ),
                ),
                Text(
                  remainingLabel,
                  style: TextStyle(
                    fontSize: 22,
                    color: remainingDays > 0
                        ? ft.textSecondary
                        : ft.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 2),
            // ── 卡类型·健身房名 ─────────────────────
            Center(
              child: Text(
                cardType.isEmpty ? gymName : '$cardType · $gymName',
                style: TextStyle(
                  fontSize: 26,
                  color: ft.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (cardName.isNotEmpty && cardName != gymName) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  cardName,
                  style: TextStyle(
                    fontSize: 20,
                    color: ft.textMuted,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // ── 底部品牌 ─────────────────────────────
            Center(
              child: Text(
                'FitTrack 燃力',
                style: TextStyle(
                  fontSize: 22,
                  color: ft.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
