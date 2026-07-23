import 'package:flutter/material.dart';
import '../data/tutorial_content.dart';
import 'poster_theme.dart';

/// 动作分享海报（1080×1920 竖版）
///
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
class TutorialPoster extends StatelessWidget {
  final Tutorial tutorial;

  /// 二维码内容（默认指向 FitTrack 应用入口）
  final String qrData;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const TutorialPoster({
    super.key,
    required this.tutorial,
    this.qrData = 'fittrack://tutorial',
    this.themeId,
  });

  static const double posterWidth = 1080.0;
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final points = tutorial.keyPoints.take(4).toList();

    return PosterBackground(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            PosterBrandHeader(colors: colors),
            const Spacer(flex: 2),
            // ── 动作名（核心标题）──────────────────────
            Text(
              tutorial.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 52,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            // 教练 + 标签
            if (tutorial.coachName.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 24, color: colors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    tutorial.coachName,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // 难度/肌群/器械 标签
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildTag(tutorial.difficulty.label, colors),
                _buildTag(tutorial.primaryMuscle.label, colors),
                if (tutorial.equipment != null &&
                    tutorial.equipment!.isNotEmpty)
                  _buildTag(tutorial.equipment!, colors),
              ],
            ),
            const Spacer(flex: 2),
            // ── 动作要点卡片 ─────────────────────────
            if (points.isNotEmpty) ...[
              Text(
                '动作要点',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ...points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.brand, colors.brandSecondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 24,
                              color: colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const Spacer(flex: 2),
            // ── 底部二维码 ───────────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: qrData,
              hint: '扫码查看完整教学',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, PosterColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.brand.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.brand.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.brand,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
