import 'dart:async';
import '../../android_alarm_service.dart';
import '../rest_reminder_service.dart';

class AndroidRestReminderService implements RestReminderService {
  final AndroidAlarmService _delegate = AndroidAlarmService.instance;

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _delegate.initListener();
    _delegate.onCardClick = (args) {
      _clickController.add(RestReminderEvent.fromMap(args));
    };
  }

  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) {
    return _delegate.scheduleRestAlarm(
      title: title,
      content: content,
      exerciseName: '',
      triggerTimeInSeconds: triggerTimeInSeconds,
      notificationId: notificationId,
    );
  }

  @override
  Future<void> cancelCurrentReminder() => _delegate.cancelRestAlarm();

  @override
  Future<void> cancelAllReminders() => _delegate.cancelAllAlarms();

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
