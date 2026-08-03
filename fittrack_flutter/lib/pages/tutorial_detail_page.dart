import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../data/content_block.dart';
import '../data/course_content.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/tutorial_share_card.dart';
import '../widgets/unlock_panel.dart';

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
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
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
          // 未解锁类型的提示横幅（可查看介绍，内容需解锁）
          if (!_isTypeUnlocked(tutorial.type))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: colors.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tutorial.unlockRequirement ?? '该教学需邀请好友激活后解锁，下方可查看简介',
                      style: TextStyle(color: colors.warningColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaCard(colors, tutorial),
                  const SizedBox(height: 16),
                  // 按章节渲染（替代旧的 keyPoints/mistakes/breathing 卡片）
                  ...tutorial.chapters.map((ch) => _buildChapterCard(colors, tutorial, ch, context)),
                  const SizedBox(height: 16),
                  if (tutorial.alternativeExerciseIds.isNotEmpty) ...[
                    _buildAlternativeExercisesCard(colors, tutorial, context),
                    const SizedBox(height: 16),
                  ],
                  if (tutorial.recommendedExerciseIds.isNotEmpty) ...[
                    _buildRecommendedExercisesCard(colors, tutorial, context),
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

  Widget _buildMetaCard(LiftTrackColors colors, Tutorial t) {
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
    LiftTrackColors colors,
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

  // ── 章节卡（按章节渲染 + 单章积分解锁） ──────────────────────

  Widget _buildChapterCard(
    LiftTrackColors colors,
    Tutorial tutorial,
    Chapter chapter,
    BuildContext context,
  ) {
    final isUnlocked = tutorial.isChapterUnlocked(chapter.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUnlocked ? Icons.menu_book : Icons.lock_outline,
                  size: 18,
                  color: isUnlocked ? colors.accentGlow : colors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    chapter.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${tutorial.chapterPointsCost} 积分',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (isUnlocked) ...[
              // 已解锁：渲染 blocks
              ...chapter.blocks.map((b) => _buildContentBlock(colors, b, context)),
            ] else ...[
              // 未解锁：显示提示文案 + 解锁按钮
              Text(
                '本章内容已锁定，观看广告或消耗积分即可解锁',
                style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await UnlockPanel.show(
                      context: context,
                      title: '解锁《${chapter.title}》',
                      description: '该章节属于「${tutorial.type.label}」教学',
                      pointsCost: tutorial.chapterPointsCost,
                      featureId: tutorial.chapterFeatureId(chapter.id),
                    );
                    if (ok && context.mounted) {
                      // 触发重建
                      (context as Element).markNeedsBuild();
                    }
                  },
                  icon: const Icon(Icons.lock_open, size: 16),
                  label: const Text('解锁本章'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.white,
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
      ),
    );
  }

  Widget _buildContentBlock(
    LiftTrackColors colors,
    ContentBlock block,
    BuildContext context,
  ) {
    // 复用 course_detail_page 已有的 ContentBlock 渲染逻辑
    // 简化版本：
    switch (block.type) {
      case BlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Text(
            block.text ?? '',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            block.text ?? '',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
          ),
        );
      case BlockType.bulletList:
        return Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
              Expanded(
                child: Text(
                  block.text ?? '',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
                ),
              ),
            ],
          ),
        );
      case BlockType.callout:
        final isWarning = block.calloutType == 'warning';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isWarning ? colors.warningColor : colors.accentGlow).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isWarning ? colors.warningColor : colors.accentGlow).withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.warning_amber : Icons.info_outline,
                size: 16,
                color: isWarning ? colors.warningColor : colors.accentGlow,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  block.text ?? '',
                  style: TextStyle(
                    color: isWarning ? colors.warningColor : colors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── 替代动作（可点击卡片，跳转到对应教学详情） ────────────────

  Widget _buildAlternativeExercisesCard(
      LiftTrackColors colors, Tutorial t, BuildContext context) {
    // alternativeExerciseIds 存储的是教学 ID，查找对应的教学项
    final alternatives = t.alternativeExerciseIds
        .map((id) => TutorialLibrary.getById(id))
        .whereType<Tutorial>()
        .toList();

    if (alternatives.isEmpty) return const SizedBox.shrink();

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text('替代动作', style: TextStyle(
                color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 12),
          ...alternatives.map((alt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.push('/tutorial/${alt.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _muscleIcon(alt.primaryMuscle),
                        color: colors.accentGlow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alt.name,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${alt.primaryMuscle.label} · ${alt.difficulty.label}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
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

  // ── 推荐训练动作 ──────────────────────────────────────────

  Widget _buildRecommendedExercisesCard(LiftTrackColors colors, Tutorial t, BuildContext context) {
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

  // ── 底部分享栏 ────────────────────────────────────────────

  /// 判断教学类型是否已解锁（用于控制"邀请加速解锁"按钮的显示）
  bool _isTypeUnlocked(TutorialType type) {
    final settings = Storage.getSettings();
    switch (type) {
      case TutorialType.basic:
        return true;
      case TutorialType.advanced:
        final n = (settings['unlockedAdvancedTutorials'] as num?)?.toInt() ?? 0;
        return n > 0;
      case TutorialType.topic:
        final invited = (settings['myReferralCodes'] as List?)?.length ?? 0;
        return invited >= 3;
      case TutorialType.master:
        return settings['unlockedMasterTutorials'] == true;
    }
  }

  Widget _buildBottomBar(
      LiftTrackColors colors, Tutorial t, BuildContext context) {
    final typeUnlocked = _isTypeUnlocked(t.type);
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
            // 已解锁类型不显示"邀请加速解锁"按钮
            if (!typeUnlocked) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/invitation'),
                  icon: const Icon(Icons.card_giftcard, size: 18),
                  label: const Text('邀请加速解锁'),
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
