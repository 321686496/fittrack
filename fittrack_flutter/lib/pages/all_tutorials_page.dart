import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 全部教学页面 —— 展示完整的系统化课程与动作教学列表
///
/// 与教学中心（TutorialListPage）不同，本页不再截断列表，并提供顶部
/// 目标筛选 Chip 用于过滤动作教学。卡片样式与 TutorialListPage 保持一致。
class AllTutorialsPage extends StatefulWidget {
  const AllTutorialsPage({super.key});

  @override
  State<AllTutorialsPage> createState() => _AllTutorialsPageState();
}

class _AllTutorialsPageState extends State<AllTutorialsPage> {
  FitnessGoal? _filterGoal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '全部教学',
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ── 目标筛选 ─────────────────────────────
                  _buildGoalFilter(colors),
                  const SizedBox(height: 20),
                  // ── 系统化课程（全部） ────────────────────
                  const SectionHeader(title: '系统化课程'),
                  const SizedBox(height: 12),
                  _buildCourseSection(colors),
                  const SizedBox(height: 20),
                  // ── 动作教学（全部，按筛选过滤） ──────────
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

  // ── 筛选 Chip ────────────────────────────────────────────────
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

  // ── 系统化课程列表（全部） ─────────────────────────────────
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

  // ── 动作教学列表（全部，按筛选过滤） ───────────────────────
  Widget _buildTutorialSection(FitTrackColors colors) {
    final tutorials = _filterGoal == null
        ? TutorialLibrary.getBasic()
        : TutorialLibrary.getBasic().where((t) => t.goal == _filterGoal).toList();
    if (tutorials.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.play_circle_outline,
                  size: 48, color: colors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text('该筛选下暂无动作教学',
                  style: TextStyle(color: colors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
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
