import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'services/permission_service.dart';
import 'services/rest_notification_service.dart';
import 'services/form_kit_service.dart';
import 'services/ohos_reminder_service.dart';
import 'router.dart' as app_router;

/// 全局路由器引用（用于卡片点击等场景的导航）
GoRouter? _globalRouter;

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      debugPrint('Stack: ${details.stack}');
    };

    // 初始化 timezone 数据库（用于定时通知，必须在 RestNotificationService.init 之前）
    tz_data.initializeTimeZones();

    try {
      await Storage.init();
      // 预加载 SQLite 中的 Plans/Records 到内存缓存
      await Storage.getPlansAsync();
      await Storage.getRecordsAsync();
      await Storage.getGymCardsAsync();
    } catch (e, stack) {
      debugPrint('Storage.init() failed: $e');
      debugPrint('Stack: $stack');
    }
    // 启动后异步请求核心权限（不阻塞启动）
    PermissionService.requestCorePermissions();
    // 初始化休息通知服务（内部会配置时区并 await 完成）
    await RestNotificationService.instance.init();
    // 初始化桌面卡片服务（OHOS）
    if (Platform.isOhos) {
      FormKitService.instance.init();
      // 初始化通知点击监听
      OhosReminderService.instance.initListener();
      // 监听卡片点击事件
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        final cardAction = args['cardAction'] as String?;
        if (targetPage == 'training') {
          // 卡片训练交互：跳转到训练页（如果已在训练页，由训练页处理 cardAction）
          _globalRouter?.go('/home');
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
      };
      // 发布每日训练提醒（如果已设置训练时间）
      _scheduleTrainingReminderIfNeeded();
    }
    runApp(const FitTrackApp());
  }, (error, stack) {
    debugPrint('Unhandled error: $error');
    debugPrint('Stack: $stack');
  });
}

Future<void> _scheduleTrainingReminderIfNeeded() async {
  final settings = Storage.getSettings();
  final trainingTime = settings['trainingTime'] as String? ?? '';
  if (trainingTime.isNotEmpty) {
    await OhosReminderService.instance.scheduleTrainingReminder(
      title: '训练时间到',
      content: '你设定的训练时间已到，开始今天的训练吧！',
      timeStr: trainingTime,
    );
  }
}

class FitTrackApp extends StatefulWidget {
  const FitTrackApp({super.key});

  @override
  State<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends State<FitTrackApp> {
  late String _currentThemeId;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _currentThemeId = Storage.getSettings()['theme'] ?? 'vitality-sport';
    _router = app_router.createRouter();
    _globalRouter = _router;
    // 设置全局主题变更回调
    app_router.onThemeChanged = _onThemeChanged;
  }

  void _onThemeChanged(String themeId) {
    setState(() {
      _currentThemeId = themeId;
    });
    final settings = Storage.getSettings();
    settings['theme'] = themeId;
    Storage.saveSettings(settings);
    // 更新桌面卡片主题
    if (Platform.isOhos) {
      FormKitService.instance.pushFormData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_currentThemeId),
      routerConfig: _router,
    );
  }
}
