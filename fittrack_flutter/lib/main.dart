import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'services/permission_service.dart';
import 'services/rest_notification_service.dart';
import 'router.dart' as app_router;

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
    } catch (e, stack) {
      debugPrint('Storage.init() failed: $e');
      debugPrint('Stack: $stack');
    }
    // 启动后异步请求核心权限（不阻塞启动）
    PermissionService.requestCorePermissions();
    // 初始化休息通知服务（内部会配置时区并 await 完成）
    await RestNotificationService.instance.init();
    runApp(const FitTrackApp());
  }, (error, stack) {
    debugPrint('Unhandled error: $error');
    debugPrint('Stack: $stack');
  });
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
