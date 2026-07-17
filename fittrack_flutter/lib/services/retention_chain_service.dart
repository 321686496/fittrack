import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/storage.dart';
import '../utils/platform_utils.dart';

/// v1 新手7天留存链服务
///
/// 依据：docs/versions/v1-获客留存版/03_开发目标.md 任务2 [V1-04]
/// 02_功能清单.md §E7
///
/// 触发节点（基于首次训练日 D0）：
/// - Day2 (D+2): 拮抗肌群推荐推送 —— 基于D1训练部位推荐拮抗肌群
/// - Day4 (D+4): 温和召回推送 —— D2-4未训练时引导看训练日历
/// - Day7 (D+7): 首份周报弹窗 —— 本周训练天数/总重量/连续打卡
///
/// 防重复：每次弹窗/推送后写入 retentionChainLastShown，每个阶段仅触发一次
class RetentionChainService {
  static final RetentionChainService instance = RetentionChainService._();
  RetentionChainService._();

  static const int _notificationId = 3001;
  static const String _channelId = 'retention_chain_channel';
  static const String _channelName = '新手留存提醒';
  static const String _channelDesc = '新手7天留存链定时提醒';

  /// 拮抗肌群映射（用于 Day2 推荐）
  static const Map<String, String> _antagonistMuscle = {
    '胸': '背',
    '背': '胸',
    '腿': '肩',
    '肩': '腿',
    '臂': '腿',
    '手臂': '腿',
    '核心': '全身',
    '胸/肩': '背',
    '背/肩': '胸',
  };

  /// 留存链阶段枚举
  static const int stageDay2 = 2;
  static const int stageDay4 = 4;
  static const int stageDay7 = 7;

  FlutterLocalNotificationsPlugin? _plugin;

  /// 初始化通知渠道（应用启动时调用）
  Future<void> init() async {
    if (isOhos) return; // OHOS 由原生侧处理
    try {
      _plugin = FlutterLocalNotificationsPlugin();
      await _plugin
          ?.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.defaultImportance,
          ));
    } catch (e) {
      debugPrint('RetentionChainService.init() error: $e');
    }
  }

  /// 记录首次训练日（训练完成时调用）
  ///
  /// 仅在 firstTrainingDate 未设置时写入，保证只记录最早的训练日期
  void recordFirstTrainingIfNeeded() {
    final s = Storage.getSettings();
    if ((s['firstTrainingDate'] ?? 0) == 0) {
      s['firstTrainingDate'] = _todayMilli();
      Storage.saveSettings(s);
      debugPrint('RetentionChain: firstTrainingDate recorded');
    }
  }

  /// 主入口：检查并触发当日留存链
  ///
  /// 返回值：
  /// - 非 null：应显示 Day7 周报弹窗（包含周报数据）
  /// - null：无需弹窗（可能已推送通知或已展示过）
  Future<RetentionWeeklyReport?> checkAndTrigger() async {
    final s = Storage.getSettings();
    final firstTs = (s['firstTrainingDate'] ?? 0) as int;
    if (firstTs == 0) return null; // 还没训练过，不触发

    final daysSince = _daysSince(firstTs);
    final stage = (s['retentionChainStage'] ?? 0) as int;

    // Day2 推送
    if (daysSince >= stageDay2 && stage < stageDay2) {
      await _triggerDay2Push();
      _advanceStage(s, stageDay2);
      return null;
    }

    // Day4 推送
    if (daysSince >= stageDay4 && stage < stageDay4) {
      await _triggerDay4Push();
      _advanceStage(s, stageDay4);
      return null;
    }

    // Day7 周报弹窗
    if (daysSince >= stageDay7 && stage < stageDay7) {
      final report = _buildWeeklyReport(firstTs);
      _advanceStage(s, stageDay7);
      return report;
    }

    return null;
  }

  // ── Day2: 拮抗肌群推荐推送 ─────────────────────────────────

  Future<void> _triggerDay2Push() async {
    final records = Storage.getRecords();
    if (records.isEmpty) return;

    // 取最近一次训练（records 是倒序，第一条最新）
    // Day1 是首次训练，即列表最后一条
    final firstRecord = records.last;
    final muscles = (firstRecord['muscles'] as List?)?.cast<String>() ?? [];
    final primaryMuscle = muscles.isNotEmpty ? muscles.first : '';

    final antagonist = _antagonistMuscle[primaryMuscle] ?? '全身';
    final message = primaryMuscle.isNotEmpty
        ? '昨天的$primaryMuscle训练数据已保存，今天试试$antagonist?'
        : '昨天的训练数据已保存，今天继续加油吧!';

    await _sendPush('FitTrack Day2', message);
  }

  // ── Day4: 温和召回推送 ─────────────────────────────────────

  Future<void> _triggerDay4Push() async {
    final records = Storage.getRecords();
    // 检查 Day2-4 是否有训练
    final now = DateTime.now();
    final hasRecentTraining = records.any((r) {
      final ts = (r['date'] ?? r['createTime'] ?? 0) as int;
      if (ts == 0) return false;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      return now.difference(d).inDays < 4;
    });

    if (!hasRecentTraining) {
      await _sendPush(
        'FitTrack 想你了',
        '休息一下也不错，看看你的训练日历，规划下一次训练吧',
      );
    }
  }

  // ── Day7: 周报数据生成 ─────────────────────────────────────

  RetentionWeeklyReport _buildWeeklyReport(int firstTs) {
    final records = Storage.getRecords();
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final weekRecords = records.where((r) {
      final ts = (r['date'] ?? r['createTime'] ?? 0) as int;
      if (ts == 0) return false;
      return DateTime.fromMillisecondsSinceEpoch(ts).isAfter(weekStart);
    }).toList();

    final trainingDays = <String>{};
    var totalWeight = 0.0;
    var totalDuration = 0;
    final muscleSet = <String>{};

    for (final r in weekRecords) {
      final ts = (r['date'] ?? r['createTime'] ?? 0) as int;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      trainingDays.add('${d.year}-${d.month}-${d.day}');
      totalWeight += ((r['totalWeight'] ?? 0) as num).toDouble();
      totalDuration += ((r['duration'] ?? 0) as num).toInt();
      final muscles = (r['muscles'] as List?)?.cast<String>() ?? [];
      muscleSet.addAll(muscles);
    }

    final streak = _computeStreak(records);

    return RetentionWeeklyReport(
      trainingDays: trainingDays.length,
      totalWeight: totalWeight.toInt(),
      totalDuration: totalDuration,
      streak: streak,
      trainedMuscles: muscleSet.toList()..sort(),
      firstTrainingDate: DateTime.fromMillisecondsSinceEpoch(firstTs),
    );
  }

  int _computeStreak(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final dates = records
        .map((r) => DateTime.fromMillisecondsSinceEpoch(
            (r['date'] ?? r['createTime'] ?? 0) as int))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    // 如果今天没练，从昨天起算
    if (streak == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
      while (dates.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  // ── 工具方法 ───────────────────────────────────────────────

  void _advanceStage(Map<String, dynamic> s, int newStage) {
    s['retentionChainStage'] = newStage;
    s['retentionChainLastShown'] = _nowMilli();
    Storage.saveSettings(s);
  }

  int _daysSince(int fromMilli) {
    final from = DateTime.fromMillisecondsSinceEpoch(fromMilli);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(from.year, from.month, from.day))
        .inDays;
  }

  int _todayMilli() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
  }

  int _nowMilli() => DateTime.now().millisecondsSinceEpoch;

  Future<void> _sendPush(String title, String body) async {
    if (isOhos) return; // OHOS 由原生侧处理
    _plugin ??= FlutterLocalNotificationsPlugin();
    try {
      await _plugin!.show(
        _notificationId,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      debugPrint('RetentionChain push sent: $title');
    } catch (e) {
      debugPrint('RetentionChain push error: $e');
    }
  }
}

/// Day7 周报数据
class RetentionWeeklyReport {
  final int trainingDays; // 本周训练天数
  final int totalWeight; // 本周总重量(kg)
  final int totalDuration; // 本周总时长(秒)
  final int streak; // 连续打卡天数
  final List<String> trainedMuscles; // 训练过的肌群
  final DateTime firstTrainingDate; // 首次训练日

  const RetentionWeeklyReport({
    required this.trainingDays,
    required this.totalWeight,
    required this.totalDuration,
    required this.streak,
    required this.trainedMuscles,
    required this.firstTrainingDate,
  });

  /// 趣味类比：根据总重量返回类比文案
  String get weightAnalogy {
    if (totalWeight >= 1000) return '≈举起一头成年牛';
    if (totalWeight >= 500) return '≈举起半头牛';
    if (totalWeight >= 200) return '≈举起两只成年金毛';
    if (totalWeight >= 50) return '≈举起一袋大米';
    return '继续努力，积少成多';
  }

  /// 时长格式化
  String get durationText {
    final hours = (totalDuration / 3600).toStringAsFixed(1);
    return '${hours}h';
  }
}
