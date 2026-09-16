import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../services/recommendation_service.dart';
import '../themes/app_themes.dart';
import '../utils/gender_filter.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_refresh_mixin.dart';

import '../l10n/i18n.dart';
/// 教学中心 Tab 页（v1.3 改版）
///
/// 设计原则（依据 Issue 6）：
/// - 只展示推荐数据，不再放目标筛选 tab 栏
/// - 推荐数据：系统横滑 banner + 精选系统化课程 + 精选基础/进阶/专题/高手教学
/// - 底部"查看全部教学"入口跳转 AllTutorialsPage，那里用卡片瀑布流分类
class TutorialListPage extends StatefulWidget {
  TutorialListPage({super.key});

  @override
  State<TutorialListPage> createState() => _TutorialListPageState();
}

class _TutorialListPageState extends State<TutorialListPage>
    with TabRefreshMixin<TutorialListPage> {
  // build 内重计算缓存（在 _refreshCache 中预计算）
  List<BannerItem> _bannersCache = [];
  List<Course> _recommendedCoursesCache = [];

  @override
  int get tabIndex => 2;

  @override
  void onTabBecameActive() {
    // 切换到教学中心时刷新解锁状态与推荐数据
    _refreshCache();
  }

  void _refreshCache() {
    _bannersCache = RecommendationService.generateBanners()
        .where((b) => b.type == 'teaching' || b.type == 'premium')
        .toList();
    _recommendedCoursesCache = CourseLibrary.courses.take(2).toList();
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    _refreshCache();
  }

  @override
  void initState() {
    super.initState();
    _refreshCache();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final banners = _bannersCache;
    final recommendedCourses = _recommendedCoursesCache;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: tr(context, '教学中心'),
            isTabPage: true,
            onSearchTap: () => context.push('/tutorial-search'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.accentGlow,
              backgroundColor: colors.bgCard,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    // ── 为你推荐横滑区段 ──────────────────────
                    if (banners.isNotEmpty) ...[
                      SectionHeader(title: tr(context, '为你推荐')),
                      SizedBox(height: 12),
                      _buildRecommendRow(colors, banners, recommendedCourses),
                      SizedBox(height: 24),
                    ],
                    // ── 精选系统化课程 ─────────────────────────
                    SectionHeader(title: tr(context, '精选系统化课程')),
                    SizedBox(height: 12),
                    _buildRecommendedCourses(colors, recommendedCourses),
                    SizedBox(height: 20),
                    // ── 推荐教学 ──────────────────────────────
                    SectionHeader(title: tr(context, '推荐教学')),
                    SizedBox(height: 12),
                    _buildRecommendedTutorials(colors),
                    SizedBox(height: 24),
                    // ── 查看全部教学入口 ─────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.push('/all-tutorials'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.accentGlow),
                          foregroundColor: colors.accentGlow,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(tr(context, '查看全部教学'),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 横滑推荐卡片（banner + 精选课程封面）
  Widget _buildRecommendRow(
      LiftTrackColors colors, List<dynamic> banners, List<Course> courses) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: (banners.length + courses.length).clamp(0, 4),
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          if (i < banners.length) {
            final banner = banners[i];
            return GestureDetector(
              onTap: () {
                if (banner.route != null) context.push(banner.route!);
              },
              child: Container(
                width: 160,
                padding: EdgeInsets.all(14),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
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
                padding: EdgeInsets.all(14),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
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

  /// 精选系统化课程列表（只展示推荐的 2 个，无筛选）
  Widget _buildRecommendedCourses(
      LiftTrackColors colors, List<Course> courses) {
    if (courses.isEmpty) {
      return _buildEmpty(colors, tr(context, '暂无推荐课程'));
    }
    return Column(
      children: courses.map((c) {
        return GestureDetector(
          onTap: () => context.push('/course/${c.id}'),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
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
                    child: Text(c.coverEmoji, style: TextStyle(fontSize: 24)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
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

  /// 推荐教学：从 4 个类型各取前 N 个作为推荐展示
  Widget _buildRecommendedTutorials(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeSubsection(
          colors,
          type: TutorialType.basic,
          title: tr(context, '基础教学'),
          subtitle: tr(context, '免费开放 · 覆盖全肌群的基础动作'),
          take: 3,
        ),
        SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.advanced,
          title: tr(context, '进阶教学'),
          subtitle: tr(context, '邀请 1 人激活解锁 3 个进阶动作'),
          take: 2,
        ),
        SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.topic,
          title: tr(context, '专题教学包'),
          subtitle: tr(context, '累计邀请 3 人激活解锁完整分化指南'),
          take: 2,
        ),
        SizedBox(height: 16),
        _buildTypeSubsection(
          colors,
          type: TutorialType.master,
          title: tr(context, '高手教学'),
          subtitle: tr(context, '累计邀请 5 人激活解锁高手级课程'),
          take: 1,
        ),
      ],
    );
  }

  /// 单个教学类型子区段（推荐展示，限制数量，无筛选）
  Widget _buildTypeSubsection(
    LiftTrackColors colors, {
    required TutorialType type,
    required String title,
    required String subtitle,
    required int take,
  }) {
    final tutorials = TutorialLibrary.getByType(type)
        .where((t) => genderMatchesUser(t.gender))
        .toList();
    final unlocked = _isTypeUnlocked(type);
    final display = tutorials.take(take).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            SizedBox(width: 8),
            // 英文分组标题更长，用 Expanded 占满剩余宽度并允许换行
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 6),
            if (!unlocked)
              Icon(Icons.lock_outline, size: 14, color: colors.textMuted),
          ],
        ),
        SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(color: colors.textMuted, fontSize: 11)),
        SizedBox(height: 10),
        if (display.isEmpty)
          _buildEmpty(colors, tr(context, '暂无推荐$title'))
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
  Widget _buildTutorialCard(LiftTrackColors colors, Tutorial t, bool unlocked) {
    return GestureDetector(
      onTap: () => context.push('/tutorial/${t.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? colors.bgCard : colors.bgCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? colors.borderColor
                : colors.borderColor.withOpacity(0.5),
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
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(
                    unlocked
                        ? t.coachName
                        : tr(context, '${t.coachName} · 点击查看介绍'),
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
        final n =
            (settings['unlockedAdvancedTutorials'] as num?)?.toInt() ?? 0;
        return n > 0;
      case TutorialType.topic:
        // 专题包需要累计邀请 3 人激活
        final invited = (settings['myReferralCodes'] as List?)?.length ?? 0;
        return invited >= 3;
      case TutorialType.master:
        return settings['unlockedMasterTutorials'] == true;
    }
  }

  Widget _buildEmpty(LiftTrackColors colors, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.play_circle_outline,
                size: 40, color: colors.textMuted.withOpacity(0.4)),
            SizedBox(height: 8),
            Text(text,
                style: TextStyle(color: colors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
