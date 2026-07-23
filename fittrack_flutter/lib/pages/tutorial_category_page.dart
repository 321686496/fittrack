import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 教学分类详情页（v1.3 新增）
///
/// 由 AllTutorialsPage 的瀑布流卡片点击进入。
/// 根据传入的 [categoryKey] 渲染对应分类下的全部教学项：
/// - system: 系统化课程列表（Course）
/// - basic/advanced/topic/master: 对应 TutorialType 的全部 Tutorial
class TutorialCategoryPage extends StatefulWidget {
  final String categoryKey;

  const TutorialCategoryPage({
    super.key,
    required this.categoryKey,
  });

  @override
  State<TutorialCategoryPage> createState() => _TutorialCategoryPageState();
}

class _TutorialCategoryPageState extends State<TutorialCategoryPage> {
  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final meta = _categoryMeta(widget.categoryKey);
    if (meta == null) {
      return Scaffold(
        backgroundColor: ft.bgSecondary,
        body: Column(
          children: [
            PageHeader(
              title: '未知分类',
              isTabPage: false,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text('分类不存在',
                    style: TextStyle(color: ft.textMuted, fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    final isSystemCategory = widget.categoryKey == 'system';
    final courses = isSystemCategory ? CourseLibrary.courses : <Course>[];
    final tutorials = isSystemCategory
        ? <Tutorial>[]
        : TutorialLibrary.getByType(meta.type!);

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: meta.title,
            subtitle: meta.subtitle,
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
          ),
          // 顶部解锁提示条
          if (meta.requiresUnlock && !meta.isUnlocked)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ft.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ft.warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: ft.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta.unlockHint,
                      style:
                          TextStyle(color: ft.warningColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: isSystemCategory
                ? _buildCourseList(ft, courses)
                : _buildTutorialList(ft, tutorials, meta),
          ),
        ],
      ),
    );
  }

  /// 系统化课程列表
  Widget _buildCourseList(FitTrackColors ft, List<Course> courses) {
    if (courses.isEmpty) {
      return _buildEmpty(ft, '暂无系统化课程');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = courses[index];
        return GestureDetector(
          onTap: () => context.push('/course/${c.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ft.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ft.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: c.coverColors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(c.coverEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: TextStyle(
                              color: ft.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(c.subtitle,
                          style:
                              TextStyle(color: ft.textMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildMetaChip(ft,
                              c.difficulty.label, ft.accentGlow.withOpacity(0.15), ft.accentGlow),
                          _buildMetaChip(ft,
                              '${c.chapters.length} 章', ft.infoColor.withOpacity(0.15), ft.infoColor),
                          _buildMetaChip(ft,
                              c.pointsCost == 0 ? '免费' : '${c.pointsCost}积分',
                              c.pointsCost == 0
                                  ? ft.successColor.withOpacity(0.15)
                                  : ft.warningColor.withOpacity(0.15),
                              c.pointsCost == 0
                                  ? ft.successColor
                                  : ft.warningColor),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: ft.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 教学动作列表
  Widget _buildTutorialList(
      FitTrackColors ft, List<Tutorial> tutorials, _CategoryMeta meta) {
    if (tutorials.isEmpty) {
      return _buildEmpty(ft, '暂无${meta.title}');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final t = tutorials[index];
        final unlocked = !meta.requiresUnlock || meta.isUnlocked;
        return _buildTutorialCard(ft, t, unlocked);
      },
    );
  }

  Widget _buildTutorialCard(FitTrackColors ft, Tutorial t, bool unlocked) {
    return GestureDetector(
      onTap: () {
        if (unlocked) {
          context.push('/tutorial/${t.id}');
        } else {
          FitToast.info(context, t.unlockRequirement ?? '邀请好友激活后解锁');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked ? ft.bgCard : ft.bgCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? ft.borderColor
                : ft.borderColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ft.accentGlow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: unlocked
                  ? Icon(Icons.play_circle_outline,
                      color: ft.accentGlow, size: 22)
                  : Icon(Icons.lock_outline, color: ft.textMuted, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.name,
                            style: TextStyle(
                                color: ft.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (t.difficulty != TutorialDifficulty.beginner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ft.purpleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.difficulty.label,
                            style: TextStyle(
                                color: ft.purpleColor, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? '${t.coachName} · ${t.primaryMuscle.label}'
                        : (t.unlockRequirement ?? '邀请好友激活后解锁'),
                    style: TextStyle(color: ft.textMuted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (unlocked && t.equipment != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '器械：${t.equipment}',
                      style: TextStyle(color: ft.textMuted, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: ft.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(
      FitTrackColors ft, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 10)),
    );
  }

  Widget _buildEmpty(FitTrackColors ft, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline,
              size: 48, color: ft.textMuted.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: ft.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  /// 根据 categoryKey 查询分类元数据
  _CategoryMeta? _categoryMeta(String key) {
    final settings = Storage.getSettings();
    final advancedUnlockedCount =
        (settings['unlockedAdvancedTutorials'] as num?)?.toInt() ?? 0;
    final invitedCount = (settings['myReferralCodes'] as List?)?.length ?? 0;
    final masterUnlocked = settings['unlockedMasterTutorials'] == true;

    switch (key) {
      case 'system':
        return const _CategoryMeta(
          title: '系统化课程',
          subtitle: '从零基础到进阶的完整体系',
          type: null,
          requiresUnlock: false,
          isUnlocked: true,
          unlockHint: '',
        );
      case 'basic':
        return const _CategoryMeta(
          title: '基础教学',
          subtitle: '免费开放 · 覆盖全肌群基础动作',
          type: TutorialType.basic,
          requiresUnlock: false,
          isUnlocked: true,
          unlockHint: '',
        );
      case 'advanced':
        return _CategoryMeta(
          title: '进阶教学',
          subtitle: '邀请 1 人激活解锁 3 个进阶动作',
          type: TutorialType.advanced,
          requiresUnlock: true,
          isUnlocked: advancedUnlockedCount > 0,
          unlockHint: '邀请 1 人激活即可解锁全部进阶教学',
        );
      case 'topic':
        return _CategoryMeta(
          title: '专题教学包',
          subtitle: '累计邀请 3 人激活解锁完整分化指南',
          type: TutorialType.topic,
          requiresUnlock: true,
          isUnlocked: invitedCount >= 3,
          unlockHint: '累计邀请 3 人激活即可解锁全部专题教学',
        );
      case 'master':
        return _CategoryMeta(
          title: '高手教学',
          subtitle: '累计邀请 5 人激活解锁高手级课程',
          type: TutorialType.master,
          requiresUnlock: true,
          isUnlocked: masterUnlocked,
          unlockHint: '累计邀请 5 人激活即可解锁全部高手教学',
        );
      default:
        return null;
    }
  }
}

/// 分类元数据
class _CategoryMeta {
  final String title;
  final String subtitle;
  final TutorialType? type; // system 类目为 null
  final bool requiresUnlock;
  final bool isUnlocked;
  final String unlockHint;

  const _CategoryMeta({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.requiresUnlock,
    required this.isUnlocked,
    required this.unlockHint,
  });
}
