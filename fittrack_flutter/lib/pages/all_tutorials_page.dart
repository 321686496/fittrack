import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 全部教学页面 —— 展示完整的系统化课程与动作教学列表
///
/// 与教学中心（TutorialListPage）一致的多级分类结构，但不再截断列表：
/// - 顶部目标筛选 Chip 同时作用于"系统化课程"和"动作教学"区段
/// - 动作教学按 TutorialType 多级分类（基础/进阶/专题/高手）
/// - 锁定项展示锁标识与解锁要求，已解锁项可点击查看详情
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
    final courses = _filterGoal == null
        ? CourseLibrary.courses
        : CourseLibrary.getByGoal(_filterGoal!);

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
                  // ── 系统化课程（响应筛选） ────────────────────
                  const SectionHeader(title: '系统化课程'),
                  const SizedBox(height: 12),
                  _buildCourseSection(colors, courses),
                  const SizedBox(height: 20),
                  // ── 动作教学（按类型多级分类） ──────────────
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
  Widget _buildCourseSection(FitTrackColors colors, List<Course> courses) {
    if (courses.isEmpty) {
      return _buildEmpty(colors, '该筛选下暂无系统化课程');
    }
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

  // ── 动作教学区段（按类型多级分类，全部展示） ─────────────────
  Widget _buildTutorialSection(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeSubsection(
          colors,
          type: TutorialType.basic,
          title: '基础教学',
          subtitle: '免费开放 · 覆盖全肌群的基础动作',
        ),
        const SizedBox(height: 20),
        _buildTypeSubsection(
          colors,
          type: TutorialType.advanced,
          title: '进阶教学',
          subtitle: '邀请 1 人激活解锁 3 个进阶动作',
        ),
        const SizedBox(height: 20),
        _buildTypeSubsection(
          colors,
          type: TutorialType.topic,
          title: '专题教学包',
          subtitle: '累计邀请 3 人激活解锁完整分化指南',
        ),
        const SizedBox(height: 20),
        _buildTypeSubsection(
          colors,
          type: TutorialType.master,
          title: '高手教学',
          subtitle: '累计邀请 5 人激活解锁高手级课程',
        ),
      ],
    );
  }

  /// 单个教学类型子区段（全部列表，不截断）
  Widget _buildTypeSubsection(
    FitTrackColors colors, {
    required TutorialType type,
    required String title,
    required String subtitle,
  }) {
    final tutorials = TutorialLibrary.getByGoalAndType(_filterGoal, type);
    final unlocked = _isTypeUnlocked(type);

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
            const Spacer(),
            Text('${tutorials.length} 项',
                style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(color: colors.textMuted, fontSize: 11)),
        const SizedBox(height: 10),
        if (tutorials.isEmpty)
          _buildEmpty(colors, '该筛选下暂无$title')
        else
          Column(
            children: tutorials
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.play_circle_outline,
                size: 48, color: colors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(text,
                style: TextStyle(color: colors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
