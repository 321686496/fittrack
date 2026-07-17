import 'dart:convert';
import '../data/storage.dart';
import 'ad_service.dart';

enum PointsSource { checkIn, ad, invite, training, note, other }
enum PointsReason { unlockReport, unlockFeature, unlockCourse, other }

class PointsService {
  static final PointsService instance = PointsService._();
  PointsService._();

  static const int checkInPoints = 1;
  static const int adPoints = 5;
  static const int invitePoints = 50;
  static const int trainingPoints = 2;
  static const int notePoints = 1;
  static const int maxAdsPerDay = 3;

  int get points => Storage.getSettings()['points'] ?? 0;

  Future<void> addPoints(int amount, String source) async {
    final settings = Storage.getSettings();
    final current = settings['points'] as int? ?? 0;
    final earned = settings['pointsEarnedTotal'] as int? ?? 0;
    settings['points'] = current + amount;
    settings['pointsEarnedTotal'] = earned + amount;
    Storage.saveSettings(settings);
    _logTransaction(amount, source, current + amount);
    Storage.dataChanged.value = !Storage.dataChanged.value;
  }

  Future<bool> spendPoints(int amount, String reason) async {
    final settings = Storage.getSettings();
    final current = settings['points'] as int? ?? 0;
    if (current < amount) return false;
    final spent = settings['pointsSpentTotal'] as int? ?? 0;
    settings['points'] = current - amount;
    settings['pointsSpentTotal'] = spent + amount;
    Storage.saveSettings(settings);
    _logTransaction(-amount, reason, current - amount);
    Storage.dataChanged.value = !Storage.dataChanged.value;
    return true;
  }

  Future<bool> dailyCheckIn() async {
    final settings = Storage.getSettings();
    final today = _todayString();
    if (settings['lastCheckInDate'] == today) return false;
    settings['lastCheckInDate'] = today;
    Storage.saveSettings(settings);
    await addPoints(checkInPoints, 'checkIn');
    return true;
  }

  Future<bool> canWatchAd() async {
    final settings = Storage.getSettings();
    if (!AdService.adsEnabled) return false;
    final today = _todayString();
    final lastDate = settings['adsWatchedDate'] as String? ?? '';
    if (lastDate != today) return true;
    final watched = settings['adsWatchedToday'] as int? ?? 0;
    return watched < maxAdsPerDay;
  }

  Future<void> recordAdWatched() async {
    final settings = Storage.getSettings();
    final today = _todayString();
    final lastDate = settings['adsWatchedDate'] as String? ?? '';
    if (lastDate != today) {
      settings['adsWatchedDate'] = today;
      settings['adsWatchedToday'] = 1;
    } else {
      final watched = settings['adsWatchedToday'] as int? ?? 0;
      settings['adsWatchedToday'] = watched + 1;
    }
    Storage.saveSettings(settings);
    await addPoints(adPoints, 'ad');
  }

  bool isFeatureUnlocked(String featureId) {
    final settings = Storage.getSettings();
    final list = _getUnlockedList(settings);
    return list.contains(featureId);
  }

  Future<bool> unlockFeature(String featureId, int cost) async {
    if (isFeatureUnlocked(featureId)) return true;
    final success = await spendPoints(cost, 'unlock_$featureId');
    if (!success) return false;
    final settings = Storage.getSettings();
    final list = _getUnlockedList(settings);
    list.add(featureId);
    settings['unlockedFeatures'] = jsonEncode(list);
    Storage.saveSettings(settings);
    Storage.dataChanged.value = !Storage.dataChanged.value;
    return true;
  }

  List<String> _getUnlockedList(Map<String, dynamic> settings) {
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> getPointsLog() {
    final settings = Storage.getSettings();
    final raw = settings['pointsLog'] as String? ?? '[]';
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  void _logTransaction(int delta, String source, int balance) {
    final settings = Storage.getSettings();
    final logs = getPointsLog();
    logs.insert(0, {
      'time': DateTime.now().millisecondsSinceEpoch,
      'delta': delta,
      'source': source,
      'balance': balance,
    });
    if (logs.length > 50) logs.removeRange(50, logs.length);
    settings['pointsLog'] = jsonEncode(logs);
    Storage.saveSettings(settings);
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
