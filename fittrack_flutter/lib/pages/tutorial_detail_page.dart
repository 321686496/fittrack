import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/tutorial_content.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/tutorial_share_card.dart';

/// v1 教学详情页
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.2.2
///
/// 展示内容：
/// - 动作名称 + 元信息（肌群/难度/器械/教练署名）
/// - 图文要点（编号列表）
/// - 常见错误（warning 色标识）
/// - 呼吸方法
/// - 替代动作（可跳转）
/// - 底部分享按钮 → 弹出教学分享卡片（含邀请码）
class TutorialDetailPage extends StatelessWidget {
  final String tutorialId;

  const TutorialDetailPage({super.key, required this.tutorialId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final tutorial = TutorialLibrary.getById(tutorialId);

    if (tutorial == null) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: '未找到',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '教学内容不存在',
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: tutorial.name,
            subtitle: '${tutorial.primaryMuscle.label} · ${tutorial.coachName}',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaCard(colors, tutorial),
                  const SizedBox(height: 16),
                  _buildKeyPointsCard(colors, tutorial),
                  const SizedBox(height: 16),
                  _buildMistakesCard(colors, tutorial),
                  const SizedBox(height: 16),
                  if (tutorial.breathingTip != null) ...[
                    _buildBreathingCard(colors, tutorial),
                    const SizedBox(height: 16),
                  ],
                  if (tutorial.alternativeExerciseIds.isNotEmpty) ...[
                    _buildAlternativesCard(colors, tutorial, context),
                    const SizedBox(height: 16),
                  ],
                  if (tutorial.recommendedExerciseIds.isNotEmpty) ...[
                    _buildRecommendedExercisesCard(colors, tutorial, context),
                    const SizedBox(height: 16),
                  ],
                  if (tutorial.type != TutorialType.basic &&
                      tutorial.unlockRequirement != null) ...[
                    _buildUnlockCard(colors, tutorial),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildBottomBar(colors, tutorial, context),
        ],
      ),
    );
  }

  // ── 元信息卡 ──────────────────────────────────────────────

  Widget _buildMetaCard(FitTrackColors colors, Tutorial t) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_muscleIcon(t.primaryMuscle),
                  size: 22, color: colors.accentGlow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetaTag(colors, t.type.label,
                  color: colors.accentGlow.withOpacity(0.1),
                  textColor: colors.accentGlow),
              const SizedBox(width: 8),
              _buildMetaTag(colors, t.primaryMuscle.label,
                  color: colors.bgSecondary,
                  textColor: colors.textSecondary),
              const SizedBox(width: 8),
              _buildMetaTag(colors, t.difficulty.label,
                  color: colors.bgSecondary,
                  textColor: colors.textSecondary),
              if (t.equipment != null) ...[
                const SizedBox(width: 8),
                _buildMetaTag(colors, t.equipment!,
                    color: colors.bgSecondary,
                    textColor: colors.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text(
                '署名：${t.coachName}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(
    FitTrackColors colors,
    String text, {
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── 图文要点 ──────────────────────────────────────────────

  Widget _buildKeyPointsCard(FitTrackColors colors, Tutorial t) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  size: 18, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                '动作要点',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...t.keyPoints.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 常见错误 ──────────────────────────────────────────────

  Widget _buildMistakesCard(FitTrackColors colors, Tutorial t) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 18, color: colors.warningColor),
              const SizedBox(width: 6),
              Text(
                '常见错误',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...t.commonMistakes.map((m) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.close, size: 16, color: colors.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 呼吸方法 ──────────────────────────────────────────────

  Widget _buildBreathingCard(FitTrackColors colors, Tutorial t) {
    return CardWidget(
      child: Row(
        children: [
          Icon(Icons.air_outlined, size: 20, color: colors.accentGlow),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '呼吸方法',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t.breathingTip!,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 替代动作 ──────────────────────────────────────────────

  Widget _buildAlternativesCard(
      FitTrackColors colors, Tutorial t, BuildContext context) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text(
                '替代动作',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: t.alternativeExerciseIds.map((id) {
              final alt = TutorialLibrary.getById(id);
              final name = alt?.name ?? id;
              return GestureDetector(
                onTap: () {
                  if (alt != null) {
                    context.pushReplacement('/tutorial/${alt.id}');
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.accentGlow.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 推荐训练动作 ──────────────────────────────────────────

  Widget _buildRecommendedExercisesCard(FitTrackColors colors, Tutorial t, BuildContext context) {
    final exercises = MockData.exercises
        .where((e) => t.recommendedExerciseIds.contains(e['id']))
        .toList();

    if (exercises.isEmpty) return const SizedBox.shrink();

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text('推荐训练动作', style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          ...exercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.push('/exercise'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline, color: colors.accentGlow, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ex['name'] as String? ?? '',
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  // ── 解锁提示 ──────────────────────────────────────────────

  Widget _buildUnlockCard(FitTrackColors colors, Tutorial t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warningColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 20, color: colors.warningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              t.unlockRequirement!,
              style: TextStyle(
                color: colors.warningColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 底部分享栏 ────────────────────────────────────────────

  Widget _buildBottomBar(
      FitTrackColors colors, Tutorial t, BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colors.bgCard,
          border: Border(top: BorderSide(color: colors.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showShareCard(context, t),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('分享动作'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/invitation'),
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('邀请解锁'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareCard(BuildContext context, Tutorial t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TutorialShareCardSheet(tutorial: t),
    );
  }

  IconData _muscleIcon(MuscleGroup m) {
    switch (m) {
      case MuscleGroup.chest:
        return Icons.favorite_outline;
      case MuscleGroup.back:
        return Icons.accessibility_new;
      case MuscleGroup.leg:
        return Icons.directions_run;
      case MuscleGroup.shoulder:
        return Icons.fitness_center;
      case MuscleGroup.arm:
        return Icons.sports_handball;
      case MuscleGroup.core:
        return Icons.self_improvement;
    }
  }
}
