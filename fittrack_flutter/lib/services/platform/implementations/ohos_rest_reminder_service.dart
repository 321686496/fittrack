import 'dart:async';
import '../../ohos_reminder_service.dart';
import '../rest_reminder_service.dart';

class OhosRestReminderService implements RestReminderService {
  final OhosReminderService _delegate = OhosReminderService.instance;

  final StreamController<RestReminderEvent> _clickController =
      StreamController<RestReminderEvent>.broadcast();

  @override
  Future<void> init() async {
    _delegate.initListener();
    _delegate.onNotificationClick = (args) {
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
    return _delegate.publishReminder(
      title: title,
      content: content,
      triggerTimeInSeconds: triggerTimeInSeconds,
      notificationId: notificationId,
    );
  }

  @override
  Future<void> cancelCurrentReminder() =>
      _delegate.cancelCurrentReminder();

  @override
  Future<void> cancelAllReminders() => _delegate.cancelAllReminders();

  @override
  Stream<RestReminderEvent> get onNotificationClick => _clickController.stream;
}
