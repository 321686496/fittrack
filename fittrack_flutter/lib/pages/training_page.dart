import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../services/rest_notification_service.dart';
import '../services/ohos_reminder_service.dart';
import '../services/form_kit_service.dart';
import '../services/share_card_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

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

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTime = DateTime.now();
    _loadData();

    // 监听 OHOS 通知点击
    if (Platform.isOhos) {
      OhosReminderService.instance.onNotificationClick = _onNotificationClicked;
      // 注册训练卡片交互回调：卡片点击时原地处理，避免跳转首页销毁本页
      OhosReminderService.instance.onTrainingCardAction = _onTrainingCardAction;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    // 清理通知点击回调
    if (Platform.isOhos) {
      OhosReminderService.instance.onNotificationClick = null;
      OhosReminderService.instance.onTrainingCardAction = null;
    }
    super.dispose();
  }

  /// 真正退出训练页时，将卡片恢复为空闲态。
  /// 只在用户主动离开（返回按钮 / 系统返回 / 保存返回）时调用，
  /// 不放在 dispose() 中，避免 go_router 页面重建时被误重置。
  void _resetWidgetOnExit() {
    if (Platform.isOhos) {
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
        if (!Platform.isOhos) {
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
      if (!Platform.isOhos) {
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

  void _completeSet() {
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
      setState(() {
        _trainingDone = true;
      });
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
    if (Platform.isOhos && _currentExIdx < _exercises.length) {
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
    if (!Platform.isOhos) {
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
    // OHOS 平台：代理提醒由 EntryAbility 自动管理（收到 mode=training/idle 时取消），无需 Flutter 侧取消
    if (!Platform.isOhos) {
      RestNotificationService.instance.cancelScheduledNotification();
    }
    _advanceAfterRest();
  }

  /// 休息结束时提醒
  /// - 前台：增强振动 + 显示通知
  /// - 后台恢复：wall-clock 检测到休息已结束，补发振动 + 通知
  ///   （OHOS 上由 EntryAbility 的 reminderAgentManager 代理提醒处理，
  ///     Flutter 侧仅做振动提醒）
  Future<void> _notifyRestEnd() async {
    if (_restEndNotified) return;
    _restEndNotified = true;

    final exerciseName = _currentExIdx < _exercises.length
        ? _exercises[_currentExIdx]['name'] as String
        : '';

    if (_appLifecycleState == AppLifecycleState.resumed) {
      // 前台或从后台恢复：振动 + 显示通知
      await RestNotificationService.vibrate();
      // OHOS 平台：通知由 EntryAbility 的 notificationManager 处理，Flutter 侧仅振动
      if (!Platform.isOhos) {
        await RestNotificationService.instance
            .showRestEndNotification(exerciseName: exerciseName);
      }
    }
    // 后台时无法主动触发通知（OHOS 限制），等待用户回到应用时补发
  }

  void _advanceAfterRest() {
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
    // 推送训练状态到卡片
    _pushTrainingToWidget();
  }

  /// 推送训练状态到桌面卡片
  void _pushTrainingToWidget() {
    if (!Platform.isOhos) return;
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

  Future<void> _saveAndReturn() async {
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

    Storage.addRecord({
      'name': _dayConfig?['label'] ?? '训练',
      'date': DateTime.now().millisecondsSinceEpoch,
      'duration': duration,
      'totalWeight': totalWeight,
      'totalSets': _completedSets,
      'exerciseCount': _exercises.length,
      'muscles': muscles.toList(),
      'setRecords': _setRecords.map((k, v) => MapEntry(k, v)),
      'restLog': _restLog,
    });

    // 训练完成触觉反馈
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    // 检查是否达成新成就
    _checkAndShowNewAchievements();

    // 更新桌面卡片数据
    if (Platform.isOhos) {
      FormKitService.instance.endTraining();
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
      if (Platform.isOhos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('训练卡片已生成，分享功能即将上线')),
        );
      } else {
        await ShareCardService.shareImage(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成分享卡片失败：$e')),
        );
      }
    }
  }

  void _checkAndShowNewAchievements() {
    final records = Storage.getRecords();
    final stats = Storage.getStats();
    final totalTrainings = (stats['totalTrainings'] as num?)?.toInt() ?? records.length;
    final totalWeight = (stats['totalWeight'] as num?)?.toDouble() ?? 0.0;
    final totalDuration = (stats['totalDuration'] as num?)?.toDouble() ?? 0.0;

    int currentStreak = 0;
    if (records.isNotEmpty) {
      final dates = <String>{};
      for (final r in records) {
        final ts = r['date'] ?? r['createTime'];
        if (ts is int) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts);
          dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        }
      }
      var checkDate = DateTime.now();
      while (dates.contains('${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    int totalReps = 0;
    for (final r in records) {
      final setRecords = r['setRecords'];
      if (setRecords is Map) {
        for (final entry in setRecords.values) {
          if (entry is List) {
            for (final s in entry) {
              if (s is Map) totalReps += (s['reps'] as num?)?.toInt() ?? 0;
            }
          }
        }
      }
    }

    final settings = Storage.getSettings();
    final previouslyUnlocked = <String>{};
    final saved = settings['unlockedAchievements'];
    if (saved is List) {
      for (final s in saved) previouslyUnlocked.add(s.toString());
    }

    final newlyUnlocked = <Map<String, dynamic>>[];
    for (final a in MockData.achievements) {
      final id = a['id'] as String;
      if (previouslyUnlocked.contains(id)) continue;
      bool unlocked = false;
      switch (id) {
        case 'a1': unlocked = totalTrainings >= 1; break;
        case 'a2': unlocked = currentStreak >= 7; break;
        case 'a3': unlocked = totalWeight >= 100000; break;
        case 'a4': unlocked = totalDuration >= 6000; break;
        case 'a5': unlocked = totalReps >= 1000; break;
        case 'a6': unlocked = currentStreak >= 30; break;
      }
      if (unlocked) newlyUnlocked.add(Map<String, dynamic>.from(a));
    }

    // 保存当前已解锁的成就
    final allUnlocked = MockData.achievements.where((a) {
      final id = a['id'] as String;
      bool u = false;
      switch (id) {
        case 'a1': u = totalTrainings >= 1; break;
        case 'a2': u = currentStreak >= 7; break;
        case 'a3': u = totalWeight >= 100000; break;
        case 'a4': u = totalDuration >= 6000; break;
        case 'a5': u = totalReps >= 1000; break;
        case 'a6': u = currentStreak >= 30; break;
      }
      return u;
    }).map((a) => a['id'] as String).toList();
    Storage.saveSettings({...settings, 'unlockedAchievements': allUnlocked});

    // 弹出恭喜弹窗
    if (newlyUnlocked.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAchievementSequence(newlyUnlocked, 0);
      });
    }
  }

  void _showAchievementSequence(List<Map<String, dynamic>> achievements, int index) {
    if (index >= achievements.length || !mounted) return;
    final a = achievements[index];
    AchievementDialog.show(
      context,
      icon: a['icon'] as String,
      name: a['name'] as String,
      desc: a['desc'] as String,
      onDone: () => _showAchievementSequence(achievements, index + 1),
    );
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
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAndReturn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '保存并返回首页',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
