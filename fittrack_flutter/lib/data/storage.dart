import 'dart:convert';
import 'dart:math';

/// In-memory storage implementation ported from React Storage.
/// Uses static maps instead of localStorage/shared_preferences.
class Storage {
  // In-memory storage maps
  static final Map<String, dynamic> _store = {};

  // Storage keys
  static const String _keyPlans = 'fitplan_plans';
  static const String _keyRecords = 'fitplan_records';
  static const String _keySettings = 'fitplan_settings';
  static const String _keyStats = 'fitplan_stats';

  // ============================================================
  // Helpers
  // ============================================================

  static String generateId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(36 * 36 * 36 * 36 * 36 * 36);
    final randomStr = random.toRadixString(36).padLeft(6, '0');
    return '${prefix}_${timestamp}_$randomStr';
  }

  static String getTodayStr() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String getWeekKey(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dayNum = d.weekday; // 1=Mon..7=Sun
    final thursday = d.subtract(Duration(days: dayNum - 4));
    final yearStart = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(yearStart).inDays + 1;
    final weekNo = ((dayOfYear - 1) / 7 + 1).ceil();
    return '${thursday.year}-W${weekNo.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // Internal safe get/set
  // ============================================================

  static dynamic _safeGet(String key, dynamic defaultValue) {
    try {
      final raw = _store[key];
      if (raw == null) return defaultValue;
      return raw;
    } catch (_) {
      return defaultValue;
    }
  }

  static bool _safeSet(String key, dynamic data) {
    try {
      _store[key] = data;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // Plans
  // ============================================================

  static List<Map<String, dynamic>> getPlans() {
    final result = _safeGet(_keyPlans, <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static bool savePlans(List<Map<String, dynamic>> plans) {
    return _safeSet(_keyPlans, plans);
  }

  static Map<String, dynamic> addPlan(Map<String, dynamic> plan) {
    final plans = getPlans();
    final newPlan = <String, dynamic>{
      ...plan,
      'id': generateId('plan'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
      'status': plan['status'] ?? 'active',
      'progress': plan['progress'] ?? 0,
    };
    plans.add(newPlan);
    savePlans(plans);
    return newPlan;
  }

  static Map<String, dynamic>? updatePlan(String planId, Map<String, dynamic> updates) {
    final plans = getPlans();
    final idx = plans.indexWhere((p) => p['id'] == planId);
    if (idx == -1) return null;
    plans[idx] = {...plans[idx], ...updates, 'updateTime': DateTime.now().millisecondsSinceEpoch};
    savePlans(plans);
    return plans[idx];
  }

  static bool deletePlan(String planId) {
    final plans = getPlans().where((p) => p['id'] != planId).toList();
    savePlans(plans);
    return true;
  }

  static Map<String, dynamic>? getPlanById(String planId) {
    final plans = getPlans();
    try {
      return plans.firstWhere((p) => p['id'] == planId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Records
  // ============================================================

  static List<Map<String, dynamic>> getRecords() {
    final result = _safeGet(_keyRecords, <Map<String, dynamic>>[]);
    return List<Map<String, dynamic>>.from(
      (result as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  static bool saveRecords(List<Map<String, dynamic>> records) {
    return _safeSet(_keyRecords, records);
  }

  static Map<String, dynamic> addRecord(Map<String, dynamic> record) {
    final records = getRecords();
    final newRecord = <String, dynamic>{
      ...record,
      'id': generateId('record'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
    };
    records.insert(0, newRecord);
    if (records.length > 500) {
      records.removeRange(500, records.length);
    }
    saveRecords(records);
    updateStats(newRecord);
    return newRecord;
  }

  static bool deleteRecord(String recordId) {
    final records = getRecords().where((r) => r['id'] != recordId).toList();
    saveRecords(records);
    return true;
  }

  static Map<String, dynamic>? getRecordById(String recordId) {
    final records = getRecords();
    try {
      return records.firstWhere((r) => r['id'] == recordId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Settings
  // ============================================================

  static Map<String, dynamic> getSettings() {
    final result = _safeGet(_keySettings, <String, dynamic>{});
    if (result is Map && result.isNotEmpty) {
      return Map<String, dynamic>.from(result);
    }
    return {
      'unit': 'kg',
      'restTime': 90,
      'defaultRestTime': 90,
      'theme': 'iron-forge',
    };
  }

  static bool saveSettings(Map<String, dynamic> settings) {
    return _safeSet(_keySettings, settings);
  }

  // ============================================================
  // Stats
  // ============================================================

  static Map<String, dynamic> getStats() {
    final result = _safeGet(_keyStats, <String, dynamic>{});
    if (result is Map && result.isNotEmpty) {
      return Map<String, dynamic>.from(result);
    }
    return {
      'totalTrainings': 0,
      'totalDuration': 0,
      'totalWeight': 0,
      'totalSets': 0,
      'weeklyData': <Map<String, dynamic>>[],
      'muscleData': <String, int>{},
    };
  }

  static Map<String, dynamic> updateStats(Map<String, dynamic> newRecord) {
    final stats = getStats();
    stats['totalTrainings'] = (stats['totalTrainings'] ?? 0) + 1;
    stats['totalDuration'] = (stats['totalDuration'] ?? 0) + (newRecord['duration'] ?? 0);
    stats['totalWeight'] = (stats['totalWeight'] ?? 0) + (newRecord['totalWeight'] ?? 0);
    stats['totalSets'] = (stats['totalSets'] ?? 0) + (newRecord['totalSets'] ?? 0);

    final weekKey = getWeekKey(newRecord['date'] ?? DateTime.now().millisecondsSinceEpoch);
    List weeklyData = List<Map<String, dynamic>>.from(
      (stats['weeklyData'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    Map<String, dynamic>? weekData;
    try {
      weekData = weeklyData.firstWhere((w) => w['week'] == weekKey);
    } catch (_) {
      weekData = null;
    }
    if (weekData == null) {
      weekData = {'week': weekKey, 'trainings': 0, 'duration': 0, 'weight': 0};
      weeklyData.add(weekData);
    }
    weekData['trainings'] = (weekData['trainings'] ?? 0) + 1;
    weekData['duration'] = (weekData['duration'] ?? 0) + (newRecord['duration'] ?? 0);
    weekData['weight'] = (weekData['weight'] ?? 0) + (newRecord['totalWeight'] ?? 0);
    if (weeklyData.length > 12) {
      weeklyData.removeRange(0, weeklyData.length - 12);
    }
    stats['weeklyData'] = weeklyData;

    final muscles = newRecord['muscles'];
    if (muscles is List && muscles.isNotEmpty) {
      Map<String, int> muscleData = Map<String, int>.from(
        (stats['muscleData'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      );
      for (final m in muscles) {
        muscleData[m.toString()] = (muscleData[m.toString()] ?? 0) + 1;
      }
      stats['muscleData'] = muscleData;
    }

    _safeSet(_keyStats, stats);
    return stats;
  }

  static Map<String, dynamic> recalcStats() {
    final records = getRecords();
    final stats = <String, dynamic>{
      'totalTrainings': 0,
      'totalDuration': 0,
      'totalWeight': 0,
      'totalSets': 0,
      'weeklyData': <Map<String, dynamic>>[],
      'muscleData': <String, int>{},
    };

    final weeklyData = <Map<String, dynamic>>[];
    final muscleData = <String, int>{};

    for (final r in records) {
      stats['totalTrainings'] = (stats['totalTrainings'] as int) + 1;
      stats['totalDuration'] = (stats['totalDuration'] as int) + (r['duration'] ?? 0);
      stats['totalWeight'] = (stats['totalWeight'] as int) + (r['totalWeight'] ?? 0);
      stats['totalSets'] = (stats['totalSets'] as int) + (r['totalSets'] ?? 0);

      final weekKey = getWeekKey(r['date'] ?? DateTime.now().millisecondsSinceEpoch);
      Map<String, dynamic>? weekData;
      try {
        weekData = weeklyData.firstWhere((w) => w['week'] == weekKey);
      } catch (_) {
        weekData = null;
      }
      if (weekData == null) {
        weekData = {'week': weekKey, 'trainings': 0, 'duration': 0, 'weight': 0};
        weeklyData.add(weekData);
      }
      weekData['trainings'] = (weekData['trainings'] ?? 0) + 1;
      weekData['duration'] = (weekData['duration'] ?? 0) + (r['duration'] ?? 0);
      weekData['weight'] = (weekData['weight'] ?? 0) + (r['totalWeight'] ?? 0);

      final muscles = r['muscles'];
      if (muscles is List && muscles.isNotEmpty) {
        for (final m in muscles) {
          muscleData[m.toString()] = (muscleData[m.toString()] ?? 0) + 1;
        }
      }
    }

    stats['weeklyData'] = weeklyData;
    stats['muscleData'] = muscleData;
    _safeSet(_keyStats, stats);
    return stats;
  }

  // ============================================================
  // Export / Import / Clear
  // ============================================================

  static Map<String, dynamic> exportAllData() {
    return {
      'plans': getPlans(),
      'records': getRecords(),
      'settings': getSettings(),
      'stats': getStats(),
      'exportTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static String exportAllDataJson() {
    return jsonEncode(exportAllData());
  }

  static bool importData(Map<String, dynamic> data) {
    if (data['plans'] == null || data['records'] == null) return false;
    savePlans(
      List<Map<String, dynamic>>.from(
        (data['plans'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    );
    saveRecords(
      List<Map<String, dynamic>>.from(
        (data['records'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    );
    if (data['settings'] != null) {
      saveSettings(Map<String, dynamic>.from(data['settings'] as Map));
    }
    if (data['stats'] != null) {
      _safeSet(_keyStats, Map<String, dynamic>.from(data['stats'] as Map));
    }
    return true;
  }

  static bool importDataJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return importData(data);
    } catch (_) {
      return false;
    }
  }

  static void clearAll() {
    _store.remove(_keyPlans);
    _store.remove(_keyRecords);
    _store.remove(_keySettings);
    _store.remove(_keyStats);
  }

  static bool hasData() {
    return getPlans().isNotEmpty || getRecords().isNotEmpty;
  }

  // ============================================================
  // Demo Data
  // ============================================================

  static Map<String, dynamic>? initDemoData() {
    if (hasData()) return null;

    final demoPlan = addPlan({
      'name': '三分化增肌计划',
      'type': '三分化',
      'frequency': '6天/周',
      'difficulty': '进阶',
      'totalWeeks': 8,
      'week': 4,
      'badge': '进行中',
      'days': [
        {
          'day': 1,
          'label': '胸部 + 三头肌',
          'muscle': '胸',
          'exercises': [
            {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
            {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
            {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
            {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'restTime': 60},
          ],
        },
        {
          'day': 2,
          'label': '背部 + 二头肌',
          'muscle': '背',
          'exercises': [
            {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
            {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
            {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 75},
            {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 60},
            {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60},
            {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 60},
          ],
        },
        {
          'day': 3,
          'label': '腿部',
          'muscle': '腿',
          'exercises': [
            {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
            {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
          ],
        },
        {
          'day': 4,
          'label': '肩部 + 核心',
          'muscle': '肩',
          'exercises': [
            {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'restTime': 90},
            {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'restTime': 60},
            {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '60秒', 'restTime': 45},
            {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 45},
          ],
        },
        {
          'day': 5,
          'label': '胸部 + 背部',
          'muscle': '胸/背',
          'exercises': <Map<String, dynamic>>[],
        },
        {
          'day': 6,
          'label': '腿部 + 手臂',
          'muscle': '腿/手臂',
          'exercises': <Map<String, dynamic>>[],
        },
      ],
    });

    addPlan({
      'name': '新手入门计划',
      'type': '全身训练',
      'frequency': '3天/周',
      'difficulty': '入门',
      'totalWeeks': 4,
      'week': 4,
      'status': 'done',
      'progress': 100,
      'badge': '已完成',
      'days': [
        {
          'day': 1,
          'label': '全身训练A',
          'muscle': '全身',
          'exercises': [
            {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'restTime': 90},
          ],
        },
        {
          'day': 2,
          'label': '全身训练B',
          'muscle': '全身',
          'exercises': [
            {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
          ],
        },
        {
          'day': 3,
          'label': '全身训练C',
          'muscle': '全身',
          'exercises': [
            {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
            {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
            {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'restTime': 30},
          ],
        },
      ],
    });

    return demoPlan;
  }
}
