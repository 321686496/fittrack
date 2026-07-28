import 'dart:async';

class RestReminderEvent {
  final String? targetPage;
  final String? cardAction;
  final Map<String, dynamic> payload;

  RestReminderEvent({this.targetPage, this.cardAction, required this.payload});

  factory RestReminderEvent.fromMap(Map<String, dynamic> map) =>
      RestReminderEvent(
        targetPage: map['targetPage'] as String?,
        cardAction: map['cardAction'] as String?,
        payload: map,
      );
}

abstract class RestReminderService {
  Future<void> init();
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  });
  Future<void> cancelCurrentReminder();
  Future<void> cancelAllReminders();
  Stream<RestReminderEvent> get onNotificationClick;
}
