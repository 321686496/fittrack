import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'themes/app_themes.dart';
import 'data/storage.dart';
import 'data/system_plan_library.dart';
import 'services/permission_service.dart';
import 'services/rest_notification_service.dart';
import 'services/smart_push_service.dart';
import 'services/iap_service.dart';
import 'services/ohos_reminder_service.dart';
import 'services/rom_adaptation_service.dart';
import 'services/platform/platform_services.dart';
import 'services/platform/widget_card_service.dart';
import 'services/retention_chain_service.dart';
import 'services/points_service.dart';
import 'services/sound_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/gym_card_reminder_service.dart';
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
    // 尽早配置本地时区：DailyReminder/GymCardReminder 等服务的初始化与
    // RestNotificationService.init 并行执行，若不在此处设置 tz.local，
    // 它们可能使用默认 UTC 时区调度，导致通知在错误时间触发（如国内偏移 8 小时）。
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      } catch (_) {}
    }

    try {
      await Storage.init();
      // 加载系统训练计划库 + 预加载 SQLite 缓存：并行执行（无相互依赖）
      await Future.wait([
        SystemPlanLibrary.instance.load(),
        Storage.getPlansAsync(),
        Storage.getRecordsAsync(),
        Storage.getGymCardsAsync(),
        Storage.getNotesAsync(),
      ]);
      // v1 积分体系：预加载积分日志
      PointsService.instance.getPointsLog();
    } catch (e, stack) {
      debugPrint('Storage.init() failed: $e');
      debugPrint('Stack: $stack');
    }
    // 音效服务初始化（与下方通知/推送服务无依赖，可并行）
    final soundFuture = SoundService.instance.init();
    // 启动后异步请求核心权限（不阻塞启动）
    PermissionService.requestCorePermissions();
    // 通知/推送/留存/IAP 服务之间无依赖，并行初始化
    await Future.wait([
      soundFuture,
      RestNotificationService.instance.init(),
      SmartPushService.instance.init(),
      RetentionChainService.instance.init(),
      IapService.instance.init(),
      DailyReminderService.instance.init(),
      GymCardReminderService.instance.init(),
    ]);
    // 启动后立即检查一次健身卡到期（fire-and-forget）
    GymCardReminderService.instance.checkAndPush();
    // 启动兜底：重新调度健身卡到期提醒（防止系统升级/数据迁移后调度丢失）
    GymCardReminderService.instance.reschedule();
    // 初始化平台抽象层（PAL）—— 根据当前平台注入对应实现
    await PlatformServices.init();
    // 注册邀请链接处理器（解析 fittrack://invite?code=XXX）
    PlatformServices.inviteUrl.registerHandler((uri) async {
      debugPrint('[Invite] Received URL: $uri');
      if (uri.host == 'invite') {
        final code = uri.queryParameters['code'];
        if (code != null && code.isNotEmpty) {
          _globalRouter?.go('/home?inviteCode=$code');
        }
      }
    });
    // OHOS: 注册原生卡片点击回调，统一转发到 PAL 事件流
    // （Android/iOS 的点击事件由各自 PAL 实现内部通过 MethodChannel 监听）
    final ohosLiveView = PlatformServices.ohosLiveView;
    final ohosWidgetCard = PlatformServices.ohosWidgetCard;
    if (ohosLiveView != null && ohosWidgetCard != null) {
      OhosReminderService.instance.onCardClick = (args) {
        final targetPage = args['targetPage'] as String?;
        if (targetPage == 'training') {
          final handler = OhosReminderService.instance.onTrainingCardAction;
          if (handler != null) {
            handler(args);
          } else {
            _globalRouter?.go('/home');
          }
        } else if (targetPage == 'home') {
          _globalRouter?.go('/home');
        }
        // 转发到 PAL 事件流（WidgetCardService.onCardClick / LiveViewService.onUserAction）
        ohosWidgetCard.handleCardClick(args);
        ohosLiveView.handleCardClick(args);
      };
    }
    runApp(const LiftTrackApp());
  }, (error, stack) {
    debugPrint('Unhandled error: $error');
    debugPrint('Stack: $stack');
  });
}

class LiftTrackApp extends StatefulWidget {
  const LiftTrackApp({super.key});

  @override
  State<LiftTrackApp> createState() => _LiftTrackAppState();
}

class _LiftTrackAppState extends State<LiftTrackApp> with WidgetsBindingObserver {
  late String _currentThemeId;
  late String _autoDarkMode;   // 'off' | 'system' | 'timed'
  late String _timedDarkTime;  // "HH:mm"
  Timer? _timedRefreshTimer;
  late String _lightThemeId;
  late String _darkThemeId;
  late final GoRouter _router;
  bool _romGuidanceShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = Storage.getSettings();
    _currentThemeId = settings['theme'] ?? 'vitality-sport';
    _autoDarkMode = settings['autoDarkMode'] as String? ?? 'off';
    _timedDarkTime = settings['timedDarkTime'] as String? ?? '18:00';
    _lightThemeId = settings['lightThemeId'] ?? 'vitality-sport';
    _darkThemeId = settings['darkThemeId'] ?? 'iron-forge';
    _router = app_router.createRouter();
    _globalRouter = _router;
    // 设置全局主题变更回调
    app_router.onThemeChanged = _onThemeChanged;
    _restartTimedTimerIfNeeded();
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
    _timedRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 应用回到前台时触发智能推送检查（fire-and-forget，
      // maybePushNow 内部已处理所有失败路径）。
      SmartPushService.instance.maybePushNow();
      // 回到前台时重新评估每日 20:00 智能提醒调度
      SmartPushService.instance.scheduleDailyCheck();
      // 回到前台时检查健身卡到期提醒（同日只推一次）
      GymCardReminderService.instance.checkAndPush();
      // 回到前台时重新调度健身卡后台提醒（防止系统杀后台/一次性提醒触发后调度丢失）
      GymCardReminderService.instance.reschedule();
      // 回到前台时重新调度每日训练提醒（防止系统杀后台后调度丢失）
      DailyReminderService.instance.reschedule();
      // 回到前台时检查今日训练提醒是否已触发并补写 App 内通知记录
      // （由于无法通过 wantAgent 传递 notificationType，需在前台补登记）
      DailyReminderService.instance.checkAndRecordNotification();
      // Android: 回到前台时重新检查 ROM 适配状态
      if (!isOhos) {
        _checkRomAdaptationOnResume();
      }
    }
  }

  void _onThemeChanged(
    String themeId, {
    bool? followSystem,
    String? lightThemeId,
    String? darkThemeId,
    String? autoDarkMode,
    String? timedDarkTime,
  }) {
    setState(() {
      _currentThemeId = themeId;
      if (followSystem != null) _autoDarkMode = followSystem ? 'system' : 'off';
      if (autoDarkMode != null) _autoDarkMode = autoDarkMode;
      if (timedDarkTime != null) _timedDarkTime = timedDarkTime;
      if (lightThemeId != null) _lightThemeId = lightThemeId;
      if (darkThemeId != null) _darkThemeId = darkThemeId;
    });
    _restartTimedTimerIfNeeded();
    final settings = Storage.getSettings();
    settings['theme'] = themeId;
    if (followSystem != null) settings['autoDarkMode'] = followSystem ? 'system' : 'off';
    if (autoDarkMode != null) settings['autoDarkMode'] = autoDarkMode;
    if (timedDarkTime != null) settings['timedDarkTime'] = timedDarkTime;
    if (lightThemeId != null) settings['lightThemeId'] = lightThemeId;
    if (darkThemeId != null) settings['darkThemeId'] = darkThemeId;
    Storage.saveSettings(settings);
    // ??????????? PAL ??????????????
    PlatformServices.widgetCard.pushCardData(
      const WidgetCardData(mode: WidgetCardMode.idle),
    );
  }

  /// timed 模式下：每分钟重算一次深浅主题，实现"到点自动切换"。
  /// 非 timed 模式：停止定时器，避免无效刷新与资源泄漏。
  void _restartTimedTimerIfNeeded() {
    _timedRefreshTimer?.cancel();
    _timedRefreshTimer = null;
    if (_autoDarkMode != 'timed') return;
    _timedRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {}); // 触发 rebuild，重新计算 themeMode
    });
  }

  ThemeMode _resolveThemeMode() {
    if (_autoDarkMode == 'system') return ThemeMode.system;
    if (_autoDarkMode == 'timed') {
      return LiftTrackTheme.isTimedDarkNow(_timedDarkTime) ? ThemeMode.dark : ThemeMode.light;
    }
    return ThemeMode.light; // 'off'
  }

  bool get _usesDayNightThemes => _autoDarkMode == 'system' || _autoDarkMode == 'timed';

  /// Android: ????? ROM ??????? ROM ???????????
  Future<void> _checkRomAdaptationOnStartup() async {
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
    if (_usesDayNightThemes) {
      // system / timed：日间用 lightThemeId、夜间用 darkThemeId
      return MaterialApp.router(
        title: 'LiftTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(_lightThemeId),
        darkTheme: AppTheme.getTheme(_darkThemeId),
        themeMode: _resolveThemeMode(),
        routerConfig: _router,
      );
    }
    // off：始终浅色，用用户手选主题
    return MaterialApp.router(
      title: 'LiftTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(_currentThemeId),
      darkTheme: AppTheme.getTheme(_currentThemeId),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
