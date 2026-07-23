import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/storage.dart';
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
    final courses = _filterGoal == null
        ? CourseLibrary.courses
        : CourseLibrary.getByGoal(_filterGoal!);

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
                  // ── 目标筛选 ──────────────────────────────
                  _buildGoalFilter(colors),
                  const SizedBox(height: 20),
                  // ── 系统化课程（响应筛选）────────────────────
                  const SectionHeader(title: '系统化课程'),
                  const SizedBox(height: 12),
                  _buildCourseSection(colors, courses),
                  const SizedBox(height: 20),
                  // ── 动作教学（按类型多级分类） ───────────────
                  const SectionHeader(title: '动作教学'),
                  const SizedBox(height: 12),
                  _buildTutorialSection(colors),
                  const SizedBox(height: 24),
                  // ── 查看全部教学入口 ─────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/all-tutorials'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.accentGlow),
                        foregroundColor: colors.accentGlow,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('查看全部教学',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
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
        itemCount: (banners.length + courses.length).clamp(0, 3),
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

  /// 系统化课程列表 —— 响应目标筛选，无内容时显示空状态
  Widget _buildCourseSection(FitTrackColors colors, List<Course> courses) {
    if (courses.isEmpty) {
      return _buildEmpty(colors, '该筛选下暂无系统化课程');
    }
    // 教学中心首页只展示前 2 个，完整列表请进入"查看全部教学"
    final display = courses.take(2).toList();
    return Column(
      children: display.map((c) {
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

  /// 动作教学区段 —— 按 TutorialType 多级分类展示，每类均响应目标筛选
  Widget _buildTutorialSection(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeSubsection(
          colors,
          type: TutorialType.basic,
          title: '基础教学',
          subtitle: '免费开放 · 覆盖全肌群的基础动作',
          take: 4,
        ),
        const SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.advanced,
          title: '进阶教学',
          subtitle: '邀请 1 人激活解锁 3 个进阶动作',
          take: 3,
        ),
        const SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.topic,
          title: '专题教学包',
          subtitle: '累计邀请 3 人激活解锁完整分化指南',
          take: 3,
        ),
        const SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.master,
          title: '高手教学',
          subtitle: '累计邀请 5 人激活解锁高手级课程',
          take: 2,
        ),
      ],
    );
  }

  /// 单个教学类型子区段
  Widget _buildTypeSubsection(
    FitTrackColors colors, {
    required TutorialType type,
    required String title,
    required String subtitle,
    required int take,
  }) {
    final tutorials = TutorialLibrary.getByGoalAndType(_filterGoal, type);
    final unlocked = _isTypeUnlocked(type);
    final display = tutorials.take(take).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (unlocked ? colors.accentGlow : colors.textMuted)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.label,
                style: TextStyle(
                  color: unlocked ? colors.accentGlow : colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            if (!unlocked)
              Icon(Icons.lock_outline, size: 14, color: colors.textMuted),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(color: colors.textMuted, fontSize: 11)),
        const SizedBox(height: 10),
        if (display.isEmpty)
          _buildEmpty(colors, '该筛选下暂无$title')
        else
          Column(
            children: display
                .map((t) => _buildTutorialCard(colors, t, unlocked))
                .toList(),
          ),
      ],
    );
  }

  /// 单个教学卡片 —— 锁定状态下显示锁标识与解锁提示
  Widget _buildTutorialCard(FitTrackColors colors, Tutorial t, bool unlocked) {
    return GestureDetector(
      onTap: () {
        if (unlocked) {
          context.push('/tutorial/${t.id}');
        } else {
          FitToast.info(context, t.unlockRequirement ?? '邀请好友激活后解锁');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? colors.bgCard : colors.bgCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked ? colors.borderColor : colors.borderColor.withOpacity(0.5),
          ),
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
              child: unlocked
                  ? Icon(Icons.play_circle_outline,
                      color: colors.accentGlow, size: 22)
                  : Icon(Icons.lock_outline,
                      color: colors.textMuted, size: 20),
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
                  Text(
                    unlocked
                        ? t.coachName
                        : (t.unlockRequirement ?? '邀请好友激活后解锁'),
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  /// 判断某个教学类型是否已解锁
  bool _isTypeUnlocked(TutorialType type) {
    final settings = Storage.getSettings();
    switch (type) {
      case TutorialType.basic:
        return true;
      case TutorialType.advanced:
        final n = (settings['unlockedAdvancedTutorials'] as num?)?.toInt() ?? 0;
        return n > 0;
      case TutorialType.topic:
        // 专题包需要累计邀请 3 人激活
        final invited = (settings['myReferralCodes'] as List?)?.length ?? 0;
        return invited >= 3;
      case TutorialType.master:
        return settings['unlockedMasterTutorials'] == true;
    }
  }

  Widget _buildEmpty(FitTrackColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.play_circle_outline,
                size: 40, color: colors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(text,
                style: TextStyle(color: colors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
