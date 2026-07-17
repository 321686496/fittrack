import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../services/achievement_service.dart';
import '../widgets/common_widgets.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  List<Achievement> _all = [];
  List<Achievement> _unlocked = [];

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
      _unlocked = _all.where((a) => a.unlocked).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    // 按 category 分组
    final groups = <String, List<Achievement>>{};
    for (final a in _all) {
      final cat = a.category;
      groups.putIfAbsent(cat, () => []).add(a);
    }
    const categoryOrder = ['streak', 'weight', 'duration', 'month', 'explore', 'plan', 'share'];
    const categoryLabels = {
      'streak': '连续打卡',
      'weight': '重量里程碑',
      'duration': '训练时长',
      'month': '月度坚持',
      'explore': '动作探索',
      'plan': '计划完成',
      'share': '分享徽章',
    };

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      appBar: AppBar(
        backgroundColor: colors.bgSecondary,
        title: Text('成就与荣誉', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: _all.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ========== 荣誉墙 ==========
                Text('荣誉墙', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('已解锁 ${_unlocked.length}/${_all.length} 个成就', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accentGlow.withOpacity(0.05), colors.accentGlow.withOpacity(0.02)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: _unlocked.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.lock_outline, size: 48, color: colors.textMuted),
                              const SizedBox(height: 12),
                              Text('完成训练解锁首个徽章', style: TextStyle(color: colors.textMuted, fontSize: 14)),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _unlocked.length,
                        itemBuilder: (ctx, i) {
                          final a = _unlocked[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.accentGlow.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(
                                    color: colors.accentGlow.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_achievementIcon(a.icon), size: 32, color: colors.accentGlow),
                                ),
                                const SizedBox(height: 8),
                                Text(a.title, style: TextStyle(
                                  color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold,
                                ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(a.description, style: TextStyle(
                                  color: colors.textMuted, fontSize: 10,
                                ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                if (a.unlockedAt != null) ...[
                                  const SizedBox(height: 4),
                                  Text(_formatDate(a.unlockedAt!), style: TextStyle(
                                    color: colors.textMuted, fontSize: 10,
                                  )),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                ),
                const SizedBox(height: 24),
                // ========== 全部成就 ==========
                Text('全部成就', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...categoryOrder.map((cat) {
                  final list = groups[cat] ?? [];
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Text(categoryLabels[cat] ?? cat, style: TextStyle(
                          color: colors.textMuted, fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                      ),
                      ...list.map((a) => _buildAchievementItem(colors, a)),
                    ],
                  );
                }),
                const SizedBox(height: 100),
              ],
            ),
          ),
    );
  }

  Widget _buildAchievementItem(FitTrackColors colors, Achievement a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _showDetail(a),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.unlocked ? colors.accentGlow.withOpacity(0.3) : colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: a.unlocked ? colors.accentGlow.withOpacity(0.15) : colors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.unlocked ? _achievementIcon(a.icon) : Icons.lock_outline,
                  size: 22,
                  color: a.unlocked ? colors.accentGlow : colors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: TextStyle(
                      color: a.unlocked ? colors.textPrimary : colors.textMuted,
                      fontSize: 14, fontWeight: FontWeight.w500,
                    )),
                    Text(a.description, style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              if (a.unlocked)
                Icon(Icons.check_circle, color: colors.successColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(Achievement a) {
    InfoDialog.show(
      context,
      title: a.title,
      content: a.unlocked
          ? '${a.description}\n\n已达成'
          : '解锁条件: ${a.description}',
      icon: a.unlocked ? Icons.emoji_events : Icons.lock_outline,
      iconColor: a.unlocked ? null : Colors.grey,
    );
  }

  IconData _achievementIcon(String iconKey) {
    switch (iconKey) {
      case 'streak':
        return Icons.local_fire_department;
      case 'weight':
        return Icons.fitness_center;
      case 'duration':
        return Icons.timer;
      case 'month':
        return Icons.calendar_month;
      case 'explore':
        return Icons.explore;
      case 'plan':
        return Icons.assignment_turned_in;
      case 'share':
        return Icons.share;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} 解锁';
  }
}
