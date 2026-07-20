import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/tutorial_content.dart';
import '../services/recommendation_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

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
    final banners = RecommendationService.generateBanners()
        .where((b) => b.type == 'teaching' || b.type == 'premium')
        .toList();
    final courses = CourseLibrary.courses.take(3).toList();

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          const PageHeader(title: '教学中心', isTabPage: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ── 为你推荐横滑区段 ──────────────────────
                  if (banners.isNotEmpty) ...[
                    const SectionHeader(title: '为你推荐'),
                    const SizedBox(height: 12),
                    _buildRecommendRow(colors, banners, courses),
                    const SizedBox(height: 24),
                  ],
                  // ── 肌群筛选 ──────────────────────────────
                  _buildGoalFilter(colors),
                  const SizedBox(height: 20),
                  // ── 系统化课程 ────────────────────────────
                  const SectionHeader(title: '系统化课程'),
                  const SizedBox(height: 12),
                  _buildCourseSection(colors),
                  const SizedBox(height: 20),
                  // ── 动作教学 ──────────────────────────────
                  const SectionHeader(title: '动作教学'),
                  const SizedBox(height: 12),
                  _buildTutorialSection(colors),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendRow(FitTrackColors colors, List<dynamic> banners, List<Course> courses) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: banners.length + courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          if (i < banners.length) {
            final banner = banners[i];
            return GestureDetector(
              onTap: () {
                if (banner.route != null) context.push(banner.route!);
              },
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.accentGlow.withOpacity(0.8),
                      colors.accentGlow.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          } else {
            final course = courses[i - banners.length];
            return GestureDetector(
              onTap: () => context.push('/course/${course.id}'),
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: course.coverColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildGoalFilter(FitTrackColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(colors, '全部', _filterGoal == null, () {
            setState(() => _filterGoal = null);
          }),
          const SizedBox(width: 8),
          ...FitnessGoal.values.map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(colors, g.label, _filterGoal == g, () {
                  setState(() => _filterGoal = g);
                }),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      FitTrackColors colors, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.accentGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? colors.accentGlow : colors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSection(FitTrackColors colors) {
    const courses = CourseLibrary.courses;
    return Column(
      children: courses.map((c) {
        return GestureDetector(
          onTap: () => context.push('/course/${c.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: c.coverColors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(c.coverEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(c.subtitle,
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTutorialSection(FitTrackColors colors) {
    final tutorials = _filterGoal == null
        ? TutorialLibrary.getBasic()
        : TutorialLibrary.getBasic().where((t) => t.goal == _filterGoal).toList();
    return Column(
      children: tutorials.map((t) {
        return GestureDetector(
          onTap: () => context.push('/tutorial/${t.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.play_circle_outline,
                      color: colors.accentGlow, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(t.coachName,
                          style: TextStyle(
                              color: colors.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
