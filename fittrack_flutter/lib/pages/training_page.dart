import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/rest_notification_service.dart';
import '../services/smart_push_service.dart';
import '../services/ohos_reminder_service.dart';
import '../services/android_alarm_service.dart';
import '../services/form_kit_service.dart';
import '../services/share_card_service.dart';
import '../services/achievement_service.dart';
import '../services/ad_service.dart';
import '../services/retention_chain_service.dart';
import '../data/virtual_opponent.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/celebration_dialog.dart';
import '../widgets/poster_preview_dialog.dart';
import '../widgets/rating_prompt_sheet.dart';
import '../utils/platform_utils.dart';

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
  bool _isResting = false;
  int _restSeconds = 0;
  int _totalRestSeconds = 0;
  bool _isLastSetOfExercise = false;

  // ── Wall-clock rest timer ────────────────────────────────────
  /// 休息结束的绝对时间点，用于后台恢复时计算剩余时间
  DateTime? _restEndTime;
  /// 是否已经触发过本次休息结束的提醒（防止重复触发）
  bool _restEndNotified = false;

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
    _loadData();

    // 监听 OHOS 通知点击
    if (isOhos) {
      OhosReminderService.instance.onNotificationClick = _onNotificationClicked;
      // 注册训练卡片交互回调：卡片点击时原地处理，避免跳转首页销毁本页
      OhosReminderService.instance.onTrainingCardAction = _onTrainingCardAction;
    } else {
      // 监听 Android 通知点击
      AndroidAlarmService.instance.onCardClick = _onAndroidAlarmCardClick;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    // 清理通知点击回调
    if (isOhos) {
      OhosReminderService.instance.onNotificationClick = null;
      OhosReminderService.instance.onTrainingCardAction = null;
    } else {
      AndroidAlarmService.instance.onCardClick = null;
    }
    super.dispose();
  }

  /// Android 通知卡片点击回调：回到训练页并处理休息结束
  void _onAndroidAlarmCardClick(Map<String, dynamic> args) {
    if (!mounted) return;
    final targetPage = args['targetPage'] as String?;
    final cardAction = args['cardAction'] as String?;

    if (targetPage == 'training' && cardAction == 'resume') {
      _onNotificationClicked(args);
    } else if (cardAction == 'skipRest' && _isResting) {
      _skipRest();
    }
  }

  /// 真正退出训练页时，将卡片恢复为空闲态。
  /// 只在用户主动离开（返回按钮 / 系统返回 / 保存返回）时调用，
  /// 不放在 dispose() 中，避免 go_router 页面重建时被误重置。
  void _resetWidgetOnExit() {
    if (isOhos) {
      FormKitService.instance.endTraining();
    }
  }

  /// 顶部返回按钮：先恢复卡片空闲态，再返回上一页。
  void _onBackPressed() {
    _resetWidgetOnExit();
    context.pop();
  }

  /// OHOS 训练卡片点击回调：
  /// - 休息中点击“结束休息”按钮(skipRest)：原地跳过休息，不跳转
  /// - 训练中点击“回到应用”(resume)：无需额外处理，应用已被拉到前台
  void _onTrainingCardAction(Map<String, dynamic> args) {
    if (!mounted) return;
    final cardAction = args['cardAction'] as String?;
    if (cardAction == 'skipRest' && _isResting) {
      _skipRest();
    }
  }

  /// OHOS 通知点击回调：回到训练页并处理休息结束
  void _onNotificationClicked(Map<String, dynamic> args) {
    if (!mounted) return;
    if (_isResting && _restEndTime != null) {
      final now = DateTime.now();
      if (now.isAfter(_restEndTime!) || now.isAtSameMomentAs(_restEndTime!)) {
        _restSeconds = 0;
        // OHOS 平台：代理提醒由 EntryAbility 自动管理，无需 Flutter 侧取消
        if (!isOhos) {
          RestNotificationService.instance.cancelScheduledNotification();
        }
        _notifyRestEnd();
        _advanceAfterRest();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prevState = _appLifecycleState;
    _appLifecycleState = state;

    // 从后台恢复到前台时，修正倒计时
    if (prevState == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed &&
        _isResting &&
        _restEndTime != null) {
      _onAppResumedFromBackground();
    }
  }

  /// 应用从后台恢复时，根据 wall-clock 修正倒计时
  void _onAppResumedFromBackground() {
    final now = DateTime.now();
    if (now.isAfter(_restEndTime!) || now.isAtSameMomentAs(_restEndTime!)) {
      // 休息时间已在后台结束
      _restSeconds = 0;
      // 取消预约通知（可能已发送，清理）
      // OHOS 平台：代理提醒由 EntryAbility 自动管理，无需 Flutter 侧取消
      if (!isOhos) {
        RestNotificationService.instance.cancelScheduledNotification();
      }
      // 后台可能没有收到 zonedSchedule 通知，恢复前台时补发通知+振动
      _notifyRestEnd();
      // 推进到下一组
      _advanceAfterRest();
    } else {
      // 休息时间未结束，重新计算剩余秒数并重启计时器
      final remaining = _restEndTime!.difference(now).inSeconds;
      setState(() {
        _restSeconds = remaining;
      });
      _restartRestTimer();
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
  /// 优先级：动作 restTime > 计划 defaultRestTime > 设置 defaultRestTime > 90秒
  int _getRestTimeForCurrentExercise() {
    final currentEx = _exercises[_currentExIdx];
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
    });

    final totalSets = (currentEx['sets'] as int?) ?? 0;
    final isLastSet = _currentSetIdx + 1 >= totalSets;
    final isLastExercise = _currentExIdx + 1 >= _exercises.length;

    if (isLastSet && isLastExercise) {
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
      // 自动保存训练记录并触发成就检查/庆祝动画（修复 Issue 1b — 无需用户点击即可保存）
      _autoSaveTraining();
    } else {
      final restTime = _getRestTimeForCurrentExercise();
      _startRest(restTime, isLastSet);
    }
  }

  void _startRest(int seconds, bool isLastSetOfExercise) {
    _restEndTime = DateTime.now().add(Duration(seconds: seconds));
    _restEndNotified = false;

    setState(() {
      _isResting = true;
      _restSeconds = seconds;
      _totalRestSeconds = seconds;
      _isLastSetOfExercise = isLastSetOfExercise;
    });

    // 推送休息状态到卡片（含 restEndTime 绝对时间戳，卡片侧本地倒计时据此运行）
    if (isOhos && _currentExIdx < _exercises.length) {
      final currentEx = _exercises[_currentExIdx];
      FormKitService.instance.startRest(
        exerciseName: currentEx['name'] as String,
        restSeconds: seconds,
        restEndTime: _restEndTime!.millisecondsSinceEpoch,
        totalRestSeconds: seconds,
        currentSet: _currentSetIdx + 1,
        totalSets: (currentEx['sets'] as int?) ?? 0,
        exerciseIndex: _currentExIdx + 1,
        totalExercises: _exercises.length,
        completedSets: _completedSets + 1,
        totalPlanSets: _totalSets,
      );
    }

    // 预约定时通知（后台时系统自动触发）
    // OHOS 平台：EntryAbility 接收到 mode=rest 数据后自动发布 reminderAgentManager 代理提醒，
    // 无需 Flutter 侧再通过 flutter_local_notifications 预约，避免 MissingPluginException
    if (!isOhos) {
      final exerciseName = _currentExIdx < _exercises.length
          ? _exercises[_currentExIdx]['name'] as String
          : '';
      RestNotificationService.instance.scheduleRestEndNotification(
        exerciseName: exerciseName,
        delaySeconds: seconds,
      );
    }

    _restartRestTimer();
  }

  /// 启动/重启休息倒计时（基于 wall-clock 校正后的 _restSeconds）
  void _restartRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isResting || _restEndTime == null) {
        timer.cancel();
        return;
      }

      // 使用 wall-clock 计算剩余时间，确保准确
      final now = DateTime.now();
      final remaining = _restEndTime!.difference(now).inSeconds;

      setState(() {
        _restSeconds = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0) {
        timer.cancel();
        // 不取消预约通知！让系统通知自然触发（后台时需要）
        // 前台时也显示通知 + 振动
        _notifyRestEnd();
        _advanceAfterRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    // 跳过休息时才取消预约通知
    // OHOS 平台：通过 restSkipped 标记告知 EntryAbility 取消尚未触发的代理提醒
    if (!isOhos) {
      RestNotificationService.instance.cancelScheduledNotification();
    }
    _advanceAfterRest(restSkipped: true);
  }

  /// 休息结束时提醒
  /// - 前台：显示通知（震动仅在训练结束时触发）
  /// - 后台恢复：wall-clock 检测到休息已结束，补发通知
  ///   （OHOS 上由 EntryAbility 的 reminderAgentManager 代理提醒处理）
  Future<void> _notifyRestEnd() async {
    if (_restEndNotified) return;
    _restEndNotified = true;

    final exerciseName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

    if (_appLifecycleState == AppLifecycleState.resumed) {
      // 前台或从后台恢复：显示通知（震动仅在训练结束时触发）
      // OHOS 平台：通知由 EntryAbility 的 notificationManager 处理
      if (!isOhos) {
        await RestNotificationService.instance
            .showRestEndNotification(exerciseName: exerciseName);
      }
    }
    // 后台时无法主动触发通知（OHOS 限制），等待用户回到应用时补发
  }

  void _advanceAfterRest({bool restSkipped = false}) {
    _restLog.add({
      'exercise': _exercises[_currentExIdx]['name'],
      'restTime': _totalRestSeconds,
      'actualTime': _totalRestSeconds - _restSeconds,
    });

    setState(() {
      _isResting = false;
      _restEndTime = null;
      _restEndNotified = false;
      if (_isLastSetOfExercise) {
        _currentExIdx++;
        _currentSetIdx = 0;
      } else {
        _currentSetIdx++;
      }
      // 预填下一个动作/组的计划值
      _prefillWeightReps();
    });
    // 推送训练状态到卡片（restSkipped 标记区分跳过 vs 自然结束）
    _pushTrainingToWidget(restSkipped: restSkipped);
  }

  /// 推送训练状态到桌面卡片
  void _pushTrainingToWidget({bool restSkipped = false}) {
    if (!isOhos) return;
    if (_currentExIdx >= _exercises.length) return;
    final currentEx = _exercises[_currentExIdx];
    FormKitService.instance.updateTrainingState(
      exerciseName: currentEx['name'] as String,
      currentSet: _currentSetIdx + 1,
      totalSets: (currentEx['sets'] as int?) ?? 0,
      exerciseIndex: _currentExIdx + 1,
      totalExercises: _exercises.length,
      completedSets: _completedSets,
      totalPlanSets: _totalSets,
      restSkipped: restSkipped,
    );
  }

  /// 根据计划数据预填重量和次数
  void _prefillWeightReps() {
    if (_currentExIdx < _exercises.length) {
      final nextEx = _exercises[_currentExIdx];
      final planWeight = (nextEx['weight'] as num?)?.toDouble() ?? 0;
      final planReps = int.tryParse(nextEx['reps']?.toString() ?? '') ?? 0;
      _weightController.text = planWeight > 0 ? '$planWeight' : '';
      _repsController.text = planReps > 0 ? '$planReps' : '';
    } else {
      _weightController.clear();
      _repsController.clear();
    }
  }

  /// 训练完成后自动保存记录、检查成就、显示庆祝动画。
  /// 不导航离开，用户仍可查看完成页面、分享成果。
  Future<void> _autoSaveTraining() async {
    if (_isSaved) return; // 防止重复保存
    _isSaved = true;

    final duration = DateTime.now().difference(_startTime).inMinutes;
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

    // 循环训练日：训练完成后，将计划的 currentDayIndex 推进到下一个训练日
    if (_plan != null) {
      final planId = _plan!['id'] as String?;
      final days = _plan!['days'] as List?;
      if (planId != null && days != null && days.isNotEmpty) {
        final currentDayIndex = (_plan!['currentDayIndex'] as num?)?.toInt() ?? 0;
        // 循环递增到下一天（取模实现循环）
        final nextDayIndex = (currentDayIndex + 1) % days.length;
        await Storage.updatePlanAsync(planId, {'currentDayIndex': nextDayIndex});
        // 更新本地缓存，避免下次进入训练页读到旧值
        _plan!['currentDayIndex'] = nextDayIndex;
      }
    }

    // B4: 成就检查（训练完成后自动计算并弹出 — 修复 Issue 1d）
    if (mounted) {
      final records = Storage.getRecords();
      final currentRecord = records.isNotEmpty ? records.first : <String, dynamic>{};
      final unlockedAchievements =
          await AchievementService.instance.checkAndUnlock(currentRecord);
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
      );
    }
  }

  /// 返回首页：更新桌面卡片、评分引导、导航离开。
  /// 训练记录已在 _autoSaveTraining() 中自动保存。
  Future<void> _returnHome() async {
    // 更新桌面卡片数据
    if (isOhos) {
      FormKitService.instance.endTraining();
    }

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
      final path = await ShareCardService.generateShareCard(record, context);
      if (!mounted) return;
      await PosterPreviewDialog.show(
        context,
        imagePath: path,
        title: '训练记录海报',
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
    final colors = Theme.of(context).extension<FitTrackColors>()!;
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
          // Current exercise card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CardWidget(
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
                          '目标: ${currentEx['reps']}次',
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Rest overlay ─────────────────────────────────────────────

  Widget _buildRestOverlay() {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final progress =
        _totalRestSeconds > 0 ? _restSeconds / _totalRestSeconds : 0.0;
    final currentExName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

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
                  '休息中',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_restSeconds',
                  style: TextStyle(
                    color: colors.accentGlow,
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
                    fillColor: colors.accentGlow,
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _skipRest,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.accentGlow),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '跳过休息',
                      style: TextStyle(
                        color: colors.accentGlow,
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
    final colors = Theme.of(context).extension<FitTrackColors>()!;
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
                                  '休息${log['actualTime']}秒',
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
                                  : '${(_restLog.fold<int>(0, (sum, l) => sum + (l['actualTime'] as num).toInt()) / _restLog.length).round()} 秒',
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
  Widget _detailRow(String label, String value, FitTrackColors colors) {
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
  Widget _buildOpponentPKCard(FitTrackColors colors) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: userWon ? colors.successColor.withOpacity(0.4) : colors.borderColor),
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
          // 双方进度条对比
          _buildPKBar(colors, '我', userWeeklyTrainings, outcome.userScore, colors.accentGlow),
          const SizedBox(height: 8),
          _buildPKBar(colors, opponent.nickname, opponent.weeklyTrainings, outcome.opponentScore, colors.textMuted),
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
    );
  }

  Widget _buildPKBar(FitTrackColors colors, String label, int trainings, double score, Color color) {
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
