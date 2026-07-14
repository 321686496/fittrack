import 'package:flutter/material.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_badge.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});
  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  @override
  Widget build(BuildContext context) {
    final all = AchievementService.instance.getAll();
    final byCategory = <String, List<Achievement>>{};
    for (final a in all) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }
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
      appBar: AppBar(title: const Text('成就墙')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: byCategory.entries.map((e) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(categoryLabels[e.key] ?? e.key,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: e.value
                    .map((a) => AchievementBadge(achievement: a))
                    .toList(),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
