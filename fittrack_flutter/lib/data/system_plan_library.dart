// lib/data/system_plan_library.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 系统训练计划库 — 从 assets/data/system_plans/*.json 加载内置计划
/// 数据驱动架构，方便 Phase 3 远程下发

// ── 常量 ───────────────────────────────────────────────────────────

const List<String> kPlanGoals = ['bulk', 'cut', 'shape', 'keep', 'strength'];

const List<String> kPlanDifficulties = [
  'beginner',
  'elementary',
  'intermediate',
  'advanced',
];

const List<String> kPlanTrainingTypes = [
  '3day_split',
  '4day_split',
  '5day_split',
  'full_body',
  'hiit',
];

const Map<String, String> kGoalLabelsZh = {
  'bulk': '增肌',
  'cut': '减脂',
  'shape': '塑形',
  'keep': '保持健康',
  'strength': '力量',
};

const Map<String, String> kDifficultyLabelsZh = {
  'beginner': '入门',
  'elementary': '初级',
  'intermediate': '进阶',
  'advanced': '高级',
};

const Map<String, String> kTrainingTypeLabelsZh = {
  '3day_split': '三分化',
  '4day_split': '四分化',
  '5day_split': '五分化',
  'full_body': '全身训练',
  'hiit': 'HIIT',
};

/// 按难度的积分价格（精品计划）
const Map<String, int> kDifficultyPointsCost = {
  'beginner': 100,
  'elementary': 200,
  'intermediate': 400,
  'advanced': 800,
};

/// 精品计划解锁有效期（天）
const int kPlanUnlockValidityDays = 90;

// ── 数据类 ─────────────────────────────────────────────────────────

class SystemPlanExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final int restTime;
  final double? weight;

  const SystemPlanExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTime,
    this.weight,
  });

  factory SystemPlanExercise.fromJson(Map<String, dynamic> json) {
    return SystemPlanExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as num).toInt(),
      reps: (json['reps'] as num).toInt(),
      restTime: (json['restTime'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets,
        'reps': reps,
        'restTime': restTime,
        if (weight != null) 'weight': weight,
      };
}

class SystemPlanDay {
  final int day;
  final String label;
  final String muscle;
  final List<SystemPlanExercise> exercises;

  const SystemPlanDay({
    required this.day,
    required this.label,
    required this.muscle,
    required this.exercises,
  });

  factory SystemPlanDay.fromJson(Map<String, dynamic> json) {
    return SystemPlanDay(
      day: (json['day'] as num).toInt(),
      label: json['label'] as String,
      muscle: json['muscle'] as String,
      exercises: (json['exercises'] as List)
          .map((e) => SystemPlanExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'label': label,
        'muscle': muscle,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class SystemPlan {
  final String id;
  final String name;
  final String goal;
  final String difficulty;
  final String trainingType;
  final bool isPremium;
  final int pointsCost;
  final int totalWeeks;
  final int defaultRestTime;
  final String description;
  final String coverEmoji;
  final List<String> coverColors;
  final List<String> tags;
  final int recommendedFrequency;
  final String suitableFor;
  final List<SystemPlanDay> days;

  const SystemPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.difficulty,
    required this.trainingType,
    required this.isPremium,
    required this.pointsCost,
    required this.totalWeeks,
    required this.defaultRestTime,
    required this.description,
    required this.coverEmoji,
    required this.coverColors,
    required this.tags,
    required this.recommendedFrequency,
    required this.suitableFor,
    required this.days,
  });

  factory SystemPlan.fromJson(Map<String, dynamic> json) {
    return SystemPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String,
      difficulty: json['difficulty'] as String,
      trainingType: json['trainingType'] as String,
      isPremium: json['isPremium'] as bool? ?? false,
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      totalWeeks: (json['totalWeeks'] as num).toInt(),
      defaultRestTime: (json['defaultRestTime'] as num).toInt(),
      description: json['description'] as String,
      coverEmoji: json['coverEmoji'] as String? ?? '💪',
      coverColors: (json['coverColors'] as List? ?? ['#FF6B6B', '#C44D4D'])
          .map((e) => e.toString())
          .toList(),
      tags: (json['tags'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      recommendedFrequency: (json['recommendedFrequency'] as num).toInt(),
      suitableFor: json['suitableFor'] as String? ?? '',
      days: (json['days'] as List)
          .map((e) => SystemPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 转换为 Storage 中存储的 plan 格式（用于"采用此计划"时写入）
  Map<String, dynamic> toStoragePlan() {
    return {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}_${id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
      'name': name,
      'type': trainingType,
      'frequency': recommendedFrequency,
      'difficulty': difficulty,
      'totalWeeks': totalWeeks,
      'defaultRestTime': defaultRestTime,
      'days': days
          .map((d) => {
                'day': d.day,
                'label': d.label,
                'muscle': d.muscle,
                'exercises': d.exercises.map((e) => e.toJson()).toList(),
              })
          .toList(),
      'week': 1,
      'progress': 0,
      'status': 'active',
      'sourcePlanId': id,
      'isFromSystemLibrary': true,
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

// ── 加载器单例 ────────────────────────────────────────────────────

class SystemPlanLibrary {
  SystemPlanLibrary._();
  static final SystemPlanLibrary instance = SystemPlanLibrary._();

  List<SystemPlan> _plans = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<SystemPlan> get all => List.unmodifiable(_plans);

  /// 启动时加载全部 JSON
  Future<void> load() async {
    if (_loaded) return;
    final List<SystemPlan> all = [];
    for (final goal in kPlanGoals) {
      try {
        final raw = await rootBundle.loadString(
          'assets/data/system_plans/$goal.json',
        );
        final List<dynamic> list = jsonDecode(raw) as List;
        all.addAll(
          list.map((e) => SystemPlan.fromJson(e as Map<String, dynamic>)),
        );
      } catch (e) {
        debugPrint('SystemPlanLibrary: 加载 $goal.json 失败: $e');
      }
    }
    _plans = all;
    _loaded = true;
    debugPrint('SystemPlanLibrary: 已加载 ${_plans.length} 个系统计划');
  }

  List<SystemPlan> getByGoal(String goal) =>
      _plans.where((p) => p.goal == goal).toList();

  List<SystemPlan> getByDifficulty(String difficulty) =>
      _plans.where((p) => p.difficulty == difficulty).toList();

  List<SystemPlan> getByGoalAndDifficulty(String goal, String difficulty) =>
      _plans
          .where((p) => p.goal == goal && p.difficulty == difficulty)
          .toList();

  SystemPlan? getById(String id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
