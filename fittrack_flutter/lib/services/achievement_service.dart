import 'package:flutter/foundation.dart';
import '../data/storage.dart';
import '../data/database_helper.dart';

class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final int? unlockedAt;

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  static const List<Achievement> _all = [
    // Streak
    Achievement(id: 'streak_7', category: 'streak', title: '青铜挑战者',
        description: '连续训练 7 天', icon: 'streak'),
    Achievement(id: 'streak_30', category: 'streak', title: '白银挑战者',
        description: '连续训练 30 天', icon: 'streak'),
    Achievement(id: 'streak_100', category: 'streak', title: '黄金挑战者',
        description: '连续训练 100 天', icon: 'streak'),
    Achievement(id: 'streak_365', category: 'streak', title: '钻石挑战者',
        description: '连续训练 365 天', icon: 'streak'),
    // Weight milestones
    Achievement(id: 'weight_1t', category: 'weight', title: '千斤顶',
        description: '累计训练总重量 1 吨', icon: 'weight'),
    Achievement(id: 'weight_10t', category: 'weight', title: '力拔山兮',
        description: '累计训练总重量 10 吨', icon: 'weight'),
    Achievement(id: 'weight_50t', category: 'weight', title: '撼地者',
        description: '累计训练总重量 50 吨', icon: 'weight'),
    Achievement(id: 'weight_100t', category: 'weight', title: '举重大师',
        description: '累计训练总重量 100 吨', icon: 'weight'),
    // Duration
    Achievement(id: 'duration_24h', category: 'duration', title: '勤劳蜜蜂',
        description: '累计训练时长 24 小时', icon: 'duration'),
    Achievement(id: 'duration_100h', category: 'duration', title: '马拉松健将',
        description: '累计训练时长 100 小时', icon: 'duration'),
    Achievement(id: 'duration_500h', category: 'duration', title: '铁人',
        description: '累计训练时长 500 小时', icon: 'duration'),
    // Month streak
    Achievement(id: 'month_3', category: 'month', title: '季度坚持',
        description: '连续 3 个月有训练', icon: 'month'),
    Achievement(id: 'month_6', category: 'month', title: '半年坚持',
        description: '连续 6 个月有训练', icon: 'month'),
    Achievement(id: 'month_12', category: 'month', title: '全年坚持',
        description: '连续 12 个月有训练', icon: 'month'),
    // Explore
    Achievement(id: 'explore_15', category: 'explore', title: '动作探索者',
        description: '尝试 15 个不同动作', icon: 'explore'),
    Achievement(id: 'explore_20', category: 'explore', title: '动作收藏家',
        description: '尝试 20 个不同动作', icon: 'explore'),
    Achievement(id: 'explore_25', category: 'explore', title: '动作大师',
        description: '尝试 25 个不同动作', icon: 'explore'),
    // Plan
    Achievement(id: 'plan_first_done', category: 'plan', title: '计划完成者',
        description: '完成第一个训练计划', icon: 'plan'),
    // Share
    Achievement(id: 'share_first', category: 'share', title: '初次分享',
        description: '首次分享训练成果', icon: 'share'),
    Achievement(id: 'share_3', category: 'share', title: '分享达人',
        description: '分享训练成果 3 次', icon: 'share'),
    Achievement(id: 'share_10', category: 'share', title: '分享大使',
        description: '分享训练成果 10 次', icon: 'share'),
  ];

  final Set<String> _unlocked = {};
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    final rows = await DatabaseHelper.instance.getAllAchievements();
    for (final r in rows) {
      final id = r['id'] as String?;
      final unlockedAt = r['unlockedAt'] as int? ?? 0;
      if (id != null && unlockedAt > 0) _unlocked.add(id);
    }
    _inited = true;
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _unlocked.clear();
    _inited = false;
    final db = await DatabaseHelper.instance.database;
    await db.delete('achievements');
  }

  Future<List<String>> checkAndUnlock(Map<String, dynamic> record) async {
    final newlyUnlocked = <String>[];
    final records = Storage.getRecords();
    final stats = Storage.getStats();
    final totalWeight = stats['totalWeight'] as int? ?? 0;
    final totalDuration = stats['totalDuration'] as int? ?? 0;

    // Streak
    final streak = _computeStreak(records);
    if (streak >= 7) newlyUnlocked.add('streak_7');
    if (streak >= 30) newlyUnlocked.add('streak_30');
    if (streak >= 100) newlyUnlocked.add('streak_100');
    if (streak >= 365) newlyUnlocked.add('streak_365');

    // Weight
    if (totalWeight >= 1000) newlyUnlocked.add('weight_1t');
    if (totalWeight >= 10000) newlyUnlocked.add('weight_10t');
    if (totalWeight >= 50000) newlyUnlocked.add('weight_50t');
    if (totalWeight >= 100000) newlyUnlocked.add('weight_100t');

    // Duration (seconds → hours)
    if (totalDuration >= 86400) newlyUnlocked.add('duration_24h');
    if (totalDuration >= 360000) newlyUnlocked.add('duration_100h');
    if (totalDuration >= 1800000) newlyUnlocked.add('duration_500h');

    // Plan first done
    final planId = record['planId'] as String?;
    if (planId != null) {
      Map<String, dynamic>? plan;
      try {
        plan = Storage.getPlans().firstWhere((p) => p['id'] == planId);
      } catch (_) {
        plan = null;
      }
      if (plan != null && (plan['progress'] as int? ?? 0) >= 100) {
        newlyUnlocked.add('plan_first_done');
      }
    }

    // Explore (unique exercise names across all records)
    final exercises = <String>{};
    for (final r in records) {
      final setRecords = r['setRecords'];
      if (setRecords is Map) {
        for (final v in setRecords.values) {
          if (v is Map && v['exerciseName'] != null) {
            exercises.add(v['exerciseName'].toString());
          }
        }
      }
    }
    if (exercises.length >= 15) newlyUnlocked.add('explore_15');
    if (exercises.length >= 20) newlyUnlocked.add('explore_20');
    if (exercises.length >= 25) newlyUnlocked.add('explore_25');

    // Persist new unlocks (filter out already-unlocked)
    final now = DateTime.now().millisecondsSinceEpoch;
    final toAdd = newlyUnlocked.where((id) => !_unlocked.contains(id)).toList();
    for (final id in toAdd) {
      final ach = _all.firstWhere((a) => a.id == id);
      await DatabaseHelper.instance.upsertAchievement({
        'id': id,
        'category': ach.category,
        'unlockedAt': now,
        'metadata': '{}',
      });
      _unlocked.add(id);
    }
    Storage.unlockedAchievementsNotifier.value = _unlocked.toList();
    return toAdd;
  }

  int _computeStreak(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final dates = records
        .map((r) => DateTime.fromMillisecondsSinceEpoch(r['date'] as int? ?? 0))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<Achievement> getAll() {
    return _all
        .map((a) => Achievement(
              id: a.id,
              category: a.category,
              title: a.title,
              description: a.description,
              icon: a.icon,
              unlocked: _unlocked.contains(a.id),
            ))
        .toList();
  }
}
