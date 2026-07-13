import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

/// Storage with hybrid persistence:
/// - Plans & Records: SQLite (via DatabaseHelper) — 结构化大数据
/// - Settings / Stats / BodyData: SharedPreferences — 简单键值对
///
/// Call Storage.init() before using any other methods.
class Storage {
  // SharedPreferences 实例（仅用于轻量键值数据）
  static SharedPreferences? _prefs;
  static final Map<String, dynamic> _store = {};

  // DatabaseHelper 单例
  static final DatabaseHelper _db = DatabaseHelper.instance;

  // SharedPreferences 存储键
  static const String _keySettings = 'fitplan_settings';
  static const String _keyStats = 'fitplan_stats';
  static const String _keyBodyData = 'fitplan_bodyData';
  static const String _keyBodyDataHistory = 'fitplan_bodyDataHistory';
  static const String _keyPrefsPrefix = 'fittrack_';
  static const String _keyMigrated = 'fittrack_sqlite_migrated';

  // Phase 2 — 全局可观测状态
  static final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<List<String>> unlockedAchievementsNotifier =
      ValueNotifier<List<String>>([]);

  // ============================================================
  // Initialization
  // ============================================================

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 加载 SharedPreferences 中的轻量数据
    for (final key in [_keySettings, _keyStats, _keyBodyData, _keyBodyDataHistory]) {
      final raw = _prefs!.getString('$_keyPrefsPrefix$key');
      if (raw != null) {
        try {
          _store[key] = jsonDecode(raw);
        } catch (_) {}
      }
    }

    // 首次启动时，将 SharedPreferences 中的旧 Plans/Records 迁移到 SQLite
    await _migrateFromPrefsIfNeeded();

    // Phase 2 — 生成 deviceId 并初始化 isPremium 状态
    final settings = _safeGet(_keySettings, <String, dynamic>{}) as Map<String, dynamic>;
    if (settings['deviceId'] == null || (settings['deviceId'] as String).isEmpty) {
      settings['deviceId'] = _generateUuidV4();
      _store[_keySettings] = settings;
      _persistKey(_keySettings);
    }
    isPremiumNotifier.value = settings['isPremium'] ?? false;
  }

  // ── 数据迁移：SharedPreferences → SQLite ──────────────────

  static Future<void> _migrateFromPrefsIfNeeded() async {
    final migrated = _prefs?.getBool(_keyMigrated) ?? false;
    if (migrated) return;

    try {
      // 迁移 Plans
      final oldPlansRaw = _prefs?.getString('${_keyPrefsPrefix}fitplan_plans');
      if (oldPlansRaw != null && oldPlansRaw.isNotEmpty) {
        final List<dynamic> oldPlans = jsonDecode(oldPlansRaw);
        for (final p in oldPlans) {
          final plan = Map<String, dynamic>.from(p as Map);
          // 确保有 id
          if (plan['id'] == null || (plan['id'] as String).isEmpty) {
            plan['id'] = generateId('plan');
          }
          await _db.insertPlan(plan);
        }
      }

      // 迁移 Records
      final oldRecordsRaw = _prefs?.getString('${_keyPrefsPrefix}fitplan_records');
      if (oldRecordsRaw != null && oldRecordsRaw.isNotEmpty) {
        final List<dynamic> oldRecords = jsonDecode(oldRecordsRaw);
        for (final r in oldRecords) {
          final record = Map<String, dynamic>.from(r as Map);
          if (record['id'] == null || (record['id'] as String).isEmpty) {
            record['id'] = generateId('record');
          }
          await _db.insertRecord(record);
        }
      }

      // 标记迁移完成，并清理旧数据
      await _prefs?.setBool(_keyMigrated, true);
      await _prefs?.remove('${_keyPrefsPrefix}fitplan_plans');
      await _prefs?.remove('${_keyPrefsPrefix}fitplan_records');
    } catch (e) {
      debugPrint('Storage migration error: $e');
    }
  }

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

  // Phase 2 — UUID v4 生成（用于 deviceId）
  static String _generateUuidV4() {
    final rng = Random();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  // Phase 2 — 更新 Premium 状态
  static Future<void> setPremium(bool value, {String source = ''}) async {
    final s = getSettings();
    s['isPremium'] = value;
    s['premiumSource'] = source;
    await saveSettings(s);
    isPremiumNotifier.value = value;
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
  // SharedPreferences 内部辅助
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
      _persistKey(key);
      return true;
    } catch (_) {
      return false;
    }
  }

  static void _persistKey(String key) {
    try {
      _prefs?.setString('$_keyPrefsPrefix$key', jsonEncode(_store[key]));
    } catch (_) {}
  }

  /// 异步持久化（确保数据写入磁盘）
  static Future<void> _persistKeyAsync(String key) async {
    try {
      await _prefs?.setString('$_keyPrefsPrefix$key', jsonEncode(_store[key]));
    } catch (_) {}
  }

  // ============================================================
  // Plans (SQLite)
  // ============================================================

  static List<Map<String, dynamic>> _plansCache = [];
  static bool _plansCacheDirty = true;

  static Future<List<Map<String, dynamic>>> getPlansAsync() async {
    if (_plansCacheDirty) {
      _plansCache = await _db.getAllPlans();
      _plansCacheDirty = false;
    }
    return List<Map<String, dynamic>>.from(
      _plansCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  /// 同步获取缓存的计划列表（需先调用 getPlansAsync 加载）
  static List<Map<String, dynamic>> getPlans() {
    return List<Map<String, dynamic>>.from(
      _plansCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<bool> savePlansAsync(List<Map<String, dynamic>> plans) async {
    await _db.deleteAllPlans();
    for (final plan in plans) {
      await _db.insertPlan(plan);
    }
    _plansCacheDirty = true;
    return true;
  }

  static Future<Map<String, dynamic>> addPlanAsync(Map<String, dynamic> plan) async {
    final newPlan = <String, dynamic>{
      ...plan,
      'id': plan['id'] ?? generateId('plan'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
      'status': plan['status'] ?? 'active',
      'progress': plan['progress'] ?? 0,
    };
    await _db.insertPlan(newPlan);
    _plansCacheDirty = true;
    return newPlan;
  }

  /// 同步添加（仅更新缓存，异步持久化）
  static Map<String, dynamic> addPlan(Map<String, dynamic> plan) {
    final newPlan = <String, dynamic>{
      ...plan,
      'id': plan['id'] ?? generateId('plan'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
      'status': plan['status'] ?? 'active',
      'progress': plan['progress'] ?? 0,
    };
    _plansCache.add(newPlan);
    _plansCacheDirty = true;
    // 异步持久化
    _db.insertPlan(newPlan);
    return newPlan;
  }

  static Future<Map<String, dynamic>?> updatePlanAsync(String planId, Map<String, dynamic> updates) async {
    final result = await _db.updatePlan(planId, updates);
    _plansCacheDirty = true;
    return result;
  }

  static Map<String, dynamic>? updatePlan(String planId, Map<String, dynamic> updates) {
    final idx = _plansCache.indexWhere((p) => p['id'] == planId);
    if (idx == -1) return null;
    _plansCache[idx] = {..._plansCache[idx], ...updates, 'updateTime': DateTime.now().millisecondsSinceEpoch};
    _plansCacheDirty = true;
    // 异步持久化
    _db.updatePlan(planId, updates);
    // 通知数据变更
    dataChanged.value = !dataChanged.value;
    return _plansCache[idx];
  }

  static Future<bool> deletePlanAsync(String planId) async {
    await _db.deletePlan(planId);
    _plansCacheDirty = true;
    return true;
  }

  static bool deletePlan(String planId) {
    _plansCache.removeWhere((p) => p['id'] == planId);
    _plansCacheDirty = true;
    // 异步持久化
    _db.deletePlan(planId);
    return true;
  }

  static Future<Map<String, dynamic>?> getPlanByIdAsync(String planId) async {
    return _db.getPlanById(planId);
  }

  static Map<String, dynamic>? getPlanById(String planId) {
    try {
      return _plansCache.firstWhere((p) => p['id'] == planId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Records (SQLite)
  // ============================================================

  static List<Map<String, dynamic>> _recordsCache = [];
  static bool _recordsCacheDirty = true;

  /// 数据变更通知器（用于跨页面刷新）
  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  static Future<List<Map<String, dynamic>>> getRecordsAsync() async {
    if (_recordsCacheDirty) {
      _recordsCache = await _db.getAllRecords();
      _recordsCacheDirty = false;
    }
    return List<Map<String, dynamic>>.from(
      _recordsCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static List<Map<String, dynamic>> getRecords() {
    return List<Map<String, dynamic>>.from(
      _recordsCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<bool> saveRecordsAsync(List<Map<String, dynamic>> records) async {
    await _db.deleteAllRecords();
    for (final record in records) {
      await _db.insertRecord(record);
    }
    _recordsCacheDirty = true;
    return true;
  }

  static Map<String, dynamic> addRecord(Map<String, dynamic> record) {
    final newRecord = <String, dynamic>{
      ...record,
      'id': generateId('record'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
    };
    _recordsCache.insert(0, newRecord);
    // 限制缓存数量
    if (_recordsCache.length > 500) {
      _recordsCache.removeRange(500, _recordsCache.length);
    }
    _recordsCacheDirty = true;
    // 通知数据变更
    dataChanged.value = !dataChanged.value;
    // 异步持久化 + 裁剪
    _db.insertRecord(newRecord);
    _db.trimRecords(500);
    // 更新统计
    updateStats(newRecord);
    return newRecord;
  }

  static bool deleteRecord(String recordId) {
    _recordsCache.removeWhere((r) => r['id'] == recordId);
    _recordsCacheDirty = true;
    _db.deleteRecord(recordId);
    return true;
  }

  static Map<String, dynamic>? getRecordById(String recordId) {
    try {
      return _recordsCache.firstWhere((r) => r['id'] == recordId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Settings (SharedPreferences)
  // ============================================================

  static Map<String, dynamic> getSettings() {
    final defaults = <String, dynamic>{
      'unit': 'kg',
      'restTime': 90,
      'defaultRestTime': 90,
      'defaultSets': 3,
      'defaultReps': 10,
      'defaultWeight': 20.0,
      'theme': 'vitality-sport',
      'trainingTime': '',
      // Phase 2 — 新增默认 settings
      'isPremium': false,
      'premiumSource': '',
      'redeemedCodes': <String>[],
      'channelSource': '',
      'anonStatsOptIn': false,
      'deviceId': '',
      'ratingPromptLastShown': 0,
      'ratingPromptNeverAsk': false,
      'smartPushEnabled': true,
      'lastPushDate': '',
      'pushCountIn7Days': 0,
      'onboardingV2Done': false,
    };
    final result = _safeGet(_keySettings, <String, dynamic>{});
    if (result is Map) {
      return {...defaults, ...Map<String, dynamic>.from(result)};
    }
    return defaults;
  }

  static bool saveSettings(Map<String, dynamic> settings) {
    final result = _safeSet(_keySettings, settings);
    // 异步确保数据写入磁盘
    _persistKeyAsync(_keySettings);
    return result;
  }

  // ============================================================
  // Stats (SharedPreferences)
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
    _persistKeyAsync(_keyStats);
    return stats;
  }

  static Future<Map<String, dynamic>> recalcStatsAsync() async {
    final records = await getRecordsAsync();
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
    _persistKeyAsync(_keyStats);
    return stats;
  }

  // ============================================================
  // Body Data (SharedPreferences)
  // ============================================================

  static Map<String, dynamic> getBodyData() {
    final result = _safeGet(_keyBodyData, <String, dynamic>{});
    if (result is Map && result.isNotEmpty) {
      return Map<String, dynamic>.from(result);
    }
    return {};
  }

  static bool saveBodyData(Map<String, dynamic> bodyData) {
    final result = _safeSet(_keyBodyData, bodyData);
    // 异步确保数据写入磁盘
    _persistKeyAsync(_keyBodyData);
    return result;
  }

  /// 获取身体数据历史记录
  static List<Map<String, dynamic>> getBodyDataHistory() {
    final result = _safeGet(_keyBodyDataHistory, <Map<String, dynamic>>[]);
    if (result is List) {
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// 保存身体数据历史（每次更新前调用）
  static bool saveBodyDataHistory(Map<String, dynamic> oldData) {
    if (oldData.isEmpty) return false;
    final history = getBodyDataHistory();
    final entry = Map<String, dynamic>.from(oldData);
    entry['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    history.add(entry);
    // 只保留最近 50 条
    if (history.length > 50) {
      history.removeRange(0, history.length - 50);
    }
    final result = _safeSet(_keyBodyDataHistory, history);
    _persistKeyAsync(_keyBodyDataHistory);
    return result;
  }

  // ============================================================
  // GymCards (SQLite)
  // ============================================================

  static List<Map<String, dynamic>> _gymCardsCache = [];
  static bool _gymCardsCacheDirty = true;

  static Future<List<Map<String, dynamic>>> getGymCardsAsync() async {
    if (_gymCardsCacheDirty) {
      _gymCardsCache = await _db.getAllGymCards();
      _gymCardsCacheDirty = false;
    }
    return List<Map<String, dynamic>>.from(
      _gymCardsCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static List<Map<String, dynamic>> getGymCards() {
    return List<Map<String, dynamic>>.from(
      _gymCardsCache.map((e) => Map<String, dynamic>.from(e)),
    );
  }

  static Future<Map<String, dynamic>> addGymCardAsync(Map<String, dynamic> card) async {
    final newCard = <String, dynamic>{
      ...card,
      'id': card['id'] ?? generateId('gymcard'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.insertGymCard(newCard);
    _gymCardsCacheDirty = true;
    return newCard;
  }

  static Map<String, dynamic> addGymCard(Map<String, dynamic> card) {
    final newCard = <String, dynamic>{
      ...card,
      'id': card['id'] ?? generateId('gymcard'),
      'createTime': DateTime.now().millisecondsSinceEpoch,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
    };
    _gymCardsCache.add(newCard);
    _gymCardsCacheDirty = true;
    _db.insertGymCard(newCard);
    return newCard;
  }

  static Future<Map<String, dynamic>?> updateGymCardAsync(String cardId, Map<String, dynamic> updates) async {
    final result = await _db.updateGymCard(cardId, updates);
    _gymCardsCacheDirty = true;
    return result;
  }

  static Map<String, dynamic>? updateGymCard(String cardId, Map<String, dynamic> updates) {
    final idx = _gymCardsCache.indexWhere((c) => c['id'] == cardId);
    if (idx == -1) return null;
    _gymCardsCache[idx] = {..._gymCardsCache[idx], ...updates, 'updateTime': DateTime.now().millisecondsSinceEpoch};
    _gymCardsCacheDirty = true;
    _db.updateGymCard(cardId, updates);
    return _gymCardsCache[idx];
  }

  static Future<bool> deleteGymCardAsync(String cardId) async {
    await _db.deleteGymCard(cardId);
    _gymCardsCacheDirty = true;
    return true;
  }

  static bool deleteGymCard(String cardId) {
    _gymCardsCache.removeWhere((c) => c['id'] == cardId);
    _gymCardsCacheDirty = true;
    _db.deleteGymCard(cardId);
    return true;
  }

  static Map<String, dynamic>? getGymCardById(String cardId) {
    try {
      return _gymCardsCache.firstWhere((c) => c['id'] == cardId);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Export / Import / Clear
  // ============================================================

  static Future<Map<String, dynamic>> exportAllDataAsync() async {
    return {
      'plans': await getPlansAsync(),
      'records': await getRecordsAsync(),
      'settings': getSettings(),
      'stats': getStats(),
      'exportTime': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<String> exportAllDataJsonAsync() async {
    final data = await exportAllDataAsync();
    return jsonEncode(data);
  }

  // 同步版本（兼容旧调用）
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

  static Future<bool> importDataAsync(Map<String, dynamic> data) async {
    if (data['plans'] == null || data['records'] == null) return false;
    await savePlansAsync(
      List<Map<String, dynamic>>.from(
        (data['plans'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
    );
    await saveRecordsAsync(
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

  static Future<bool> importDataJsonAsync(String jsonStr) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return importDataAsync(data);
    } catch (_) {
      return false;
    }
  }

  // 同步版本（兼容旧调用）
  static bool importData(Map<String, dynamic> data) {
    if (data['plans'] == null || data['records'] == null) return false;
    // 同步版本仅更新缓存，异步持久化
    _plansCache = List<Map<String, dynamic>>.from(
      (data['plans'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    _recordsCache = List<Map<String, dynamic>>.from(
      (data['records'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    _plansCacheDirty = true;
    _recordsCacheDirty = true;
    savePlansAsync(_plansCache);
    saveRecordsAsync(_recordsCache);
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

  static Future<void> clearAll() async {
    await _db.deleteAllPlans();
    await _db.deleteAllRecords();
    await _db.deleteAllGymCards();
    _plansCache = [];
    _recordsCache = [];
    _gymCardsCache = [];
    _plansCacheDirty = true;
    _recordsCacheDirty = true;
    _gymCardsCacheDirty = true;
    _store.remove(_keySettings);
    _store.remove(_keyStats);
    _store.remove(_keyBodyData);
    _store.remove(_keyBodyDataHistory);
    _prefs?.remove('${_keyPrefsPrefix}fitplan_settings');
    _prefs?.remove('${_keyPrefsPrefix}fitplan_stats');
    _prefs?.remove('${_keyPrefsPrefix}fitplan_bodyData');
    _prefs?.remove('${_keyPrefsPrefix}fitplan_bodyDataHistory');
  }

  static bool hasData() {
    return _plansCache.isNotEmpty || _recordsCache.isNotEmpty;
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
