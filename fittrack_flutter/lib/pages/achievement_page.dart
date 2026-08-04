import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/achievement_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  List<Achievement> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await AchievementService.instance.init();
    await AchievementService.instance.evaluateAchievements();
    if (!mounted) return;
    setState(() {
      _all = AchievementService.instance.getAll();
      _loading = false;
    });
  }

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'streak': return Icons.local_fire_department;
      case 'weight': return Icons.fitness_center;
      case 'duration': return Icons.timer;
      case 'month': return Icons.calendar_month;
      case 'explore': return Icons.explore;
      case 'plan': return Icons.assignment_turned_in;
      case 'share': return Icons.share;
      default: return Icons.emoji_events;
    }
  }

  String _categoryLabel(String cat) {
    const map = {
      'streak': '连续训练',
      'weight': '重量里程碑',
      'duration': '时长里程碑',
      'month': '月度坚持',
      'explore': '动作探索',
      'plan': '计划完成',
      'share': '分享成就',
    };
    return map[cat] ?? cat;
  }

  /// 简单相对时间格式化（不引入 timeago 包）
  /// 输入：毫秒时间戳；输出："刚刚 / X 分钟前 / X 小时前 / X 天前 / X 个月前 / X 年前"
  String _formatRelativeTime(int ts) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - ts;
    if (diff < 0) return '刚刚';
    final minutes = diff ~/ 60000;
    if (minutes < 1) return '刚刚';
    if (minutes < 60) return '$minutes 分钟前';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours 小时前';
    final days = hours ~/ 24;
    if (days < 30) return '$days 天前';
    final months = days ~/ 30;
    if (months < 12) return '$months 个月前';
    final years = months ~/ 12;
    return '$years 年前';
  }

  /// 组内排序：已解锁排前（按 unlockedAt 倒序），未解锁排后（保持原始顺序）
  void _sortItemsInPlace(List<Achievement> items) {
    items.sort((a, b) {
      if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
      if (a.unlocked && b.unlocked) {
        return (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0);
      }
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.bgSecondary,
        body: Column(
          children: [
            PageHeader(
              title: '成就墙',
              isTabPage: false,
              onBack: () => context.pop(),
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    // 按 category 分组（保留原有顺序）
    const categoryOrder = ['streak', 'weight', 'duration', 'month', 'explore', 'plan', 'share'];
    final grouped = <String, List<Achievement>>{};
    for (final cat in categoryOrder) {
      final items = _all.where((a) => a.category == cat).toList();
      if (items.isNotEmpty) {
        // 组内排序：已解锁优先（按 unlockedAt 倒序），未解锁排后
        _sortItemsInPlace(items);
        grouped[cat] = items;
      }
    }

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '成就墙',
            isTabPage: false,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部进度摘要
                  _buildSummary(colors),
                  const SizedBox(height: 24),
                  // 按 category 分组列表
                  ...grouped.entries.map((entry) => _buildCategorySection(
                      colors, _categoryLabel(entry.key), entry.value)),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(LiftTrackColors colors) {
    final unlocked = _all.where((a) => a.unlocked).length;
    final total = _all.length;
    final pct = total > 0 ? (unlocked / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentGlow.withOpacity(0.1),
            colors.accentGlow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? unlocked / total : 0,
                  strokeWidth: 4,
                  backgroundColor: colors.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accentGlow),
                ),
                Text('$pct%',
                    style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('总进度',
                    style: TextStyle(color: colors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('$unlocked / $total',
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(LiftTrackColors colors, String title,
      List<Achievement> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: 8),
        ...items.map((a) => _buildAchievementItem(colors, a)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAchievementItem(LiftTrackColors colors, Achievement a) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: a.title,
        content: a.unlocked
            ? '${a.description}\n\n解锁于 ${a.unlockedAt != null ? _formatRelativeTime(a.unlockedAt!) : '已解锁'}'
            : '未解锁\n\n解锁条件：${a.description}',
        icon: _iconFor(a.icon),
        iconColor: a.unlocked ? colors.accentGlow : colors.textMuted,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // 已解锁背景 accentGlow(0.15)，未解锁保持 bgCard
          color: a.unlocked
              ? colors.accentGlow.withOpacity(0.15)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: a.unlocked
                ? colors.accentGlow.withOpacity(0.3)
                : colors.borderColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: a.unlocked
                    ? colors.accentGlow.withOpacity(0.15)
                    : colors.borderColor.withOpacity(0.3),
              ),
              child: Icon(
                _iconFor(a.icon),
                size: 22,
                color: a.unlocked ? colors.accentGlow : colors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(a.description,
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_buildPointsBadge(a) != null) ...[
                    _buildPointsBadge(a)!,
                    const SizedBox(height: 4),
                  ],
                  if (a.unlocked && a.unlockedAt != null) ...[
                    Icon(Icons.check_circle,
                        color: colors.successColor, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(a.unlockedAt!),
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 10),
                    ),
                  ] else if (a.unlocked)
                    Icon(Icons.check_circle,
                        color: colors.successColor, size: 22)
                  else
                    Icon(Icons.lock_outline,
                        color: colors.textMuted, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 积分标记徽章：
  /// - canEarnPoints && pointsReward > 0 → purple "+N积分"
  /// - !canEarnPoints → info "纯荣誉"
  Widget? _buildPointsBadge(Achievement a) {
    if (a.canEarnPoints && a.pointsReward > 0) {
      return BadgeWidget(
        text: '+${a.pointsReward}积分',
        variant: BadgeVariant.purple,
      );
    }
    if (!a.canEarnPoints) {
      return const BadgeWidget(
        text: '纯荣誉',
        variant: BadgeVariant.info,
      );
    }
    return null;
  }
}
