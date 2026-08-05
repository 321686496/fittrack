import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/mock_data.dart';
import '../services/rest_notification_service.dart';
import '../services/smart_push_service.dart';
import '../services/achievement_service.dart';
import '../services/ad_service.dart';
import '../services/points_service.dart';
import '../services/retention_chain_service.dart';
import '../services/sound_service.dart';
import '../data/virtual_opponent.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/poster_capture_helper.dart';
import '../widgets/rating_prompt_sheet.dart';
import '../widgets/share_card_frame.dart';
import '../widgets/opponent/opponent_renderer.dart';
import '../widgets/opponent/opponent_skin_config.dart';
import '../services/platform/platform_services.dart';
import '../services/platform/widget_card_service.dart';
import '../services/platform/live_view_service.dart';
import '../services/platform/rest_reminder_service.dart';
import '../services/platform/implementations/ohos_rest_reminder_service.dart';
import '../services/permission_service.dart';

/// 休息状态机阶段
enum RestPhase { idle, resting, restingOvertime }
/// 休息结束原因
enum RestEndReason { manual, autoTimeout, skip }

class TrainingPage extends StatefulWidget {
  final Map<String, dynamic> params;

  const TrainingPage({
    super.key,
    required this.params,
  });

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage>
    with WidgetsBindingObserver {
  // ── Data ─────────────────────────────────────────────────────
  Map<String, dynamic>? _plan;
  Map<String, dynamic>? _dayConfig;
  List<Map<String, dynamic>> _exercises = [];

  // ── Training state ───────────────────────────────────────────
  int _currentExIdx = 0;
  int _currentSetIdx = 0;
  bool _trainingDone = false;

  /// 动作指导卡片是否展开（默认展开，状态从持久化设置读取）
  bool _actionGuideExpanded = true;

  // ── Rest state machine ──────────────────────────────────────
  RestPhase _restPhase = RestPhase.idle;
  int _restScheduledSeconds = 0;
  DateTime? _restActualStartAt;
  DateTime? _restScheduledEndAt;
  DateTime? _restOvertimeLimitAt;
  RestEndReason? _restEndReason;
  int _restDisplaySeconds = 0;
  int _lastRestActualSeconds = 0;

  /// 兼容字段：UI 读取 _restSeconds 来显示剩余秒数
  int get _restSeconds => _restDisplaySeconds;
  bool get _isResting => _restPhase != RestPhase.idle;

  // ── App lifecycle ────────────────────────────────────────────
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // ── Input ────────────────────────────────────────────────────
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();

  // ── Records ──────────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _setRecords = {};
  final List<Map<String, dynamic>> _restLog = [];

  // ── Timer ────────────────────────────────────────────────────
  Timer? _restTimer;
  late DateTime _startTime;

  // ── PAL stream subscriptions ─────────────────────────────────
  StreamSubscription<RestReminderEvent>? _restReminderSub;
  StreamSubscription<LiveViewEvent>? _liveViewSub;

  // ── Save state ───────────────────────────────────────────────
  /// 防止自动保存重复触发
  bool _isSaved = false;

  /// 详细报告是否已通过广告解锁
  bool _detailedReportUnlocked = false;

  /// v1 V1-11: 训练完成后保存的记录ID，用于跳转写笔记
  String? _savedRecordId;

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    // 读取持久化的动作指导折叠状态（默认展开）
    _actionGuideExpanded = !(Storage.getSettings()['actionGuideCollapsed'] as bool? ?? false);
    _loadData();

    // 检查通知权限，未授予时提示用户
    _checkNotificationPermission();

    // 监听通知点击（通过 PAL 统一处理）
    _restReminderSub = PlatformServices.restReminder.onNotificationClick.listen(_onNotificationClicked);
    // 监听实况窗用户操作（skipRest / resume）
    _liveViewSub = PlatformServices.liveView.onUserAction.listen((event) {
      if (!mounted) return;
      if (event.action == LiveViewAction.skipRest && _isResting) {
        _skipRest();
      }
    });
  }

  /// 检查通知权限，未授予时弹窗引导用户去设置
  Future<void> _checkNotificationPermission() async {
    final granted = await PermissionService.isNotificationGranted();
    if (!granted && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PermissionService.showPermissionDeniedDialog(
          context,
          permissionName: '通知',
          reason: '休息结束提醒需要通知权限才能在后台向您发送提醒，请在设置中开启通知权限。',
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _restReminderSub?.cancel();
    _liveViewSub?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  /// 通知点击回调：回到训练页并处理休息结束
  ///
  /// C2 修复：Android "结束休息"按钮（RestOngoingService.ACTION_SKIP_REST）和 iOS Live Activity
  /// 的 Link 按钮都通过 cardAction="skipRest" 路由到这里。优先处理 skipRest，避免走到下方的
  /// "休息到点"分支（该分支只在 now >= restEndTime 时才动作）。
  void _onNotificationClicked(RestReminderEvent event) {
    if (!mounted) return;
    if (event.cardAction == 'skipRest') {
      _skipRest();
      return;
    }
    // 通知点击回到训练页：如果休息已超时，直接结束
    if (_restPhase == RestPhase.restingOvertime) {
      _endRest(RestEndReason.manual);
    } else if (_restPhase == RestPhase.resting && _restScheduledEndAt != null) {
      final now = DateTime.now();
      if (now.isAfter(_restScheduledEndAt!)) {
        _endRest(RestEndReason.manual);
      }
    }
  }

  /// 真正退出训练页时，将卡片恢复为空闲态。
  /// 只在用户主动离开（返回按钮 / 系统返回 / 保存返回）时调用，
  /// 不放在 dispose() 中，避免 go_router 页面重建时被误重置。
  void _resetWidgetOnExit() {
    PlatformServices.widgetCard.clearCardData();
  }

  /// 顶部返回按钮：先恢复卡片空闲态，再返回上一页。
  void _onBackPressed() {
    _resetWidgetOnExit();
    context.pop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prevState = _appLifecycleState;
    _appLifecycleState = state;

    // 从后台恢复到前台时，修正倒计时
    if (prevState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed &&
        _restPhase != RestPhase.idle &&
        _restScheduledEndAt != null) {
      _onAppResumedFromBackground();
    }

    // App 进入后台时持久化（兜底）
    if (state == AppLifecycleState.paused) {
      _persistInProgressTraining();
    }
  }

  /// 应用从后台恢复时，根据 wall-clock 修正倒计时
  void _onAppResumedFromBackground() {
    final now = DateTime.now();
    if (_restPhase == RestPhase.resting) {
      if (now.isAfter(_restScheduledEndAt!) || now.isAtSameMomentAs(_restScheduledEndAt!)) {
        // 倒计时已结束
        final autoEnd = Storage.getSettings()['autoEndAfterRest'] as bool? ?? false;
        if (autoEnd) {
          _endRest(RestEndReason.autoTimeout,
              actualSecondsOverride: _restScheduledSeconds);
        } else {
          _enterOvertimePhase(skipSound: true);
        }
      } else {
        setState(() {
          _restDisplaySeconds = _restScheduledEndAt!.difference(now).inSeconds;
        });
      }
    } else if (_restPhase == RestPhase.restingOvertime) {
      if (now.isAfter(_restOvertimeLimitAt!)) {
        _endRest(RestEndReason.autoTimeout);
      }
    }
  }

  // ── Data loading ─────────────────────────────────────────────

  void _loadData() {
    final planId = widget.params['planId'] as String?;
    final dayIndex = widget.params['dayIndex'] as int?;

    if (planId != null) {
      _plan = Storage.getPlanById(planId);
    }

    if (_plan != null && dayIndex != null) {
      final days = _plan!['days'] as List<dynamic>?;
      if (days != null && dayIndex >= 0 && dayIndex < days.length) {
        _dayConfig = Map<String, dynamic>.from(days[dayIndex] as Map);
        final exList = _dayConfig!['exercises'] as List<dynamic>? ?? [];
        _exercises = List<Map<String, dynamic>>.from(
          exList.map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
    }

    for (final ex in _exercises) {
      _setRecords[ex['id'] as String] = [];
    }

    // 预填第一个动作的计划值
    _prefillWeightReps();

    setState(() {});

    // 进入训练页后推送训练态到桌面卡片
    _pushTrainingToWidget();
  }

  // ── Computed ─────────────────────────────────────────────────

  int get _totalSets =>
      _exercises.fold(0, (sum, ex) => sum + ((ex['sets'] as int?) ?? 0));

  int get _completedSets =>
      _setRecords.values.fold(0, (sum, list) => sum + list.length);

  double get _overallProgress =>
      _totalSets > 0 ? _completedSets / _totalSets : 0.0;

  /// 获取当前动作的组间休息时间
  /// 优先级：逐组配置 setConfig[currentSet] > 动作 restTime > 计划 defaultRestTime > 设置 defaultRestTime > 90秒
  int _getRestTimeForCurrentExercise() {
    final currentEx = _exercises[_currentExIdx];
    // 0. 逐组配置中当前组的休息时间（最高优先级，确保逐组设置生效）
    final setConfig = currentEx['setConfig'] as List?;
    if (setConfig != null && _currentSetIdx < setConfig.length) {
      final cfg = Map<String, dynamic>.from(setConfig[_currentSetIdx] as Map);
      final perSetRest = (cfg['restTime'] as num?)?.toInt();
      if (perSetRest != null && perSetRest > 0) return perSetRest;
    }
    // 1. 动作自身的休息时间
    final exRest = currentEx['restTime'] as int?;
    if (exRest != null && exRest > 0) return exRest;
    // 2. 计划的默认休息时间
    final planRest = _plan?['defaultRestTime'] as int?;
    if (planRest != null && planRest > 0) return planRest;
    // 3. 设置中的默认休息时间
    final settings = Storage.getSettings();
    final settingsRest = (settings['defaultRestTime'] as num?)?.toInt();
    if (settingsRest != null && settingsRest > 0) return settingsRest;
    // 4. 兜底
    return 90;
  }

  /// 获取当前组的目标次数（用于 UI 显示）
  /// 优先使用逐组配置，否则回退到动作统一参数
  String _targetRepsForCurrentSet() {
    if (_currentExIdx >= _exercises.length) return '';
    final currentEx = _exercises[_currentExIdx];
    final setConfig = currentEx['setConfig'] as List?;
    if (setConfig != null && _currentSetIdx < setConfig.length) {
      final cfg = Map<String, dynamic>.from(setConfig[_currentSetIdx] as Map);
      final perSetReps = cfg['reps']?.toString();
      if (perSetReps != null && perSetReps.isNotEmpty) return perSetReps;
    }
    return currentEx['reps']?.toString() ?? '';
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _completeSet() async {
    if (_currentExIdx >= _exercises.length) return;

    final currentEx = _exercises[_currentExIdx];
    final exId = currentEx['id'] as String;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    _setRecords[exId]!.add({
      'set': _currentSetIdx + 1,
      'weight': weight,
      'reps': reps,
      'rest': _lastRestActualSeconds,  // 上一组结束后的实际休息秒数
    });

    final totalSets = (currentEx['sets'] as int?) ?? 0;
    final isLastSet = _currentSetIdx + 1 >= totalSets;
    final isLastExercise = _currentExIdx + 1 >= _exercises.length;

    if (isLastSet && isLastExercise) {
      // 训练完成：取消所有待发通知（§1 修复）
      RestNotificationService.instance.cancelScheduledNotification();
      // 训练完成：立即触觉反馈（修复 Issue 1a — 震动与完成动作同步）
      try {
        final settings = Storage.getSettings();
        final vibrationEnabled = settings['vibrationEnabled'] as bool? ?? true;
        if (vibrationEnabled) {
          await HapticFeedback.heavyImpact();
        }
      } catch (_) {}

      setState(() {
        _trainingDone = true;
      });
      SoundService.instance.play(SoundType.completeTraining);
      // 自动保存训练记录并触发成就检查/庆祝动画（修复 Issue 1b — 无需用户点击即可保存）
      _autoSaveTraining();
    } else {
      SoundService.instance.play(SoundType.completeSet);
      final restTime = _getRestTimeForCurrentExercise();
      _startRest(restTime, isLastSet);
    }
  }

  void _startRest(int seconds, bool isLastSetOfExercise) {
    SoundService.instance.play(SoundType.restStart);
    final now = DateTime.now();
    _restScheduledSeconds = seconds;
    _restActualStartAt = now;
    _restScheduledEndAt = now.add(Duration(seconds: seconds));
    final multiplier =
        (Storage.getSettings()['restOvertimeLimitMultiplier'] as num?)?.toDouble() ?? 3.0;
    _restOvertimeLimitAt = _restScheduledEndAt!.add(
        Duration(seconds: (seconds * multiplier).round()));
    // 重置上一次休息的结束原因，使 _notifyRestEnd 的"已通知"守卫按周期生效
    _restEndReason = null;

    setState(() {
      _restPhase = RestPhase.resting;
      _restDisplaySeconds = seconds;
    });

    // 推送休息状态到卡片 + 启动实况窗
    if (_currentExIdx < _exercises.length) {
      final currentEx = _exercises[_currentExIdx];
      final exerciseName = currentEx['name'] as String;
      final totalSets = (currentEx['sets'] as int?) ?? 0;

      PlatformServices.widgetCard.pushCardData(WidgetCardData(
        mode: WidgetCardMode.rest,
        exerciseName: exerciseName,
        restTotalSeconds: seconds,
        restEndTime: _restScheduledEndAt,
        currentSet: _currentSetIdx + 1,
        totalSets: totalSets,
        exerciseIndex: _currentExIdx + 1,
        totalExercises: _exercises.length,
        completedSets: _completedSets + 1,
        totalPlanSets: _totalSets,
      ));
      PlatformServices.liveView.startRestLiveView(
        exerciseName: exerciseName,
        restSeconds: seconds,
        restEndTime: _restScheduledEndAt!,
      );
    }

    // 预约定时通知（后台时系统自动触发）
    if (PlatformServices.restReminder is! OhosRestReminderService) {
      final exerciseName = _currentExIdx < _exercises.length
          ? _exercises[_currentExIdx]['name'] as String
          : '';
      RestNotificationService.instance.scheduleRestEndNotification(
        exerciseName: exerciseName,
        delaySeconds: seconds,
      );
    }

    _restartRestTimer();
    _persistInProgressTraining();
  }

  /// 启动/重启休息倒计时（基于 wall-clock 校正）
  void _restartRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restPhase == RestPhase.idle) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      setState(() {
        if (_restPhase == RestPhase.resting) {
          final remaining = _restScheduledEndAt!.difference(now).inSeconds;
          _restDisplaySeconds = remaining > 0 ? remaining : 0;
          if (remaining <= 3 && remaining > 0) {
            SoundService.instance.play(SoundType.tick);
          }
          if (remaining <= 0) {
            // 倒计时结束
            final autoEnd = Storage.getSettings()['autoEndAfterRest'] as bool? ?? false;
            if (autoEnd) {
              _endRest(RestEndReason.autoTimeout,
                  actualSecondsOverride: _restScheduledSeconds);
            } else {
              _enterOvertimePhase();
            }
          }
        } else if (_restPhase == RestPhase.restingOvertime) {
          final overtime = now.difference(_restScheduledEndAt!).inSeconds;
          _restDisplaySeconds = overtime;
          if (now.isAfter(_restOvertimeLimitAt!)) {
            _endRest(RestEndReason.autoTimeout);
          }
        }
      });
    });
  }

  /// 进入超时静默计时阶段
  void _enterOvertimePhase({bool skipSound = false}) {
    setState(() {
      _restPhase = RestPhase.restingOvertime;
      _restDisplaySeconds = 0;
    });
    // 前台时取消预约通知（_notifyRestEnd 已处理），避免重复
    if (_appLifecycleState == AppLifecycleState.resumed) {
      RestNotificationService.instance.cancelScheduledNotification();
    }
    _notifyRestEnd();
    _persistInProgressTraining();
  }

  void _skipRest() {
    _endRest(RestEndReason.skip);
  }

  /// 统一的休息结束收尾
  void _endRest(RestEndReason reason, {int? actualSecondsOverride}) {
    _restTimer?.cancel();

    // §1 修复：前台时取消预约通知，避免重复/延迟触发
    if (_appLifecycleState == AppLifecycleState.resumed) {
      RestNotificationService.instance.cancelScheduledNotification();
    }

    // 计算实际休息秒数
    final actualSeconds = actualSecondsOverride
        ?? (_restActualStartAt != null
            ? DateTime.now().difference(_restActualStartAt!).inSeconds
            : _restScheduledSeconds);

    if (_currentExIdx < _exercises.length) {
      _restLog.add({
        'exercise': _exercises[_currentExIdx]['name'],
        'scheduledRestSeconds': _restScheduledSeconds,
        'actualRestSeconds': actualSeconds,
        'restEndReason': reason.name,
      });
    }

    _lastRestActualSeconds = actualSeconds;

    // 停止休息倒计时前台服务
    PlatformServices.liveView.stopRestLiveView();
    _pushTrainingToWidget(restSkipped: reason == RestEndReason.skip);

    setState(() {
      _restPhase = RestPhase.idle;
      _restActualStartAt = null;
      _restScheduledEndAt = null;
      _restOvertimeLimitAt = null;
      _restEndReason = reason;

      // 推进到下一组/下一动作
      final currentEx = _currentExIdx < _exercises.length ? _exercises[_currentExIdx] : null;
      final totalSets = currentEx != null ? (currentEx['sets'] as int?) ?? 0 : 0;
      if (_currentSetIdx + 1 >= totalSets) {
        // 当前动作最后一组完成，推进到下一个动作
        _currentExIdx++;
        _currentSetIdx = 0;
      } else {
        _currentSetIdx++;
      }
      _prefillWeightReps();
    });

    _persistInProgressTraining();
  }

  /// 休息结束时提醒
  /// - 前台：显示通知（震动仅在训练结束时触发）
  /// - 后台恢复：wall-clock 检测到休息已结束，补发通知
  ///   （OHOS 上由 EntryAbility 的 reminderAgentManager 代理提醒处理）
  Future<void> _notifyRestEnd() async {
    if (_restEndReason != null) return; // 已通知过

    final exerciseName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

    if (_appLifecycleState == AppLifecycleState.resumed) {
      // OHOS 平台：通知由 EntryAbility 原生侧处理，跳过 Flutter 侧 show() 避免重复
      if (PlatformServices.restReminder is! OhosRestReminderService) {
        await RestNotificationService.instance
            .showRestEndNotification(exerciseName: exerciseName);
      }
    }
    // 后台时无法主动触发通知（OHOS 限制），等待用户回到应用时补发
  }

  /// 推送训练状态到桌面卡片
  void _pushTrainingToWidget({bool restSkipped = false}) {
    if (_currentExIdx >= _exercises.length) return;
    final currentEx = _exercises[_currentExIdx];
    PlatformServices.widgetCard.pushCardData(WidgetCardData(
      mode: WidgetCardMode.training,
      exerciseName: currentEx['name'] as String,
      currentSet: _currentSetIdx + 1,
      totalSets: (currentEx['sets'] as int?) ?? 0,
      exerciseIndex: _currentExIdx + 1,
      totalExercises: _exercises.length,
      completedSets: _completedSets,
      totalPlanSets: _totalSets,
    ));
  }

  /// 根据计划数据预填重量和次数
  /// 优先使用逐组配置 setConfig[currentSet]，否则回退到动作统一参数
  void _prefillWeightReps() {
    if (_currentExIdx < _exercises.length) {
      final nextEx = _exercises[_currentExIdx];
      // 优先：逐组配置中当前组的参数
      final setConfig = nextEx['setConfig'] as List?;
      if (setConfig != null && _currentSetIdx < setConfig.length) {
        final cfg = Map<String, dynamic>.from(setConfig[_currentSetIdx] as Map);
        final perSetWeight = (cfg['weight'] as num?)?.toDouble() ?? 0;
        final perSetReps = int.tryParse(cfg['reps']?.toString() ?? '') ?? 0;
        _weightController.text = perSetWeight > 0 ? '$perSetWeight' : '';
        _repsController.text = perSetReps > 0 ? '$perSetReps' : '';
        return;
      }
      // 回退：动作统一参数
      final planWeight = (nextEx['weight'] as num?)?.toDouble() ?? 0;
      final planReps = int.tryParse(nextEx['reps']?.toString() ?? '') ?? 0;
      _weightController.text = planWeight > 0 ? '$planWeight' : '';
      _repsController.text = planReps > 0 ? '$planReps' : '';
    } else {
      _weightController.clear();
      _repsController.clear();
    }
  }

  /// 持久化进行中训练到 Storage
  Future<void> _persistInProgressTraining() async {
    if (_trainingDone || _exercises.isEmpty) return;
    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      final data = <String, dynamic>{
        'version': 1,
        'startedAt': _startTime.millisecondsSinceEpoch,
        'startedAtDate': today,
        'planId': _plan?['id'],
        'planName': _plan?['name'],
        'dayConfig': _dayConfig,
        'exercises': _exercises,
        'currentExIdx': _currentExIdx,
        'currentSetIdx': _currentSetIdx,
        'setRecords': _setRecords.map((k, v) => MapEntry(k, v)),
        'restLog': _restLog,
        'restPhaseSnapshot': _restPhase != RestPhase.idle ? {
          'phase': _restPhase.name,
          'scheduledSeconds': _restScheduledSeconds,
          'actualStartAt': _restActualStartAt?.millisecondsSinceEpoch,
          'scheduledEndAt': _restScheduledEndAt?.millisecondsSinceEpoch,
          'overtimeLimitAt': _restOvertimeLimitAt?.millisecondsSinceEpoch,
        } : null,
      };
      await Storage.saveInProgressTraining(data);
    } catch (e) {
      debugPrint('_persistInProgressTraining error: $e');
    }
  }

  /// 训练完成后自动保存记录、检查成就、显示庆祝动画。
  /// 不导航离开，用户仍可查看完成页面、分享成果。
  Future<void> _autoSaveTraining() async {
    if (_isSaved) return; // 防止重复保存
    _isSaved = true;

    // §1 修复：训练完成时兜底取消所有待发通知
    RestNotificationService.instance.cancelScheduledNotification();

    // 清理进行中训练持久化
    Storage.clearInProgressTraining();

    final totalDurationSec = DateTime.now().difference(_startTime).inSeconds;
    final restTotalSec = _restLog.fold<int>(0, (sum, r) =>
        sum + ((r['actualRestSeconds'] as num?) ?? 0).toInt());
    final pureDurationSec = totalDurationSec - restTotalSec;
    final duration = (totalDurationSec / 60).round();

    int totalWeight = 0;
    final muscles = <String>{};

    for (final ex in _exercises) {
      final records = _setRecords[ex['id']] ?? [];
      for (final r in records) {
        totalWeight +=
            ((r['weight'] as num?) ?? 0).toInt() * ((r['reps'] as num?) ?? 0).toInt();
      }
      final muscle =
          ex['category'] as String? ?? _dayConfig?['muscle'] as String? ?? '';
      if (muscle.isNotEmpty) muscles.add(muscle);
    }

    final savedRecord = Storage.addRecord({
      'name': _dayConfig?['label'] ?? '训练',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
      'pureDuration': pureDurationSec,
      'totalWeight': totalWeight,
      'totalSets': _completedSets,
      'exerciseCount': _exercises.length,
      'muscles': muscles.toList(),
      'setRecords': _setRecords.map((k, v) => MapEntry(k, v)),
      'restLog': _restLog,
      // 修复 Issue 1d：写入 planId/planName 以解锁计划完成成就 + 记录页正确显示
      'planId': _plan?['id'],
      'planName': _plan?['name'],
    });
    // v1 V1-11: 保存记录ID，用于训练完成页"写笔记"入口
    _savedRecordId = savedRecord['id'] as String?;

    // 循环训练日：训练完成后，将计划的 currentDayIndex 推进到下一个训练日（跳过休息日）
    if (_plan != null) {
      final planId = _plan!['id'] as String?;
      final days = _plan!['days'] as List?;
      if (planId != null && days != null && days.isNotEmpty) {
        final currentDayIndex = (_plan!['currentDayIndex'] as num?)?.toInt() ?? 0;
        // 循环递增到下一个训练日（跳过 isRest 的休息日）
        int nextDayIndex = (currentDayIndex + 1) % days.length;
        int attempts = 0;
        while (attempts < days.length) {
          final dayData = days[nextDayIndex] as Map<String, dynamic>?;
          if (dayData == null || dayData['isRest'] != true) break;
          nextDayIndex = (nextDayIndex + 1) % days.length;
          attempts++;
        }
        await Storage.updatePlanAsync(planId, {'currentDayIndex': nextDayIndex});
        // 更新本地缓存，避免下次进入训练页读到旧值
        _plan!['currentDayIndex'] = nextDayIndex;
      }
    }

    // B4: 成就检查（训练完成后自动计算并弹出 — 修复 Issue 1d）
    int earnedPoints = 0;
    if (mounted) {
      final records = Storage.getRecords();
      final currentRecord = records.isNotEmpty ? records.first : <String, dynamic>{};
      final unlockedAchievements =
          await AchievementService.instance.checkAndUnlock(currentRecord);
      // 每日训练得积分（同日防重复）：成就检查之后调用，避免与成就解锁积分交错
      earnedPoints = await PointsService.instance.addDailyTrainingPoints();
      if (unlockedAchievements.isNotEmpty && mounted) {
        for (final id in unlockedAchievements) {
          final all = AchievementService.instance.getAll();
          final ach = all.where((a) => a.id == id).first;
          await InfoDialog.show(
            context,
            title: '解锁新成就',
            content: '${ach.title}\n${ach.description}',
            actionText: '好的',
            icon: Icons.emoji_events,
            iconColor: Theme.of(context).colorScheme.primary,
          );
        }
      }
    }

    // B2: 训练完成庆祝动画
    if (mounted) {
      final records = Storage.getRecords();
      if (records.isNotEmpty) {
        final current = records.first;
        final previous = records.length > 1 ? records[1] : null;
        await CelebrationOverlay.show(context,
            record: current, previousRecord: previous);
      }
    }

    // v1 训练笔记情感化：弹出祝贺框
    if (mounted) {
      await CelebrationDialog.show(
        context,
        totalWeight: totalWeight,
        totalSets: _completedSets,
        duration: duration,
        recordId: _savedRecordId ?? '',
        earnedPoints: earnedPoints,
      );
    }
  }

  /// 返回首页：更新桌面卡片、评分引导、导航离开。
  /// 训练记录已在 _autoSaveTraining() 中自动保存。
  Future<void> _returnHome() async {
    // 更新桌面卡片数据
    PlatformServices.widgetCard.clearCardData();
    PlatformServices.liveView.stopRestLiveView();

    // B3: 训练完成回调，重置今日推送规避
    SmartPushService.instance.onTrainingCompleted();
    // v1 V1-04: 记录首次训练日（用于7天留存链触发）
    RetentionChainService.instance.recordFirstTrainingIfNeeded();

    // D2: 评分引导（第 2 次训练后弹窗 + 30 天上限）
    if (mounted) {
      await RatingPromptSheet.maybeShow(context);
    }

    // 返回上一页
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _shareTrainingCard(int totalWeight, int duration) async {
    final record = <String, dynamic>{
      'name': _dayConfig?['label'] ?? '训练',
      'totalWeight': totalWeight,
      'totalSets': _completedSets,
      'duration': duration * 60, // minutes → seconds for ShareCardFrame
      'date': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      await PosterCaptureHelper.captureAndPreview(
        context,
        posterWidget: ShareCardFrame(record: record),
        posterWidth: ShareCardFrame.posterWidth,
        title: '训练记录海报',
        fileNamePrefix: 'fittrack_training',
      );
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '生成分享卡片失败：$e');
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 用 WillPopScope 兜底系统返回键：退出训练页时把卡片恢复为空闲态。
    // 返回 true 放行默认的 pop 行为。
    return WillPopScope(
      onWillPop: () async {
        _resetWidgetOnExit();
        return true;
      },
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_exercises.isEmpty) {
      return _buildEmptyState();
    }
    if (_trainingDone) {
      return _buildCompletionScreen();
    }
    return Stack(
      children: [
        _buildTrainingContent(),
        if (_isResting) _buildRestOverlay(),
      ],
    );
  }

  // ── Empty state ──────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            onBack: _onBackPressed,
            title: '训练',
          ),
          const Expanded(
            child: EmptyState(
              icon: Icons.fitness_center_outlined,
              message: '没有找到训练动作',
            ),
          ),
        ],
      ),
    );
  }

  // ── Training content ─────────────────────────────────────────

  Widget _buildTrainingContent() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final currentEx = _exercises[_currentExIdx];
    final totalSets = (currentEx['sets'] as int?) ?? 0;
    final records = _setRecords[currentEx['id']] ?? [];

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            onBack: _onBackPressed,
            title: _dayConfig?['label'] ?? '训练',
            subtitle: '第${_currentExIdx + 1}/${_exercises.length}个动作',
          ),
          // Overall progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '整体进度',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '$_completedSets/$_totalSets 组',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBar(progress: _overallProgress),
              ],
            ),
          ),
          // Exercise list sidebar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _exercises.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final ex = _exercises[index];
                final isCurrent = index == _currentExIdx;
                final exRecords = _setRecords[ex['id']] ?? [];
                final exTotalSets = (ex['sets'] as int?) ?? 0;
                final isDone = exRecords.length >= exTotalSets && exTotalSets > 0;

                Color bgColor;
                Color borderColor;
                Color textColor;

                if (isCurrent) {
                  bgColor = colors.accentGlow.withOpacity(0.15);
                  borderColor = colors.accentGlow;
                  textColor = colors.accentGlow;
                } else if (isDone) {
                  bgColor = colors.successColor.withOpacity(0.1);
                  borderColor = colors.successColor;
                  textColor = colors.successColor;
                } else {
                  bgColor = colors.bgCard;
                  borderColor = colors.borderColor;
                  textColor = colors.textMuted;
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDone) ...[
                          Icon(Icons.check_circle,
                              size: 14, color: colors.successColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          ex['name'] as String,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Current exercise card (动作指导卡片置于下方滚动区域)
          Expanded(
            key: const ValueKey('training_card'),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CardWidget(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentEx['name'] as String,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '第 ${_currentSetIdx + 1}/$totalSets 组',
                          style: TextStyle(
                            color: colors.accentGlow,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '目标: ${_targetRepsForCurrentSet()}次',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '休息: ${_getRestTimeForCurrentExercise()}秒',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Previous set records
                    if (records.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '已完成组',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: records.map((r) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '第${r['set']}组 ${r['weight']}kg×${r['reps']}',
                              style: TextStyle(
                                color: colors.successColor,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Weight & reps input
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '重量 (kg)',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: '输入重量',
                                  hintStyle: TextStyle(color: colors.textMuted),
                                  filled: true,
                                  fillColor: colors.bgSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.accentGlow),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '次数',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _repsController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  hintText: '输入次数',
                                  hintStyle: TextStyle(color: colors.textMuted),
                                  filled: true,
                                  fillColor: colors.bgSecondary,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: colors.accentGlow),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Complete button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeSet,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          '完成第${_currentSetIdx + 1}组',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                    // 动作指导卡片（置于训练卡片下方）
                    if (_exercises.isNotEmpty && _currentExIdx < _exercises.length) ...[
                      const SizedBox(height: 12),
                      _buildActionGuide(colors),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Action guide card ────────────────────────────────────────

  /// 切换动作指导卡片展开/收起状态，并持久化
  void _toggleActionGuide() {
    setState(() => _actionGuideExpanded = !_actionGuideExpanded);
    final settings = Storage.getSettings();
    settings['actionGuideCollapsed'] = !_actionGuideExpanded;
    Storage.saveSettings(settings);
  }

  Widget _buildActionGuide(LiftTrackColors colors) {
    if (_exercises.isEmpty || _currentExIdx >= _exercises.length) {
      return const SizedBox.shrink();
    }
    final ex = _exercises[_currentExIdx];
    final exId = ex['id'] as String?;

    // 数据读取：优先动作自带字段，回退 MockData
    String desc = (ex['description'] as String?)?.isNotEmpty == true
        ? ex['description'] as String
        : (exId != null ? (MockData.exerciseDescriptions[exId] ?? '') : '');
    List<String> muscles = (ex['muscles'] as List?)?.isNotEmpty == true
        ? List<String>.from(ex['muscles'] as List)
        : (exId != null ? (MockData.exerciseMuscles[exId] ?? <String>[]) : <String>[]);
    List<Map<String, dynamic>> steps = (ex['steps'] as List?)?.isNotEmpty == true
        ? List<Map<String, dynamic>>.from(ex['steps'] as List)
        : (exId != null ? (MockData.exerciseSteps[exId] ?? <Map<String, dynamic>>[]) : <Map<String, dynamic>>[]);

    // ID 匹配失败时，通过动作名称回退查找 MockData
    // 系统计划 JSON 使用 ex_str_xxx 等 ID，与 MockData 的 e1-e21 不一致
    if (desc.isEmpty && muscles.isEmpty && steps.isEmpty) {
      final exName = ex['name'] as String? ?? '';
      if (exName.isNotEmpty) {
        // 1. 精确名称匹配
        // 2. 模糊匹配：计划动作名包含 MockData 动作名，或反之（如"深蹲"匹配"杠铃深蹲"）
        String? matchedId;
        for (final me in MockData.exercises) {
          final meName = me['name'] as String;
          if (meName == exName) {
            matchedId = me['id'] as String;
            break;
          }
        }
        // 精确匹配失败，尝试模糊匹配
        if (matchedId == null) {
          for (final me in MockData.exercises) {
            final meName = me['name'] as String;
            if (meName.contains(exName) || exName.contains(meName)) {
              matchedId = me['id'] as String;
              break;
            }
          }
        }

        if (matchedId != null) {
          desc = MockData.exerciseDescriptions[matchedId] ?? '';
          muscles = MockData.exerciseMuscles[matchedId] ?? <String>[];
          steps = MockData.exerciseSteps[matchedId] ?? <Map<String, dynamic>>[];
        }
      }
    }

    final exName = ex['name'] as String? ?? '当前动作';
    final hasContent = desc.isNotEmpty || muscles.isNotEmpty || steps.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: CardWidget(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题行（点击展开/收起）
            InkWell(
              onTap: _toggleActionGuide,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: colors.accentGlow),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '动作指导 · $exName',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _actionGuideExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 展开内容（带动画）
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _actionGuideExpanded
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DividerWidget(indent: 14),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                          child: hasContent
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (desc.isNotEmpty) ...[
                                    Text('动作说明', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                                    const SizedBox(height: 4),
                                    Text(desc, style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.5)),
                                    const SizedBox(height: 10),
                                  ],
                                  if (muscles.isNotEmpty) ...[
                                    Text('目标肌群', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: muscles.map((m) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.accentGlow.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(m, style: TextStyle(fontSize: 11, color: colors.accentGlow)),
                                      )).toList(),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  if (steps.isNotEmpty) ...[
                                    Text('训练步骤', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.accentGlow)),
                                    const SizedBox(height: 6),
                                    ...steps.asMap().entries.map((e) {
                                      final i = e.key;
                                      final s = e.value;
                                      final kp = (s['keyPoses'] as List?) ?? [];
                                      final stepImg = s['image'] as String?;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${i + 1}. ${s['title'] ?? ''}',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                            if (stepImg != null) ...[
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.asset(
                                                  stepImg,
                                                  width: double.infinity,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    width: double.infinity,
                                                    height: 80,
                                                    color: colors.bgSecondary,
                                                    child: Icon(Icons.fitness_center, size: 28, color: colors.textMuted.withOpacity(0.3)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                            ],
                                            if ((s['desc'] as String?)?.isNotEmpty == true)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2, left: 12),
                                                child: Text(s['desc'],
                                                    style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.4)),
                                              ),
                                            if (kp.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              ...kp.map((k) => Padding(
                                                padding: const EdgeInsets.only(left: 24, bottom: 2),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('· ', style: TextStyle(fontSize: 12, color: colors.accentGlow)),
                                                    Expanded(child: Text(k.toString(),
                                                        style: TextStyle(fontSize: 11, color: colors.textSecondary))),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Text('暂无动作指导', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                ),
                              ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rest overlay ─────────────────────────────────────────────

  Widget _buildRestOverlay() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final isOvertime = _restPhase == RestPhase.restingOvertime;
    // resting 阶段：剩余秒数 / 计划秒数；overtime 阶段：进度已满
    final progress = isOvertime
        ? 1.0
        : (_restScheduledSeconds > 0
            ? _restSeconds / _restScheduledSeconds
            : 0.0);
    final currentExName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';
    // overtime 阶段显示 "+Ns" 形式，resting 阶段显示剩余秒数
    final secondsText = isOvertime ? '+$_restSeconds' : '$_restSeconds';
    final statusText = isOvertime ? '已超时' : '休息中';
    final buttonText = isOvertime ? '结束休息' : '跳过休息';
    // overtime 阶段用警告色高亮按钮
    final buttonColor = isOvertime ? colors.warningColor : colors.accentGlow;

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentExName,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  secondsText,
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '秒',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: ProgressBar(
                    progress: progress,
                    height: 8,
                    fillColor: buttonColor,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.coffee,
                          size: 16, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isOvertime
                              ? '休息时间已超，按需结束休息开始下一组。'
                              : '你可以离开 App 去喝口水、活动一下，休息结束时我们会发送通知提醒你开始下一组。',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: isOvertime
                      ? () => _endRest(RestEndReason.manual)
                      : _skipRest,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: buttonColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: buttonColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Completion screen ────────────────────────────────────────

  Widget _buildCompletionScreen() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final duration = DateTime.now().difference(_startTime).inMinutes;

    int totalWeight = 0;
    for (final ex in _exercises) {
      final records = _setRecords[ex['id']] ?? [];
      for (final r in records) {
        totalWeight += ((r['weight'] as num?) ?? 0).toInt() *
            ((r['reps'] as num?) ?? 0).toInt();
      }
    }

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            onBack: _onBackPressed,
            title: '训练完成',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Check icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.successColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 48,
                      color: colors.successColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '训练完成',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        icon: Icons.timer_outlined,
                        value: '$duration分钟',
                        label: '训练时长',
                        color: colors.accentGlow,
                      ),
                      StatCard(
                        icon: Icons.fitness_center,
                        value: '$_completedSets',
                        label: '总组数',
                        color: colors.infoColor,
                      ),
                      StatCard(
                        icon: Icons.monitor_weight_outlined,
                        value: '${totalWeight}kg',
                        label: '总重量',
                        color: colors.warningColor,
                      ),
                      StatCard(
                        icon: Icons.sports_gymnastics,
                        value: '${_exercises.length}',
                        label: '动作数',
                        color: colors.purpleColor,
                      ),
                    ],
                  ),
                  // v1 虚拟对手 PK 对比
                  const SizedBox(height: 20),
                  _buildOpponentPKCard(colors),
                  // Rest log
                  if (_restLog.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const SectionHeader(title: '休息记录'),
                    const SizedBox(height: 8),
                    ..._restLog.map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: colors.bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  log['exercise'] as String,
                                  style: TextStyle(
                                      color: colors.textPrimary, fontSize: 14),
                                ),
                                Text(
                                  '休息${log['actualRestSeconds']}秒',
                                  style: TextStyle(
                                      color: colors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 24),
                  // 返回首页按钮（训练记录已自动保存）
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _returnHome,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '返回首页',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('分享训练成果'),
                      onPressed: () => _shareTrainingCard(totalWeight, duration),
                    ),
                  ),
                  // v1 V1-11: 写训练笔记入口
                  if (_savedRecordId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('写训练笔记'),
                        onPressed: () =>
                            context.push('/note/edit/record_$_savedRecordId'),
                      ),
                    ),
                  ],
                  if (AdService.instance.shouldShowRewarded())
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () async {
                            final result =
                                await AdService.instance.showRewardedVideo();
                            if (!mounted) return;
                            // Phase 2：未集成真实广告 SDK，AdService 始终返回 notAvailable。
                            // 此处对 notAvailable 直接解锁详细报告，避免用户点击无反馈。
                            if (result == AdResult.success ||
                                result == AdResult.notAvailable) {
                              setState(() => _detailedReportUnlocked = true);
                              FitToast.success(context, '已解锁详细数据报告');
                            } else if (result == AdResult.userDismissed) {
                              FitToast.info(context, '广告未观看完成');
                            } else {
                              FitToast.error(context, '广告加载失败，请稍后重试');
                            }
                          },
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('看广告解锁详细报告'),
                        ),
                      ),
                    ),
                  if (_detailedReportUnlocked) ...[
                    const SizedBox(height: 16),
                    const SectionHeader(title: '详细数据报告'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('平均每组重量',
                              _completedSets > 0
                                  ? '${(totalWeight / _completedSets).toStringAsFixed(1)} kg'
                                  : '0 kg',
                              colors),
                          const SizedBox(height: 8),
                          _detailRow('训练密度',
                              '${(_completedSets / (duration > 0 ? duration : 1)).toStringAsFixed(2)} 组/分',
                              colors),
                          const SizedBox(height: 8),
                          _detailRow('完成动作数',
                              '${_exercises.length} 个', colors),
                          const SizedBox(height: 8),
                          _detailRow('平均休息时长',
                              _restLog.isEmpty
                                  ? '0 秒'
                                  : '${(_restLog.fold<int>(0, (sum, l) => sum + (l['actualRestSeconds'] as num).toInt()) / _restLog.length).round()} 秒',
                              colors),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 详细报告行
  Widget _detailRow(String label, String value, LiftTrackColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: colors.textSecondary, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// v1 虚拟对手 PK 对比卡片 —— 训练完成后展示本周 PK 结果
  Widget _buildOpponentPKCard(LiftTrackColors colors) {
    final settings = Storage.getSettings();
    final opponentJson = settings['virtualOpponentData'] as Map<String, dynamic>?;
    if (opponentJson == null) return const SizedBox.shrink();

    final opponent = VirtualOpponent.fromJson(Map<String, dynamic>.from(opponentJson));
    final records = Storage.getRecords();

    // 计算用户本周训练次数
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMs = DateTime(weekStart.year, weekStart.month, weekStart.day).millisecondsSinceEpoch;
    int userWeeklyTrainings = 0;
    for (final r in records) {
      final ts = r['date'] as int? ?? r['createTime'] as int?;
      if (ts != null && ts >= weekStartMs) userWeeklyTrainings++;
    }

    // 计算 PK 结果
    final outcome = VirtualOpponentEngine.instance.computeOutcome(
      userWeeklyTrainings,
      opponent,
    );
    final userWon = outcome.userScore > outcome.opponentScore;
    final percentile = VirtualOpponentEngine.instance.computePercentile(
      userWeeklyTrainings,
      opponent.tier,
    );

    // 皮肤主题（appliedSkinId 为空时 fallback 到无皮肤样式）
    final skinId = opponent.appliedSkinId;
    final hasSkin = skinId.isNotEmpty;
    final skin = hasSkin ? OpponentSkinConfig.byId(skinId) : null;
    final cardTheme = skin?.cardTheme;
    // 卡片边框：优先用皮肤 borderColor，否则维持胜负色
    final cardBorderColor = cardTheme?.borderColor ??
        (userWon ? colors.successColor.withOpacity(0.4) : colors.borderColor);
    // 招式名高亮色
    final signatureColor = cardTheme?.glowColor ?? colors.accentGlow;

    return InkWell(
      onTap: () => context.push('/opponent-detail'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cardBorderColor,
            width: cardTheme != null ? 1.5 : 1,
          ),
          boxShadow: cardTheme != null
              ? [
                  BoxShadow(
                    color: cardTheme.glowColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 18, color: colors.accentGlow),
                const SizedBox(width: 6),
                Text(
                  '本周PK · vs ${opponent.nickname}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (cardTheme != null)
                  // 皮肤角标 emoji
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      cardTheme.badgeEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (userWon ? colors.successColor : colors.warningColor).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    userWon ? '领先' : '追赶中',
                    style: TextStyle(
                      color: userWon ? colors.successColor : colors.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 对手人物图 + 招式
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: OpponentRenderer(
                    skinId: opponent.appliedSkinId,
                    size: const Size(64, 64),
                    autoTrain: false,
                    showAura: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '招式：${hasSkin ? skin!.signatureMove : '默认招式'}',
                    style: TextStyle(
                      color: signatureColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 双方进度条对比
            _buildPKBar(colors, '我', userWeeklyTrainings, outcome.userScore, colors.accentGlow),
            const SizedBox(height: 8),
            _buildPKBar(colors, opponent.nickname, opponent.weeklyTrainings, outcome.opponentScore, cardTheme?.glowColor ?? colors.textMuted),
            const SizedBox(height: 12),
            // 超越百分比
            Row(
              children: [
                Text(
                  '超越同水平 $percentile% 用户',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                if (opponent.currentStatus != null)
                  Text(
                    '${opponent.nickname}：${opponent.currentStatus}',
                    style: TextStyle(color: colors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPKBar(LiftTrackColors colors, String label, int trainings, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.15),
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text('$trainings次', style: TextStyle(color: colors.textSecondary, fontSize: 11), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
