// lib/services/plan_unlock_service.dart
import 'dart:convert';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import 'points_service.dart';

enum UnlockResult {
  success,
  insufficientPoints,
  alreadyUnlocked,
  unknownPlan,
}

class PlanUnlockInfo {
  final String planId;
  final int unlockTime;
  final int expireTime;

  const PlanUnlockInfo({
    required this.planId,
    required this.unlockTime,
    required this.expireTime,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expireTime;

  int get remainingDays {
    if (isExpired) return 0;
    final ms = expireTime - DateTime.now().millisecondsSinceEpoch;
    return (ms / (24 * 60 * 60 * 1000)).ceil();
  }

  factory PlanUnlockInfo.fromJson(Map<String, dynamic> json) {
    return PlanUnlockInfo(
      planId: json['planId'] as String,
      unlockTime: (json['unlockTime'] as num).toInt(),
      expireTime: (json['expireTime'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'unlockTime': unlockTime,
        'expireTime': expireTime,
      };
}

class PlanUnlockService {
  static final PlanUnlockService instance = PlanUnlockService._();
  PlanUnlockService._();

  static const int _validityMs = kPlanUnlockValidityDays * 24 * 60 * 60 * 1000;

  /// 检查计划是否已解锁且在有效期内
  bool isPlanUnlocked(String planId) {
    final info = getUnlockInfo(planId);
    return info != null && !info.isExpired;
  }

  /// 获取解锁信息（可能已过期）
  PlanUnlockInfo? getUnlockInfo(String planId) {
    final list = _readRecords();
    try {
      final match = list.firstWhere((r) => r.planId == planId);
      return match;
    } catch (_) {
      return null;
    }
  }

  /// 解锁精品计划
  /// 返回 success 表示扣费成功且已解锁
  Future<UnlockResult> unlockPlan(String planId, int cost) async {
    final plan = SystemPlanLibrary.instance.getById(planId);
    if (plan == null) return UnlockResult.unknownPlan;
    if (!plan.isPremium) return UnlockResult.alreadyUnlocked;

    if (isPlanUnlocked(planId)) return UnlockResult.alreadyUnlocked;

    final success = await PointsService.instance.spendPoints(
      cost,
      'unlock_plan_$planId',
    );
    if (!success) return UnlockResult.insufficientPoints;

    final now = DateTime.now().millisecondsSinceEpoch;
    final info = PlanUnlockInfo(
      planId: planId,
      unlockTime: now,
      expireTime: now + _validityMs,
    );

    final list = _readRecords();
    list.removeWhere((r) => r.planId == planId); // 替换旧记录
    list.add(info);
    _writeRecords(list);

    Storage.dataChanged.value = !Storage.dataChanged.value;
    return UnlockResult.success;
  }

  /// 清理已过期的解锁记录（可选调用，节省存储）
  void cleanExpiredRecords() {
    final list = _readRecords();
    final before = list.length;
    list.removeWhere((r) => r.isExpired);
    if (list.length != before) {
      _writeRecords(list);
    }
  }

  // ── 内部辅助 ──────────────────────────────────────────

  List<PlanUnlockInfo> _readRecords() {
    final settings = Storage.getSettings();
    final raw = settings['planUnlockRecords'] as String? ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => PlanUnlockInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _writeRecords(List<PlanUnlockInfo> records) {
    final settings = Storage.getSettings();
    settings['planUnlockRecords'] = jsonEncode(
      records.map((r) => r.toJson()).toList(),
    );
    Storage.saveSettings(settings);
  }
}
