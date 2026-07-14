import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// SQLite 数据库管理类
/// 管理训练计划和训练记录的结构化存储
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'fittrack.db';
  static const int _dbVersion = 3;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── 建表 ────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT '',
        difficulty TEXT NOT NULL DEFAULT '',
        frequency TEXT NOT NULL DEFAULT '',
        totalWeeks INTEGER NOT NULL DEFAULT 8,
        defaultRestTime INTEGER NOT NULL DEFAULT 90,
        week INTEGER NOT NULL DEFAULT 0,
        progress INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        badge TEXT NOT NULL DEFAULT '',
        days TEXT NOT NULL DEFAULT '[]',
        createTime INTEGER NOT NULL,
        updateTime INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE records (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL DEFAULT '',
        date INTEGER NOT NULL DEFAULT 0,
        duration INTEGER NOT NULL DEFAULT 0,
        totalWeight INTEGER NOT NULL DEFAULT 0,
        totalSets INTEGER NOT NULL DEFAULT 0,
        exerciseCount INTEGER NOT NULL DEFAULT 0,
        muscles TEXT NOT NULL DEFAULT '[]',
        setRecords TEXT NOT NULL DEFAULT '{}',
        restLog TEXT NOT NULL DEFAULT '[]',
        createTime INTEGER NOT NULL
      )
    ''');

    // 索引：按状态查计划、按日期查记录
    await db.execute('CREATE INDEX idx_plans_status ON plans(status)');
    await db.execute('CREATE INDEX idx_records_date ON records(date)');
    await db.execute('CREATE INDEX idx_records_createTime ON records(createTime)');

    // 健身卡表
    await db.execute('''
      CREATE TABLE gym_cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gymName TEXT NOT NULL DEFAULT '',
        cardType TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL DEFAULT 0,
        startDate INTEGER NOT NULL DEFAULT 0,
        endDate INTEGER NOT NULL DEFAULT 0,
        remainingCount INTEGER NOT NULL DEFAULT -1,
        totalCount INTEGER NOT NULL DEFAULT -1,
        phone TEXT NOT NULL DEFAULT '',
        remark TEXT NOT NULL DEFAULT '',
        createTime INTEGER NOT NULL,
        updateTime INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_gym_cards_endDate ON gym_cards(endDate)');

    // 成就表 (v3)
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        unlockedAt INTEGER NOT NULL DEFAULT 0,
        metadata TEXT NOT NULL DEFAULT '{}'
      )
    ''');
    await db.execute('CREATE INDEX idx_achievements_category ON achievements(category)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE gym_cards (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          gymName TEXT NOT NULL DEFAULT '',
          cardType TEXT NOT NULL DEFAULT '',
          price REAL NOT NULL DEFAULT 0,
          startDate INTEGER NOT NULL DEFAULT 0,
          endDate INTEGER NOT NULL DEFAULT 0,
          remainingCount INTEGER NOT NULL DEFAULT -1,
          totalCount INTEGER NOT NULL DEFAULT -1,
          phone TEXT NOT NULL DEFAULT '',
          remark TEXT NOT NULL DEFAULT '',
          createTime INTEGER NOT NULL,
          updateTime INTEGER NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_gym_cards_endDate ON gym_cards(endDate)');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          unlockedAt INTEGER NOT NULL DEFAULT 0,
          metadata TEXT NOT NULL DEFAULT '{}'
        )
      ''');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_achievements_category ON achievements(category)');
    }
  }

  // ── Plans CRUD ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllPlans() async {
    final db = await database;
    final rows = await db.query('plans', orderBy: 'createTime DESC');
    return rows.map(_planRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getPlanById(String id) async {
    final db = await database;
    final rows = await db.query('plans', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _planRowToMap(rows.first);
  }

  Future<Map<String, dynamic>> insertPlan(Map<String, dynamic> plan) async {
    final db = await database;
    final row = _planMapToRow(plan);
    await db.insert('plans', row, conflictAlgorithm: ConflictAlgorithm.replace);
    return plan;
  }

  Future<Map<String, dynamic>?> updatePlan(String planId, Map<String, dynamic> updates) async {
    final db = await database;
    final existing = await getPlanById(planId);
    if (existing == null) return null;
    final merged = {...existing, ...updates, 'updateTime': DateTime.now().millisecondsSinceEpoch};
    final row = _planMapToRow(merged);
    await db.update('plans', row, where: 'id = ?', whereArgs: [planId]);
    return merged;
  }

  Future<int> deletePlan(String planId) async {
    final db = await database;
    return db.delete('plans', where: 'id = ?', whereArgs: [planId]);
  }

  Future<int> deleteAllPlans() async {
    final db = await database;
    return db.delete('plans');
  }

  // ── Records CRUD ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await database;
    final rows = await db.query('records', orderBy: 'createTime DESC');
    return rows.map(_recordRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getRecordById(String id) async {
    final db = await database;
    final rows = await db.query('records', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _recordRowToMap(rows.first);
  }

  Future<Map<String, dynamic>> insertRecord(Map<String, dynamic> record) async {
    final db = await database;
    final row = _recordMapToRow(record);
    await db.insert('records', row, conflictAlgorithm: ConflictAlgorithm.replace);
    return record;
  }

  Future<int> deleteRecord(String recordId) async {
    final db = await database;
    return db.delete('records', where: 'id = ?', whereArgs: [recordId]);
  }

  Future<int> deleteAllRecords() async {
    final db = await database;
    return db.delete('records');
  }

  /// 保留最近 maxCount 条记录，删除更早的
  Future<int> trimRecords(int maxCount) async {
    final db = await database;
    final count = await db.delete(
      'records',
      where: 'id IN (SELECT id FROM records ORDER BY createTime DESC LIMIT -1 OFFSET ?)',
      whereArgs: [maxCount],
    );
    return count;
  }

  // ── 行 ↔ Map 转换 ──────────────────────────────────────────

  /// 数据库行 → 业务 Map（还原嵌套结构）
  Map<String, dynamic> _planRowToMap(Map<String, Object?> row) {
    final map = Map<String, dynamic>.from(row);
    // days 是 JSON 字符串，还原为 List
    if (map['days'] is String) {
      try {
        map['days'] = jsonDecode(map['days'] as String);
      } catch (_) {
        map['days'] = <Map<String, dynamic>>[];
      }
    }
    return map;
  }

  /// 业务 Map → 数据库行（days 序列化为 JSON）
  Map<String, Object?> _planMapToRow(Map<String, dynamic> map) {
    final row = Map<String, Object?>.from(map);
    // days 序列化为 JSON 字符串
    if (row['days'] is List) {
      row['days'] = jsonEncode(row['days']);
    }
    // 移除非数据库字段
    row.remove('icon');
    row.remove('desc');
    return row;
  }

  Map<String, dynamic> _recordRowToMap(Map<String, Object?> row) {
    final map = Map<String, dynamic>.from(row);
    // muscles: JSON 字符串 → List
    if (map['muscles'] is String) {
      try {
        map['muscles'] = jsonDecode(map['muscles'] as String);
      } catch (_) {
        map['muscles'] = [];
      }
    }
    // setRecords: JSON 字符串 → Map
    if (map['setRecords'] is String) {
      try {
        map['setRecords'] = jsonDecode(map['setRecords'] as String);
      } catch (_) {
        map['setRecords'] = {};
      }
    }
    // restLog: JSON 字符串 → List
    if (map['restLog'] is String) {
      try {
        map['restLog'] = jsonDecode(map['restLog'] as String);
      } catch (_) {
        map['restLog'] = [];
      }
    }
    return map;
  }

  Map<String, Object?> _recordMapToRow(Map<String, dynamic> map) {
    final row = Map<String, Object?>.from(map);
    if (row['muscles'] is List) {
      row['muscles'] = jsonEncode(row['muscles']);
    }
    if (row['setRecords'] is Map) {
      row['setRecords'] = jsonEncode(row['setRecords']);
    }
    if (row['restLog'] is List) {
      row['restLog'] = jsonEncode(row['restLog']);
    }
    return row;
  }

  // ── GymCards CRUD ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllGymCards() async {
    final db = await database;
    final rows = await db.query('gym_cards', orderBy: 'endDate ASC');
    return rows.map(_gymCardRowToMap).toList();
  }

  Future<Map<String, dynamic>?> getGymCardById(String id) async {
    final db = await database;
    final rows = await db.query('gym_cards', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _gymCardRowToMap(rows.first);
  }

  Future<Map<String, dynamic>> insertGymCard(Map<String, dynamic> card) async {
    final db = await database;
    final row = _gymCardMapToRow(card);
    await db.insert('gym_cards', row, conflictAlgorithm: ConflictAlgorithm.replace);
    return card;
  }

  Future<Map<String, dynamic>?> updateGymCard(String cardId, Map<String, dynamic> updates) async {
    final db = await database;
    final existing = await getGymCardById(cardId);
    if (existing == null) return null;
    final merged = {...existing, ...updates, 'updateTime': DateTime.now().millisecondsSinceEpoch};
    final row = _gymCardMapToRow(merged);
    await db.update('gym_cards', row, where: 'id = ?', whereArgs: [cardId]);
    return merged;
  }

  Future<int> deleteGymCard(String cardId) async {
    final db = await database;
    return db.delete('gym_cards', where: 'id = ?', whereArgs: [cardId]);
  }

  Future<int> deleteAllGymCards() async {
    final db = await database;
    return db.delete('gym_cards');
  }

  Map<String, dynamic> _gymCardRowToMap(Map<String, Object?> row) {
    return Map<String, dynamic>.from(row);
  }

  Map<String, Object?> _gymCardMapToRow(Map<String, dynamic> map) {
    return Map<String, Object?>.from(map);
  }

  // ── Achievements CRUD ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    final db = await database;
    return db.query('achievements');
  }

  Future<int> upsertAchievement(Map<String, dynamic> achievement) async {
    final db = await database;
    return db.insert('achievements', achievement,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
