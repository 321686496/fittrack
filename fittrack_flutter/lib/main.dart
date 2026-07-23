import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'data/system_plan_library.dart';
import 'services/permission_service.dart';
import 'services/rest_notification_service.dart';
import 'services/smart_push_service.dart';
import 'services/iap_service.dart';
import 'services/form_kit_service.dart';
import 'services/ohos_reminder_service.dart';
import 'services/android_alarm_service.dart';
import 'services/rom_adaptation_service.dart';
import 'services/retention_chain_service.dart';
import 'services/points_service.dart';
import 'services/sound_service.dart';
import 'widgets/rom_guidance_sheet.dart';
import 'router.dart' as app_router;
import 'utils/platform_utils.dart';

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
      // 加载系统训练计划库（assets/data/system_plans/*.json）
      await SystemPlanLibrary.instance.load();
      // 预加载 SQLite 中的 Plans/Records 到内存缓存
      await Storage.getPlansAsync();
      await Storage.getRecordsAsync();
      await Storage.getGymCardsAsync();
      // v1 V1-11: 预加载训练笔记缓存
      await Storage.getNotesAsync();
      // v1 积分体系：预加载积分日志
      PointsService.instance.getPointsLog();
    } catch (e, stack) {
      debugPrint('Storage.init() failed: $e');
      debugPrint('Stack: $stack');
    }
    // 初始化音效服务（读取设置中的开关状态）
    await SoundService.instance.init();
    // 启动后异步请求核心权限（不阻塞启动）
    PermissionService.requestCorePermissions();
    // 初始化休息通知服务（内部会配置时区并 await 完成）
    await RestNotificationService.instance.init();
    // 初始化智能推送服务
    await SmartPushService.instance.init();
    // v1 V1-04: 初始化新手7天留存链服务
    await RetentionChainService.instance.init();
    // 初始化 IAP 服务（Android/iOS only, OHOS 使用兑换码路径）
    await IapService.instance.init();
    // 初始化桌面卡片服务（OHOS）
    if (isOhos) {
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
  bool _romGuidanceShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentThemeId = Storage.getSettings()['theme'] ?? 'vitality-sport';
    _router = app_router.createRouter();
    _globalRouter = _router;
    // 设置全局主题变更回调
    app_router.onThemeChanged = _onThemeChanged;
    // Android: 启动后延迟检查 ROM 适配
    if (!isOhos) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkRomAdaptationOnStartup();
      });
    }
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
      // Android: 回到前台时重新检查 ROM 适配状态
      if (!isOhos) {
        _checkRomAdaptationOnResume();
      }
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
    if (isOhos) {
      FormKitService.instance.pushFormData();
    }
  }

  /// Android: 启动后检查 ROM 适配，仅对国产 ROM 且未优化的用户弹出引导
  Future<void> _checkRomAdaptationOnStartup() async {
    if (_romGuidanceShown) return;
    final romService = RomAdaptationService.instance;

    final needsGuidance = await romService.needsRomGuidance();
    if (!needsGuidance) return;

    final settings = Storage.getSettings();
    // 用户已关闭引导则不再弹窗
    if (settings['romGuidanceDismissed'] == true) return;

    // 不阻塞 UI 显示，稍等片刻后再弹窗
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _romGuidanceShown = true;

    RomGuidanceSheet.show(context, onDismiss: () {
      // 不强制，用户点"稍后设置"后 7 天内不再弹窗
      final s = Storage.getSettings();
      s['romGuidanceDismissed'] = true;
      s['romGuidanceDismissTime'] = DateTime.now().toIso8601String();
      Storage.saveSettings(s);
    });
  }

  /// Android: 回到前台时检查 ROM 适配状态（用户可能在后台设置完自启动后返回）
  Future<void> _checkRomAdaptationOnResume() async {
    if (_romGuidanceShown) return;
    final romService = RomAdaptationService.instance;

    // 用户已完成优化，重置引导状态
    final needsGuidance = await romService.needsRomGuidance();
    if (!needsGuidance) {
      final s = Storage.getSettings();
      if (s['romGuidanceDismissed'] == true) {
        s['romGuidanceDismissed'] = false;
        s.remove('romGuidanceDismissTime');
        Storage.saveSettings(s);
        _romGuidanceShown = false;
      }
      return;
    }

    // 仍需要引导，检查是否超过 7 天未设置
    final s = Storage.getSettings();
    final dismissTimeStr = s['romGuidanceDismissTime'] as String? ?? '';
    if (dismissTimeStr.isNotEmpty) {
      try {
        final dismissTime = DateTime.parse(dismissTimeStr);
        final daysSince = DateTime.now().difference(dismissTime).inDays;
        if (daysSince >= 7) {
          s['romGuidanceDismissed'] = false;
          s.remove('romGuidanceDismissTime');
          Storage.saveSettings(s);
          _romGuidanceShown = false;
        }
      } catch (_) {}
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
