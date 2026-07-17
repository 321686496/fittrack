import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/tutorial_content.dart';
import '../data/course_content.dart';
import '../services/recommendation_service.dart';
import '../widgets/tutorial_cover_card.dart';
import '../widgets/page_header.dart';

/// v1 教学信息列表页
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E2
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.2
///
/// 展示策略：
/// - 推荐 tab：个性化推荐（教学 banner + 精选课程）+ "查看更多"按钮
/// - 全部 tab：基础教学（免费）按肌群过滤 + 系统化课程 + 动作教学
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const PageHeader(title: '教学中心', isTabPage: true),
          Container(
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              border: Border(bottom: BorderSide(color: colors.borderColor)),
            ),
            child: TabBar(
              labelColor: colors.accentGlow,
              unselectedLabelColor: colors.textMuted,
              indicatorColor: colors.accentGlow,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [Tab(text: '推荐'), Tab(text: '全部')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRecommendTab(colors),
                _buildAllTab(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== 推荐 tab ==========

  Widget _buildRecommendTab(FitTrackColors colors) {
    final banners = RecommendationService.generateBanners()
        .where((b) => b.type == 'teaching' || b.type == 'premium')
        .take(5)
        .toList();
    final recommendedCourses = CourseLibrary.courses.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('为你推荐', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...banners.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildRecommendCard(colors, b),
          )),
          const SizedBox(height: 20),
          Text('精选课程', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...recommendedCourses.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.push('/course/${c.id}'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: c.coverColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(c.coverEmoji, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(c.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.9)),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
              child: const Text('查看更多'),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildRecommendCard(FitTrackColors colors, BannerItem b) {
    return GestureDetector(
      onTap: () {
        if (b.route != null) context.push(b.route!);
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.school, color: colors.accentGlow, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(b.subtitle, style: TextStyle(color: colors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // ========== 全部 tab（保留原有逻辑） ==========

  Widget _buildAllTab(FitTrackColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalFilter(colors),
          const SizedBox(height: 16),
          _buildCourseSection(colors),
          const SizedBox(height: 16),
          _buildTutorialSection(colors),
          const SizedBox(height: 100),
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
