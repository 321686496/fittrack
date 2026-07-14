import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'services/permission_service.dart';
import 'services/rest_notification_service.dart';
import 'services/smart_push_service.dart';
import 'services/iap_service.dart';
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
    // 初始化智能推送服务
    await SmartPushService.instance.init();
    // 初始化 IAP 服务（Android/iOS only, OHOS 使用兑换码路径）
    await IapService.instance.init();
    // 初始化桌面卡片服务（OHOS）
    if (Platform.isOhos) {
      FormKitService.instance.init();
      // 初始化通知点击监听（RestNotificationService.init 内部也会调用，此处幂等）
      OhosReminderService.instance.initListener();
      // 监听卡片点击事件
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        if (targetPage == 'training') {
          // 卡片训练交互：优先交给正在运行的训练页处理（跳过休息 / 回到训练），
          // 避免跳转到首页导致训练页被销毁、数据丢失。
          final handler = OhosReminderService.instance.onTrainingCardAction;
          if (handler != null) {
            // 训练页已挂载：由训练页原地处理 cardAction（skipRest / resume）。
            handler(args);
          } else {
            // 训练页未挂载（例如已退出训练）：回到首页兜底。
            _globalRouter?.go('/home');
          }
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
      };
    }
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

class _FitTrackAppState extends State<FitTrackApp> with WidgetsBindingObserver {
  late String _currentThemeId;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentThemeId = Storage.getSettings()['theme'] ?? 'vitality-sport';
    _router = app_router.createRouter();
    _globalRouter = _router;
    // 设置全局主题变更回调
    app_router.onThemeChanged = _onThemeChanged;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时触发智能推送检查（fire-and-forget，
      // maybePushNow 内部已处理所有失败路径）。
      SmartPushService.instance.maybePushNow();
    }
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
