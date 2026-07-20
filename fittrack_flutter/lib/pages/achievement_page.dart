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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

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
      if (items.isNotEmpty) grouped[cat] = items;
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

  Widget _buildSummary(FitTrackColors colors) {
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

  Widget _buildCategorySection(FitTrackColors colors, String title,
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

  Widget _buildAchievementItem(FitTrackColors colors, Achievement a) {
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: a.title,
        content: a.description,
        icon: _iconFor(a.icon),
        iconColor: a.unlocked ? colors.accentGlow : colors.textMuted,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: a.unlocked
                ? colors.accentGlow.withOpacity(0.3)
                : colors.borderColor,
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
            if (a.unlocked)
              Icon(Icons.check_circle, color: colors.successColor, size: 22)
            else
              Icon(Icons.lock_outline, color: colors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
