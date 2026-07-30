/// lib/services/notification_storage_service.dart

import 'dart:math';
import '../data/storage.dart';

/// 通知记录存储服务
///
/// 封装各提醒服务调用 Storage 持久化通知记录的逻辑。
/// 生成唯一 id 供 Storage.addNotification 使用。
class NotificationStorageService {
  NotificationStorageService._();
  static final NotificationStorageService instance =
      NotificationStorageService._();

  /// 生成简单唯一 id（时间戳 + 随机数）
  String _genId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(10000).toString().padLeft(4, '0');
    return '${ts}_$rand';
  }

  /// 新增健身卡到期通知
  void addGymCardNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'gym_card',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增每日训练提醒通知
  void addDailyTrainingNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'daily_training',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增休息结束通知
  void addRestEndNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'rest_end',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }

  /// 新增系统通知
  void addSystemNotification(String title, String body) {
    Storage.addNotification({
      'id': _genId(),
      'type': 'system',
      'title': title,
      'body': body,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
  }
}
