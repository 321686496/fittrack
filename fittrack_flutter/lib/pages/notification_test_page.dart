import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/rest_notification_service.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';
import 'package:go_router/go_router.dart';

/// 通知测试页面 —— 用于验证通知功能是否可用
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  final List<String> _logs = [];
  bool _isInitialized = false;
  bool _permissionGranted = false;
  FlutterLocalNotificationsPlugin? _plugin;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _log(String msg) {
    debugPrint('[NotificationTest] $msg');
    setState(() {
      _logs.insert(0, '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _checkStatus() async {
    final service = RestNotificationService.instance;
    _plugin = FlutterLocalNotificationsPlugin();
    _log('Platform: ${Platform.isOhos ? "OHOS" : Platform.isAndroid ? "Android" : Platform.operatingSystem}');
    _log('Service initialized: ${service.isInitialized}');
    _isInitialized = service.isInitialized;
    _log('Plugin instance: ${service.plugin != null ? "available" : "null"}');
    _log('Timezone: ${tz.local.name}');
    setState(() {});
  }

  Future<void> _requestPermission() async {
    _log('Requesting notification permission...');
    try {
      final plugin = RestNotificationService.instance.plugin ?? _plugin!;
      if (Platform.isOhos) {
        final ohosPlugin = plugin.resolvePlatformSpecificImplementation<
            OhosFlutterLocalNotificationsPlugin>();
        if (ohosPlugin != null) {
          final result = await ohosPlugin.requestNotificationsPermission();
          _log('OHOS permission result: $result');
          _permissionGranted = result ?? false;
        } else {
          _log('ERROR: ohosPlugin is null');
        }
      } else if (Platform.isAndroid) {
        final androidPlugin = plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final result = await androidPlugin.requestNotificationsPermission();
          _log('Android permission result: $result');
          _permissionGranted = result ?? false;
        } else {
          _log('ERROR: androidPlugin is null');
        }
      }
    } catch (e) {
      _log('Permission error: $e');
    }
    setState(() {});
  }

  Future<void> _reInit() async {
    _log('Re-initializing RestNotificationService...');
    try {
      final service = RestNotificationService.instance;
      await service.init();
      _isInitialized = service.isInitialized;
      _log('Re-init result: $_isInitialized');
    } catch (e) {
      _log('Re-init error: $e');
    }
    setState(() {});
  }

  Future<void> _showNow() async {
    _log('Attempting to show notification NOW...');
    try {
      final plugin = RestNotificationService.instance.plugin ?? _plugin!;
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        '测试通知渠道',
        channelDescription: '用于测试通知是否可用',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );
      const ohosDetails = OhosNotificationDetails(
        OhosNotificationSlotType.SOCIAL_COMMUNICATION,
        slotDesc: '测试通知渠道',
        importance: OhosImportance.high,
        enableVibration: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        ohos: ohosDetails,
      );

      await plugin.show(
        9999,
        '测试通知',
        '如果你看到了这条通知，说明通知功能正常！',
        details,
      );
      _log('plugin.show() called successfully - check notification bar');
    } catch (e) {
      _log('show() error: $e');
    }
  }

  Future<void> _showWithService() async {
    _log('Attempting showRestEndNotification via service...');
    try {
      await RestNotificationService.instance.showRestEndNotification(
        exerciseName: '测试动作',
      );
      _log('showRestEndNotification() called - check notification bar');
    } catch (e) {
      _log('showRestEndNotification() error: $e');
    }
  }

  Future<void> _schedule5s() async {
    _log('Scheduling notification in 5 seconds (zonedSchedule)...');
    try {
      final plugin = RestNotificationService.instance.plugin ?? _plugin!;
      final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      _log('Scheduled time: $scheduledDate');
      _log('Current time: ${tz.TZDateTime.now(tz.local)}');

      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        '测试通知渠道',
        channelDescription: '用于测试通知是否可用',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );
      const ohosDetails = OhosNotificationDetails(
        OhosNotificationSlotType.SOCIAL_COMMUNICATION,
        slotDesc: '测试通知渠道',
        importance: OhosImportance.high,
        enableVibration: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        ohos: ohosDetails,
      );

      await plugin.zonedSchedule(
        9998,
        '5秒定时通知',
        '这是5秒后到达的定时通知测试',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('zonedSchedule() called - wait 5 seconds');
    } catch (e) {
      _log('zonedSchedule() error: $e');
    }
  }

  Future<void> _scheduleDartTimer5s() async {
    _log('Scheduling notification in 5 seconds (Dart Timer + show)...');
    try {
      Timer(const Duration(seconds: 5), () async {
        _log('Dart Timer fired! Calling show()...');
        try {
          final plugin = RestNotificationService.instance.plugin ?? _plugin!;
          const androidDetails = AndroidNotificationDetails(
            'test_channel',
            '测试通知渠道',
            channelDescription: '用于测试通知是否可用',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
          );
          const ohosDetails = OhosNotificationDetails(
            OhosNotificationSlotType.SOCIAL_COMMUNICATION,
            slotDesc: '测试通知渠道',
            importance: OhosImportance.high,
            enableVibration: true,
          );
          const details = NotificationDetails(
            android: androidDetails,
            ohos: ohosDetails,
          );
          await plugin.show(
            9997,
            'Dart Timer 5秒通知',
            '这是通过 Dart Timer + show() 发出的5秒定时通知',
            details,
          );
          _log('show() after Timer called successfully');
        } catch (e) {
          _log('show() after Timer error: $e');
        }
      });
      _log('Dart Timer started - wait 5 seconds (keep app in foreground!)');
    } catch (e) {
      _log('Dart Timer error: $e');
    }
  }

  Future<void> _scheduleViaService() async {
    _log('Scheduling via service in 5 seconds...');
    try {
      await RestNotificationService.instance.scheduleRestEndNotification(
        exerciseName: '测试动作',
        delaySeconds: 5,
      );
      _log('scheduleRestEndNotification() called - wait 5 seconds');
    } catch (e) {
      _log('scheduleRestEndNotification() error: $e');
    }
  }

  Future<void> _cancelAll() async {
    _log('Cancelling all notifications...');
    try {
      await RestNotificationService.instance.cancelAll();
      _log('All notifications cancelled');
    } catch (e) {
      _log('cancelAll() error: $e');
    }
  }

  Future<void> _vibrate() async {
    _log('Testing vibration...');
    try {
      await RestNotificationService.vibrate();
      _log('Vibration triggered');
    } catch (e) {
      _log('Vibration error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '通知测试',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status info
                  _buildStatusCard(colors),
                  const SizedBox(height: 16),

                  // Action buttons
                  _buildSectionTitle(colors, '基础操作'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildButton(colors, '重新初始化', Icons.refresh, _reInit),
                      _buildButton(colors, '请求权限', Icons.notifications_active, _requestPermission),
                      _buildButton(colors, '振动测试', Icons.vibration, _vibrate),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle(colors, '直接发送通知'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildButton(colors, '立即通知(plugin)', Icons.notifications, _showNow),
                      _buildButton(colors, '立即通知(service)', Icons.notifications, _showWithService),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle(colors, '定时通知'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildButton(colors, '5秒后(zonedSchedule)', Icons.schedule, _schedule5s),
                      _buildButton(colors, '5秒后(Dart Timer)', Icons.timer, _scheduleDartTimer5s),
                      _buildButton(colors, '5秒后(service)', Icons.schedule, _scheduleViaService),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildSectionTitle(colors, '其他'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildButton(colors, '取消所有通知', Icons.cancel, _cancelAll),
                      _buildButton(colors, '清除日志', Icons.delete_outline, () => setState(() => _logs.clear())),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Log output
                  _buildSectionTitle(colors, '日志输出'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _logs.isEmpty
                        ? const Text('暂无日志', style: TextStyle(color: Colors.grey, fontSize: 12))
                        : SingleChildScrollView(
                            reverse: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _logs.map((log) {
                                Color color = Colors.greenAccent;
                                if (log.contains('error') || log.contains('ERROR')) {
                                  color = Colors.redAccent;
                                } else if (log.contains('null') || log.contains('false')) {
                                  color = Colors.orangeAccent;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    log,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(FitTrackColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('状态信息', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildStatusRow(colors, '平台', Platform.isOhos ? 'OHOS (HarmonyOS)' : Platform.operatingSystem),
          _buildStatusRow(colors, 'Service 已初始化', _isInitialized ? '是' : '否',
              valueColor: _isInitialized ? Colors.greenAccent : Colors.redAccent),
          _buildStatusRow(colors, '权限已授予', _permissionGranted ? '是' : '否',
              valueColor: _permissionGranted ? Colors.greenAccent : Colors.orangeAccent),
          _buildStatusRow(colors, '时区', tz.local.name),
        ],
      ),
    );
  }

  Widget _buildStatusRow(FitTrackColors colors, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(FitTrackColors colors, String title) {
    return Text(
      title,
      style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildButton(FitTrackColors colors, String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.bgCard,
        foregroundColor: colors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.borderColor),
        ),
      ),
    );
  }
}
