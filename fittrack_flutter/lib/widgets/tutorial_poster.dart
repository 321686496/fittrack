import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';

/// 动作分享海报（1080×1920 竖版）
///
/// 用于 [TutorialShareCardSheet] 的"立即分享"按钮：
/// 调用方通过 [Overlay] + [OverflowBox] 离屏渲染本组件，
/// 用 [PosterGenerator.capture] 截图为 PNG 后弹出 [PosterPreviewDialog]。
///
/// 设计依据：docs/superpowers/plans/2026-07-21-app-optimization-batch.md Task 3a
class TutorialPoster extends StatelessWidget {
  final Tutorial tutorial;

  /// 二维码内容（默认指向 FitTrack 应用入口）
  final String qrData;

  const TutorialPoster({
    super.key,
    required this.tutorial,
    this.qrData = 'fittrack://tutorial',
  });

  /// 海报尺寸常量，供调用方 [OverflowBox] 使用
  static const double posterWidth = 1080.0;
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final points = tutorial.keyPoints.take(4).toList();

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
              ft.accentGlow.withOpacity(0.1),
              ft.bgSecondary,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 品牌区 ────────────────────────────────
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
            // ── 动作名 + 教练 ─────────────────────────
            Text(
              tutorial.name,
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (tutorial.coachName.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 22, color: ft.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    tutorial.coachName,
                    style: TextStyle(
                      color: ft.textSecondary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // 难度/肌群/器械 标签行
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildTag(ft, tutorial.difficulty.label),
                _buildTag(ft, tutorial.primaryMuscle.label),
                if (tutorial.equipment != null &&
                    tutorial.equipment!.isNotEmpty)
                  _buildTag(ft, tutorial.equipment!),
              ],
            ),
            const Spacer(),
            // ── 动作要点 ─────────────────────────────
            if (points.isNotEmpty) ...[
              Text(
                '动作要点',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ft.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ...points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            color: ft.successColor, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 22,
                              color: ft.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const Spacer(flex: 2),
            // ── 底部二维码提示 ───────────────────────
            Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    gapless: true,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: ft.textPrimary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: ft.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '扫码查看完整教学',
                        style: TextStyle(
                          fontSize: 20,
                          color: ft.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FitTrack · 燃力训练',
                        style: TextStyle(
                          fontSize: 16,
                          color: ft.textMuted,
                        ),
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

  Widget _buildTag(FitTrackColors ft, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ft.accentGlow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ft.accentGlow.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: ft.accentGlow,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
