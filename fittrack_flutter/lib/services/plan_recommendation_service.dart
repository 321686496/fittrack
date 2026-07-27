// lib/services/plan_recommendation_service.dart
import '../data/storage.dart';
import '../data/system_plan_library.dart';

/// 评分结果（避免使用 Dart 3 record 语法）
class ScoreResult {
  final double points;
  final String? reason;
  const ScoreResult(this.points, [this.reason]);
}

/// 推荐结果项
class PlanRecommendation {
  final SystemPlan plan;
  final double score; // 0-100
  final List<String> reasons; // 推荐理由（中文，最多 3 条）

  const PlanRecommendation({
    required this.plan,
    required this.score,
    required this.reasons,
  });
}

class PlanRecommendationService {
  static final PlanRecommendationService instance =
      PlanRecommendationService._();
  PlanRecommendationService._();

  /// 主推荐入口 — 返回 top N 推荐计划
  List<PlanRecommendation> recommend({int limit = 5}) {
    if (!SystemPlanLibrary.instance.isLoaded) return [];
    final allPlans = SystemPlanLibrary.instance.all;
    if (allPlans.isEmpty) return [];

    final settings = Storage.getSettings();
    final bodyData = Storage.getBodyData();
    final records = Storage.getRecords();
    final userPlans = Storage.getPlans();

    final userGoal = settings['fitnessGoal'] as String? ?? '';
    final userLevel = _inferFitnessLevel(records, settings);

    // 1. 筛选：优先匹配 goal；无 goal 时全候选
    List<SystemPlan> candidates;
    if (userGoal.isNotEmpty &&
        kPlanGoals.contains(_mapGoalFromSettings(userGoal))) {
      final mappedGoal = _mapGoalFromSettings(userGoal);
      candidates = SystemPlanLibrary.instance.getByGoal(mappedGoal);
      // 候选不足时补充其他目标
      if (candidates.length < 5) {
        final others = allPlans.where((p) => p.goal != mappedGoal).toList();
        candidates = [...candidates, ...others];
      }
    } else {
      candidates = allPlans;
    }

    // 2. 评分
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - 30 * 24 * 60 * 60 * 1000;
    final recentRecords = records.where((r) {
      final ts = (r['date'] as num?)?.toInt() ??
          (r['createTime'] as num?)?.toInt() ??
          0;
      return ts >= thirtyDaysAgo;
    }).toList();

    final scored = candidates.map((plan) {
      return _scorePlan(
        plan: plan,
        userLevel: userLevel,
        userGoal: userGoal,
        bodyData: bodyData,
        recentRecords: recentRecords,
        userPlans: userPlans,
      );
    }).toList();

    // 3. 排序+截断
    final sorted = sortWithFreePriority(scored);
    return sorted.take(limit).toList();
  }

  /// 排序：同段内免费优先
  /// 同段判定：score 差 ≤ 5 视为同段
  static List<PlanRecommendation> sortWithFreePriority(
    List<PlanRecommendation> scored,
  ) {
    final list = List<PlanRecommendation>.from(scored);
    list.sort((a, b) {
      final scoreDiff = b.score.compareTo(a.score);
      // 不同段：按 score 降序
      if ((b.score - a.score).abs() > 5) return scoreDiff;
      // 同段：免费（isPremium=false）排前
      final aPremium = a.plan.isPremium ? 1 : 0;
      final bPremium = b.plan.isPremium ? 1 : 0;
      if (aPremium != bPremium) return aPremium.compareTo(bPremium);
      // 同段同付费状态：按 score 降序
      return scoreDiff;
    });
    return list;
  }

  // ── 评分核心 ──────────────────────────────────────────────────

  PlanRecommendation _scorePlan({
    required SystemPlan plan,
    required String userLevel,
    required String userGoal,
    required Map<String, dynamic> bodyData,
    required List<Map<String, dynamic>> recentRecords,
    required List<Map<String, dynamic>> userPlans,
  }) {
    final reasons = <String>[];
    double score = 0;

    // 难度匹配度（30 分）
    final difficultyScore = _scoreDifficulty(plan.difficulty, userLevel);
    score += difficultyScore.points;
    if (difficultyScore.reason != null) reasons.add(difficultyScore.reason!);

    // 频率匹配度（25 分）
    final frequencyScore = _scoreFrequency(
      plan.recommendedFrequency,
      recentRecords,
    );
    score += frequencyScore.points;
    if (frequencyScore.reason != null) reasons.add(frequencyScore.reason!);

    // BMI 区间匹配（15 分）
    final bmiScore = _scoreBmi(plan.suitableFor, bodyData);
    score += bmiScore.points;
    if (bmiScore.reason != null) reasons.add(bmiScore.reason!);

    // 肌群偏好匹配（15 分）
    final muscleScore = _scoreMusclePreference(plan, recentRecords);
    score += muscleScore.points;

    // 未训练过的计划加分（15 分）
    final noveltyScore = _scoreNovelty(plan.id, userPlans);
    score += noveltyScore.points;
    if (noveltyScore.reason != null) reasons.add(noveltyScore.reason!);

    return PlanRecommendation(
      plan: plan,
      score: score,
      reasons: reasons.take(3).toList(),
    );
  }

  // ── 子评分函数 ────────────────────────────────────────────────

  ScoreResult _scoreDifficulty(String planDifficulty, String userLevel) {
    // level: 'newbie'/'beginner'/'intermediate'/'advanced'
    // difficulty: 'beginner'/'elementary'/'intermediate'/'advanced'
    final levelMap = {
      'newbie': 0,
      'beginner': 1,
      'intermediate': 2,
      'advanced': 3,
    };
    final diffMap = {
      'beginner': 0,
      'elementary': 1,
      'intermediate': 2,
      'advanced': 3,
    };
    final userLv = levelMap[userLevel] ?? 0;
    final planLv = diffMap[planDifficulty] ?? 0;
    final diff = (userLv - planLv).abs();
    double points;
    if (diff == 0) {
      points = 30.0;
    } else if (diff == 1) {
      points = 22.0;
    } else if (diff == 2) {
      points = 12.0;
    } else {
      points = 5.0;
    }
    return ScoreResult(points, '难度匹配当前训练水平');
  }

  ScoreResult _scoreFrequency(
    int planFreq,
    List<Map<String, dynamic>> recentRecords,
  ) {
    if (recentRecords.isEmpty) {
      // 新用户：推荐低频计划
      final points = planFreq <= 3 ? 20.0 : 10.0;
      return ScoreResult(points, '适合新手的训练频率');
    }
    // 去重训练日
    final days = <String>{};
    for (final r in recentRecords) {
      final ts = (r['date'] as num?)?.toInt() ?? 0;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      days.add('${d.year}-${d.month}-${d.day}');
    }
    final avgFreqPerWeek = (days.length / 30 * 7).round();
    final diff = (avgFreqPerWeek - planFreq).abs();
    double points;
    if (diff == 0) {
      points = 25.0;
    } else if (diff == 1) {
      points = 20.0;
    } else if (diff == 2) {
      points = 12.0;
    } else {
      points = 5.0;
    }
    return ScoreResult(points, '频率契合你近期的训练节奏');
  }

  ScoreResult _scoreBmi(
    String suitableFor,
    Map<String, dynamic> bodyData,
  ) {
    final height = (bodyData['height'] as num?)?.toDouble() ?? 0;
    final weight = (bodyData['weight'] as num?)?.toDouble() ?? 0;
    if (height <= 0 || weight <= 0) return const ScoreResult(8.0);

    final bmi = weight / (height * height / 10000);
    String bmiCategory;
    if (bmi < 18.5) {
      bmiCategory = '偏瘦';
    } else if (bmi < 24) {
      bmiCategory = '正常';
    } else if (bmi < 28) {
      bmiCategory = '超重';
    } else {
      bmiCategory = '肥胖';
    }

    // 简单关键词匹配
    if (suitableFor.contains(bmiCategory) ||
        suitableFor.contains(bmi.toStringAsFixed(0))) {
      return const ScoreResult(15.0, '符合你的身体指标');
    }
    return const ScoreResult(7.0);
  }

  ScoreResult _scoreMusclePreference(
    SystemPlan plan,
    List<Map<String, dynamic>> recentRecords,
  ) {
    if (recentRecords.isEmpty) return const ScoreResult(8.0);

    // 统计用户近期训练肌群分布
    // 注意：record['setRecords'] 的结构是 Map<String(exId), List<{set,weight,reps}>>
    // 没有 muscle 字段；肌肉信息应从 record['muscles'] 取出。
    final muscleCount = <String, int>{};
    for (final r in recentRecords) {
      final muscles = r['muscles'];
      if (muscles is List) {
        for (final m in muscles) {
          final muscle = m.toString();
          if (muscle.isNotEmpty) {
            muscleCount[muscle] = (muscleCount[muscle] ?? 0) + 1;
          }
        }
      }
    }
    if (muscleCount.isEmpty) return const ScoreResult(8.0);

    // 统计计划覆盖的肌群
    final planMuscles = <String>{};
    for (final d in plan.days) {
      planMuscles.add(d.muscle);
    }

    // 计算重合度
    int matchCount = 0;
    for (final m in planMuscles) {
      if (muscleCount.containsKey(m)) matchCount++;
    }
    final overlap = matchCount / planMuscles.length;
    final points = overlap * 15.0;
    return ScoreResult(points);
  }

  ScoreResult _scoreNovelty(
    String planId,
    List<Map<String, dynamic>> userPlans,
  ) {
    // 检查用户历史计划中是否使用过此系统计划
    final used = userPlans.any((p) => p['sourcePlanId'] == planId);
    if (used) {
      return const ScoreResult(3.0); // 已用过加分低
    }
    return const ScoreResult(15.0, '全新计划，为你推荐');
  }

  // ── 辅助 ──────────────────────────────────────────────────────

  /// 从 settings.fitnessGoal 映射到 plan.goal
  /// settings 中的值: '增肌'/'减脂'/'塑形'/'保持健康' 等
  String _mapGoalFromSettings(String settingsGoal) {
    if (settingsGoal.contains('增肌') || settingsGoal.contains('bulk')) {
      return 'bulk';
    }
    if (settingsGoal.contains('减脂') || settingsGoal.contains('cut')) {
      return 'cut';
    }
    if (settingsGoal.contains('塑形') || settingsGoal.contains('shape')) {
      return 'shape';
    }
    if (settingsGoal.contains('保持') || settingsGoal.contains('keep')) {
      return 'keep';
    }
    if (settingsGoal.contains('力量') || settingsGoal.contains('strength')) {
      return 'strength';
    }
    return 'bulk'; // 默认
  }

  /// 从训练记录推断用户水平
  /// 返回: 'newbie'/'beginner'/'intermediate'/'advanced'
  String _inferFitnessLevel(
    List<Map<String, dynamic>> records,
    Map<String, dynamic> settings,
  ) {
    // 优先使用 settings 中的 fitnessLevel
    final settingLevel = settings['fitnessLevel'] as String? ?? '';
    if (settingLevel.contains('高级') || settingLevel.contains('advanced')) {
      return 'advanced';
    }
    if (settingLevel.contains('中级') || settingLevel.contains('intermediate')) {
      return 'intermediate';
    }
    if (settingLevel.contains('初级') || settingLevel.contains('beginner')) {
      return 'beginner';
    }
    if (settingLevel.contains('新手') || settingLevel.contains('newbie')) {
      return 'newbie';
    }

    // 无设置时，从训练记录推断
    if (records.isEmpty) return 'newbie';
    if (records.length < 10) return 'beginner';
    if (records.length < 50) return 'intermediate';
    return 'advanced';
  }
}
