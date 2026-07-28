import 'dart:async';
import 'rest_reminder_service.dart';
import 'live_view_service.dart';
import 'widget_card_service.dart';
import 'invite_url_service.dart';

class NoopRestReminderService implements RestReminderService {
  @override
  Future<void> init() async {}
  @override
  Future<int?> scheduleRestReminder({
    required String title,
    required String content,
    required int triggerTimeInSeconds,
    required int notificationId,
  }) async => null;
  @override
  Future<void> cancelCurrentReminder() async {}
  @override
  Future<void> cancelAllReminders() async {}
  @override
  Stream<RestReminderEvent> get onNotificationClick => const Stream.empty();
}

class NoopLiveViewService implements LiveViewService {
  @override
  Future<void> init() async {}
  @override
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  }) async {}
  @override
  Future<void> stopRestLiveView() async {}
  @override
  Stream<LiveViewEvent> get onUserAction => const Stream.empty();
}

class NoopWidgetCardService implements WidgetCardService {
  @override
  Future<void> init() async {}
  @override
  Future<void> pushCardData(WidgetCardData data) async {}
  @override
  Future<void> clearCardData() async {}
  @override
  Stream<WidgetCardClickEvent> get onCardClick => const Stream.empty();
}

class NoopInviteUrlService implements InviteUrlService {
  @override
  Future<void> registerHandler(Future<void> Function(Uri uri) handler) async {}
  @override
  Future<void> launchInviteUrl(Uri uri) async {}
}
