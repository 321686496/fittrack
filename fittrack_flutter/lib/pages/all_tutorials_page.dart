import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';

/// 全部教学页面（v1.3 改版）
///
/// 设计原则（依据 Issue 6）：
/// - 第一大类使用卡片瀑布流的形式排版，类似计划库首页
/// - 五大分类：系统化课程 / 基础教学 / 进阶教学 / 专题教学 / 高手教学
/// - 点击分类卡片进入 TutorialCategoryPage 查看该分类下完整教学列表
class AllTutorialsPage extends StatelessWidget {
  const AllTutorialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;

    // 构建分类数据（含数量统计与解锁状态）
    final categories = _buildCategories();

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '全部教学',
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
            onSearchTap: () => context.push('/tutorial-search'),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '选择教学分类',
                      style: TextStyle(
                        color: ft.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _CategoryCard(category: categories[index]);
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建 5 大分类元数据（含数量与解锁状态）
  List<_TutorialCategory> _buildCategories() {
    final settings = Storage.getSettings();
    final advancedUnlockedCount =
        (settings['unlockedAdvancedTutorials'] as num?)?.toInt() ?? 0;
    final invitedCount = (settings['myReferralCodes'] as List?)?.length ?? 0;
    final masterUnlocked = settings['unlockedMasterTutorials'] == true;

    return [
      _TutorialCategory(
        key: 'system',
        title: '系统化课程',
        subtitle: '从零基础到进阶的完整体系',
        emoji: '📚',
        gradientColors: const [Color(0xFFFF6B35), Color(0xFFFFD700)],
        totalCount: CourseLibrary.courses.length,
        unlockedCount: CourseLibrary.courses.length, // 课程本身可点击查看详情
        requiresUnlock: false,
      ),
      _TutorialCategory(
        key: 'basic',
        title: '基础教学',
        subtitle: '免费开放 · 覆盖全肌群基础动作',
        emoji: '🌱',
        gradientColors: const [Color(0xFF6BCB77), Color(0xFF4DBF60)],
        totalCount: TutorialLibrary.basicTutorials.length,
        unlockedCount: TutorialLibrary.basicTutorials.length,
        requiresUnlock: false,
      ),
      _TutorialCategory(
        key: 'advanced',
        title: '进阶教学',
        subtitle: '邀请 1 人激活解锁 3 个进阶动作',
        emoji: '🚀',
        gradientColors: const [Color(0xFF4D96FF), Color(0xFF6BB6FF)],
        totalCount: TutorialLibrary.advancedTutorials.length,
        unlockedCount: TutorialLibrary.getAdvanced(advancedUnlockedCount).length,
        requiresUnlock: true,
      ),
      _TutorialCategory(
        key: 'topic',
        title: '专题教学包',
        subtitle: '累计邀请 3 人激活解锁完整分化指南',
        emoji: '📦',
        gradientColors: const [Color(0xFFB57BFF), Color(0xFF9C5BE0)],
        totalCount: TutorialLibrary.topicTutorials.length,
        unlockedCount: invitedCount >= 3
            ? TutorialLibrary.topicTutorials.length
            : 0,
        requiresUnlock: true,
      ),
      _TutorialCategory(
        key: 'master',
        title: '高手教学',
        subtitle: '累计邀请 5 人激活解锁高手级课程',
        emoji: '👑',
        gradientColors: const [Color(0xFFFFB347), Color(0xFFFF8C42)],
        totalCount: TutorialLibrary.masterTutorials.length,
        unlockedCount:
            masterUnlocked ? TutorialLibrary.masterTutorials.length : 0,
        requiresUnlock: true,
      ),
    ];
  }
}

/// 教学分类元数据
class _TutorialCategory {
  final String key;
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradientColors;
  final int totalCount;
  final int unlockedCount;
  final bool requiresUnlock;

  const _TutorialCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradientColors,
    required this.totalCount,
    required this.unlockedCount,
    required this.requiresUnlock,
  });

  bool get isUnlocked => !requiresUnlock || unlockedCount > 0;
}

/// 分类卡片 —— 复用 PlanLibraryHomePage 的瀑布流卡片样式
class _CategoryCard extends StatelessWidget {
  final _TutorialCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tutorials/${category.key}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: category.gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // 右上角大 Emoji
            Positioned(
              right: 12,
              top: 12,
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
            // 锁定标识
            if (!category.isUnlocked)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_outline, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '未解锁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 底部信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    category.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${category.unlockedCount}/${category.totalCount} 项可学',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
