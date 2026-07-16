import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/tutorial_content.dart';
import '../data/course_content.dart';
import '../widgets/tutorial_cover_card.dart';
import '../widgets/page_header.dart';

/// v1 教学信息列表页
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.2
///
/// 展示策略：
/// - 基础教学（免费）：30个，按肌群过滤
/// - 进阶/专题/高手教学（裂变解锁）：展示但锁定，点击提示解锁方式
class TutorialListPage extends StatefulWidget {
  const TutorialListPage({super.key});

  @override
  State<TutorialListPage> createState() => _TutorialListPageState();
}

class _TutorialListPageState extends State<TutorialListPage> {
  FitnessGoal? _filterGoal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: '教学中心', subtitle: '动作教学 · 系统化课程', onBack: () => Navigator.of(context).pop()),
          _buildGoalFilter(colors),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseSection(colors), // 系统化课程
                  const SizedBox(height: 16),
                  _buildTutorialSection(colors), // 按目标分类的教学
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalFilter(FitTrackColors colors) {
    final goals = [FitnessGoal.bulk, FitnessGoal.cut, FitnessGoal.maintain];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip(colors, '全部', _filterGoal == null, () => setState(() => _filterGoal = null)),
          ...goals.map((g) => _filterChip(colors, g.label, _filterGoal == g, () => setState(() => _filterGoal = g))),
        ],
      ),
    );
  }

  Widget _filterChip(FitTrackColors colors, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.accentGlow : colors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? colors.accentGlow : colors.borderColor),
          ),
          child: Text(label, style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary, fontSize: 13,
          )),
        ),
      ),
    );
  }

  Widget _buildCourseSection(FitTrackColors colors) {
    const courses = CourseLibrary.courses;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('系统化课程', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...courses.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => context.push('/course/${c.id}'),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: c.coverColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(c.coverEmoji, style: const TextStyle(fontSize: 40)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(c.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTutorialSection(FitTrackColors colors) {
    final tutorials = _filterGoal == null
      ? TutorialLibrary.getBasic()
      : TutorialLibrary.getBasic().where((t) => t.goal == _filterGoal).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('动作教学', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tutorials.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TutorialCoverCard(tutorial: t, onTap: () => context.push('/tutorial/${t.id}')),
        )),
      ],
    );
  }
}
