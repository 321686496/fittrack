import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

class FlutterLocalNotificationsLinuxPlugin
    extends FlutterLocalNotificationsPlatform {
  static void registerWith() {
    FlutterLocalNotificationsPlatform.instance =
        FlutterLocalNotificationsLinuxPlugin();
  }

  @override
  Future<String?> resolvePlatformSpecificImplementation(
      FlutterLocalNotificationsPlatform? platform) {
    return null;
  }

  @override
  Future<bool?> initialize(
    InitializationSettings settings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
    List<DarwinNotificationCategory>? iOSNotificationCategories,
    String? defaultIcon,
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
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id, {String? tag}) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> periodicallyShow(
    int id,
    String? title,
    String? body,
    RepeatInterval repeatInterval,
    NotificationDetails? notificationDetails, {
    String? payload,
    DateTime? scheduledTime,
    String? matchDateTimeComponents,
  }) async {}

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    TZDateTime scheduledDate,
    NotificationDetails? notificationDetails, {
    @required Future<dynamic> Function(int, String?, String?, String?)?
        androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    String? uiLocalNotificationDateInterpretation,
    bool androidAllowWhileIdle = false,
  }) async {}

  @override
  Future<void> periodicallyShowWithDuration(
    int id,
    String? title,
    String? body,
    Duration? frequency,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {}

  @override
  Map<String, dynamic>? toMap() => null;
}
