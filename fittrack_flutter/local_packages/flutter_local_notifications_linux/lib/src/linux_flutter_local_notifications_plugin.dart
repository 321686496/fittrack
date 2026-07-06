import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/timezone.dart';

class LinuxFlutterLocalNotificationsPlugin
    extends FlutterLocalNotificationsPlatform {
  static void registerWith() {
    FlutterLocalNotificationsPlatform.instance =
        LinuxFlutterLocalNotificationsPlugin();
  }

  @override
  Future<String?> resolvePlatformSpecificImplementation(
      FlutterLocalNotificationsPlatform? platform) async {
    return null;
  }

  @override
  Future<bool?> initialize({
    String? defaultIcon,
    List<DarwinNotificationCategory>? iOSNotificationCategories,
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return null;
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [];
  }

  @override
  Future<NotificationDetails> resolveNotificationDetails(
    NotificationDetails? genericPlatformData,
  ) async {
    return const NotificationDetails();
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> periodicallyShow({
    required int id,
    String? title,
    String? body,
    required RepeatInterval repeatInterval,
    NotificationDetails? notificationDetails,
    String? payload,
    DateTime? scheduledTime,
    String? matchDateTimeComponents,
  }) async {}

  @override
  Future<void> periodicallyShowWithDuration({
    required int id,
    String? title,
    String? body,
    required Duration frequency,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required TZDateTime scheduledDate,
    required Future<dynamic> Function(int, String?, String?, String?)?
        androidScheduleMode,
    NotificationDetails? notificationDetails,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    String? uiLocalNotificationDateInterpretation,
    bool androidAllowWhileIdle = false,
  }) async {}

  @override
  Map<String, dynamic>? toMap() => null;
}
