import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/course_content.dart';
import '../data/tutorial_content.dart';
import '../services/points_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/unlock_panel.dart';
import '../widgets/page_header.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final course = CourseLibrary.getById(widget.courseId);
    if (course == null) return const Scaffold(body: Center(child: Text('课程不存在')));

    final isUnlocked = PointsService.instance.isFeatureUnlocked(course.id);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: course.title,
            subtitle: course.subtitle,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCourseInfoCard(colors, course, isUnlocked),
                const SizedBox(height: 20),
                // 章节列表标题
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 18, color: colors.accentGlow),
                    const SizedBox(width: 8),
                    Text('课程章节',
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${course.chapters.length} 章',
                        style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                ...course.chapters.asMap().entries.map((entry) {
                  return _buildChapterItem(
                      colors, course, entry.value, entry.key, isUnlocked);
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 课程基本信息卡（封面、标签、描述、解锁状态）
  Widget _buildCourseInfoCard(
      LiftTrackColors colors, Course course, bool isUnlocked) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面 + 标题
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: course.coverColors),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(course.coverEmoji,
                      style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(course.subtitle,
                        style:
                            TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 标签行
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildInfoChip(colors, course.difficulty.label, colors.accentGlow),
              _buildInfoChip(colors, course.goal.label, colors.infoColor),
              _buildInfoChip(
                  colors, '${course.chapters.length} 章', colors.purpleColor),
              _buildInfoChip(
                colors,
                course.pointsCost == 0 ? '免费' : '${course.pointsCost} 积分',
                course.pointsCost == 0
                    ? colors.successColor
                    : colors.warningColor,
              ),
              _buildInfoChip(
                colors,
                isUnlocked ? '已解锁' : '未解锁',
                isUnlocked ? colors.successColor : colors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 描述
          Text(course.description,
              style:
                  TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 10),
          // 教练署名
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: colors.textMuted),
              const SizedBox(width: 4),
              Text('教练：${course.coachName}',
                  style: TextStyle(color: colors.textMuted, fontSize: 12)),
            ],
          ),
          // 未解锁时显示解锁按钮
          if (!isUnlocked) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final unlocked = await UnlockPanel.show(
                    context: context,
                    title: course.title,
                    description: course.description,
                    pointsCost: course.pointsCost,
                    featureId: course.id,
                  );
                  if (unlocked && mounted) setState(() {});
                },
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('解锁全部课程'),
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
    );
  }

  Widget _buildInfoChip(LiftTrackColors colors, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  /// 单个章节项
  Widget _buildChapterItem(LiftTrackColors colors, Course course, Chapter ch,
      int index, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: isUnlocked
          ? () => context.push('/course/${course.id}/chapter/${ch.id}')
          : () async {
              final unlocked = await UnlockPanel.show(
                context: context,
                title: course.title,
                description: course.description,
                pointsCost: course.pointsCost,
                featureId: course.id,
              );
              if (unlocked && mounted) setState(() {});
            },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(ch.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Icon(
                isUnlocked ? Icons.chevron_right : Icons.lock_outline,
                color: colors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
