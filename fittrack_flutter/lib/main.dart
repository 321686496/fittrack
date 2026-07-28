import 'dart:async';
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
      // 回到前台时检查健身卡到期提醒（同日只推一次）
      GymCardReminderService.instance.checkAndPush();
      // 回到前台时重新调度每日训练提醒（防止系统杀后台后调度丢失）
      DailyReminderService.instance.reschedule();
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
    // 更新桌面卡片主题（通过 PAL 统一推送空闲态，三平台一致）
    PlatformServices.widgetCard.pushCardData(
      const WidgetCardData(mode: WidgetCardMode.idle),
    );
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
