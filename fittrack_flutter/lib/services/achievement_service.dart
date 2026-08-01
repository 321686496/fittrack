import 'package:flutter/foundation.dart';
import '../data/storage.dart';
import '../data/database_helper.dart';
import 'points_service.dart';
import 'sound_service.dart';

class Achievement {
  final String id;
  final String category;
  final String title;
  final String description;
  final String icon;
  final bool unlocked;
  final int? unlockedAt;
  final int pointsReward;      // 解锁可获积分，0 表示纯荣誉
  final bool canEarnPoints;    // 是否可获积分

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    this.unlocked = false,
    this.unlockedAt,
    this.pointsReward = 0,
    this.canEarnPoints = true,
  });
}

class AchievementService {
  static final AchievementService instance = AchievementService._();
  AchievementService._();

  static const List<Achievement> _all = [
    // Streak
    Achievement(id: 'streak_7', category: 'streak', title: '青铜挑战者',
        description: '连续训练 7 天', icon: 'streak',
        pointsReward: 20, canEarnPoints: true),
    Achievement(id: 'streak_30', category: 'streak', title: '白银挑战者',
        description: '连续训练 30 天', icon: 'streak',
        pointsReward: 50, canEarnPoints: true),
    Achievement(id: 'streak_100', category: 'streak', title: '黄金挑战者',
        description: '连续训练 100 天', icon: 'streak',
        pointsReward: 100, canEarnPoints: true),
    Achievement(id: 'streak_365', category: 'streak', title: '钻石挑战者',
        description: '连续训练 365 天', icon: 'streak',
        pointsReward: 200, canEarnPoints: true),
    // Weight milestones（纯荣誉，可刷）
    Achievement(id: 'weight_1t', category: 'weight', title: '千斤顶',
        description: '累计训练总重量 1 吨', icon: 'weight',
        pointsReward: 0, canEarnPoints: false),
    Achievement(id: 'weight_10t', category: 'weight', title: '力拔山兮',
        description: '累计训练总重量 10 吨', icon: 'weight',
        pointsReward: 0, canEarnPoints: false),
    Achievement(id: 'weight_50t', category: 'weight', title: '撼地者',
        description: '累计训练总重量 50 吨', icon: 'weight',
        pointsReward: 0, canEarnPoints: false),
    Achievement(id: 'weight_100t', category: 'weight', title: '举重大师',
        description: '累计训练总重量 100 吨', icon: 'weight',
        pointsReward: 0, canEarnPoints: false),
    // Duration
    Achievement(id: 'duration_24h', category: 'duration', title: '勤劳蜜蜂',
        description: '累计训练时长 24 小时', icon: 'duration',
        pointsReward: 30, canEarnPoints: true),
    Achievement(id: 'duration_100h', category: 'duration', title: '马拉松健将',
        description: '累计训练时长 100 小时', icon: 'duration',
        pointsReward: 80, canEarnPoints: true),
    Achievement(id: 'duration_500h', category: 'duration', title: '铁人',
        description: '累计训练时长 500 小时', icon: 'duration',
        pointsReward: 200, canEarnPoints: true),
    // Month streak
    Achievement(id: 'month_3', category: 'month', title: '季度坚持',
        description: '连续 3 个月有训练', icon: 'month',
        pointsReward: 50, canEarnPoints: true),
    Achievement(id: 'month_6', category: 'month', title: '半年坚持',
        description: '连续 6 个月有训练', icon: 'month',
        pointsReward: 100, canEarnPoints: true),
    Achievement(id: 'month_12', category: 'month', title: '全年坚持',
        description: '连续 12 个月有训练', icon: 'month',
        pointsReward: 200, canEarnPoints: true),
    // Explore
    Achievement(id: 'explore_15', category: 'explore', title: '动作探索者',
        description: '尝试 15 个不同动作', icon: 'explore',
        pointsReward: 30, canEarnPoints: true),
    Achievement(id: 'explore_20', category: 'explore', title: '动作收藏家',
        description: '尝试 20 个不同动作', icon: 'explore',
        pointsReward: 60, canEarnPoints: true),
    Achievement(id: 'explore_25', category: 'explore', title: '动作大师',
        description: '尝试 25 个不同动作', icon: 'explore',
        pointsReward: 100, canEarnPoints: true),
    // Plan
    Achievement(id: 'plan_first_done', category: 'plan', title: '计划完成者',
        description: '完成第一个训练计划', icon: 'plan',
        pointsReward: 50, canEarnPoints: true),
    // Share
    Achievement(id: 'share_first', category: 'share', title: '初次分享',
        description: '首次分享训练成果', icon: 'share',
        pointsReward: 20, canEarnPoints: true),
    Achievement(id: 'share_3', category: 'share', title: '分享达人',
        description: '分享训练成果 3 次', icon: 'share',
        pointsReward: 40, canEarnPoints: true),
    Achievement(id: 'share_10', category: 'share', title: '分享大使',
        description: '分享训练成果 10 次', icon: 'share',
        pointsReward: 80, canEarnPoints: true),
  ];

  final Set<String> _unlocked = {};
  final Map<String, int> _unlockedAtMap = {};
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    final rows = await DatabaseHelper.instance.getAllAchievements();
    for (final r in rows) {
      final id = r['id'] as String?;
      final unlockedAt = r['unlockedAt'] as int? ?? 0;
      if (id != null && unlockedAt > 0) {
        _unlocked.add(id);
        _unlockedAtMap[id] = unlockedAt;
      }
    }
    _inited = true;
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _unlocked.clear();
    _unlockedAtMap.clear();
    _inited = false;
    final db = await DatabaseHelper.instance.database;
    await db.delete('achievements');
  }

  Future<List<String>> checkAndUnlock(Map<String, dynamic> record) async {
    final candidates = <String>[];
    final records = Storage.getRecords();
    final stats = Storage.getStats();
    final totalWeight = stats['totalWeight'] as int? ?? 0;
    final totalDuration = stats['totalDuration'] as int? ?? 0;

    // Streak
    final streak = _computeStreak(records);
    if (streak >= 7) candidates.add('streak_7');
    if (streak >= 30) candidates.add('streak_30');
    if (streak >= 100) candidates.add('streak_100');
    if (streak >= 365) candidates.add('streak_365');

    // Weight
    if (totalWeight >= 1000) candidates.add('weight_1t');
    if (totalWeight >= 10000) candidates.add('weight_10t');
    if (totalWeight >= 50000) candidates.add('weight_50t');
    if (totalWeight >= 100000) candidates.add('weight_100t');

    // Duration (存储单位为分钟，需转换为小时比较)
    // 修复：training_page 存入 duration 单位为分钟，此处原按秒比较导致阈值错误
    // 24h = 1440min, 100h = 6000min, 500h = 30000min
    if (totalDuration >= 1440) candidates.add('duration_24h');
    if (totalDuration >= 6000) candidates.add('duration_100h');
    if (totalDuration >= 30000) candidates.add('duration_500h');

    // Month streak（不同 year-month 数量）
    // 注：此处按"出现过训练的月份数"判定，与"连续 N 个月"语义略有差异，
    // 与设计文档 Task 3.2 / 5 节描述一致。
    final months = <String>{};
    for (final r in records) {
      final dateMs = r['date'] as int?;
      if (dateMs == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(dateMs);
      months.add('${d.year}-${d.month}');
    }
    if (months.length >= 3) candidates.add('month_3');
    if (months.length >= 6) candidates.add('month_6');
    if (months.length >= 12) candidates.add('month_12');

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
        candidates.add('plan_first_done');
      }
    }

    // Explore (unique exercise ids across all records)
    // 修复：setRecords 结构为 Map<exId, List<{set,weight,reps}>>，
    // 原代码读取 v['exerciseName'] 但 set 记录中无此字段，导致探索成就永不触发。
    // 正确做法：使用 setRecords 的 key（动作 id）作为唯一标识。
    final exercises = <String>{};
    for (final r in records) {
      final setRecords = r['setRecords'];
      if (setRecords is Map) {
        for (final key in setRecords.keys) {
          if (key != null) {
            exercises.add(key.toString());
          }
        }
      }
    }
    if (exercises.length >= 15) candidates.add('explore_15');
    if (exercises.length >= 20) candidates.add('explore_20');
    if (exercises.length >= 25) candidates.add('explore_25');

    // 统一通过 _unlockById 写入 DB + 发积分 + 音效
    final newlyUnlocked = <String>[];
    for (final id in candidates) {
      newlyUnlocked.addAll(await _unlockById(id));
    }
    Storage.unlockedAchievementsNotifier.value = _unlocked.toList();
    return newlyUnlocked;
  }

  /// 解锁单个成就（若已解锁则跳过）。
  /// 集中处理：写入 DB、发放积分（仅 canEarnPoints && pointsReward > 0）、播放音效。
  /// 返回 [id] 单元素列表（本次新解锁），否则空列表。
  Future<List<String>> _unlockById(String id) async {
    if (_unlocked.contains(id)) return [];
    Achievement? ach;
    for (final a in _all) {
      if (a.id == id) {
        ach = a;
        break;
      }
    }
    if (ach == null) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    await DatabaseHelper.instance.upsertAchievement({
      'id': id,
      'category': ach.category,
      'unlockedAt': now,
      'metadata': '{}',
      'pointsReward': ach.pointsReward,
      'canEarnPoints': ach.canEarnPoints ? 1 : 0,
    });
    _unlocked.add(id);
    _unlockedAtMap[id] = now;
    // 解锁发放积分（仅可获积分且奖励 > 0）
    if (ach.canEarnPoints && ach.pointsReward > 0) {
      await PointsService.instance.addPoints(ach.pointsReward, 'achievement');
    }
    SoundService.instance.play(SoundType.achievement);
    return [id];
  }

  /// 记录一次分享行为并评估 share 类成就解锁。
  /// 在分享成功（生成分享卡片）后调用。
  Future<List<String>> recordShare() async {
    // 确保 _unloaded 已从 DB 加载，避免重复解锁 + 重复发积分
    await init();
    final settings = Storage.getSettings();
    final count = (settings['shareCount'] as int? ?? 0) + 1;
    settings['shareCount'] = count;
    Storage.saveSettings(settings);
    // 评估 share_first(1)/share_3(3)/share_10(10)
    final newlyUnlocked = <String>[];
    if (count >= 1) newlyUnlocked.addAll(await _unlockById('share_first'));
    if (count >= 3) newlyUnlocked.addAll(await _unlockById('share_3'));
    if (count >= 10) newlyUnlocked.addAll(await _unlockById('share_10'));
    Storage.unlockedAchievementsNotifier.value = _unlocked.toList();
    return newlyUnlocked;
  }

  /// 评估所有成就解锁状态（不基于单条记录，用于 profile 页面初始化）
  /// 返回新解锁的成就 ID 列表
  Future<List<String>> evaluateAchievements() async {
    // 构造一个空 record 用于触发判定（checkAndUnlock 内部会读取全部 records/stats）
    final emptyRecord = <String, dynamic>{};
    return await checkAndUnlock(emptyRecord);
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
              unlockedAt: _unlockedAtMap[a.id],
              pointsReward: a.pointsReward,
              canEarnPoints: a.canEarnPoints,
            ))
        .toList();
  }
}
