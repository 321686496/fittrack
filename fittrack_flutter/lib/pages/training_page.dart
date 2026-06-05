import 'dart:async';
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class TrainingPage extends StatefulWidget {
  final Map<String, dynamic> params;
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const TrainingPage({
    super.key,
    required this.params,
    required this.onNavigate,
  });

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
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
    _startTime = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
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

    setState(() {});
  }

  // ── Computed ─────────────────────────────────────────────────

  int get _totalSets =>
      _exercises.fold(0, (sum, ex) => sum + ((ex['sets'] as int?) ?? 0));

  int get _completedSets =>
      _setRecords.values.fold(0, (sum, list) => sum + list.length);

  double get _overallProgress =>
      _totalSets > 0 ? _completedSets / _totalSets : 0.0;

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
      final restTime = (currentEx['restTime'] as int?) ?? 90;
      _startRest(restTime, isLastSet);
    }
  }

  void _startRest(int seconds, bool isLastSetOfExercise) {
    setState(() {
      _isResting = true;
      _restSeconds = seconds;
      _totalRestSeconds = seconds;
      _isLastSetOfExercise = isLastSetOfExercise;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _restSeconds--;
      });
      if (_restSeconds <= 0) {
        timer.cancel();
        _advanceAfterRest();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _advanceAfterRest();
  }

  void _advanceAfterRest() {
    _restLog.add({
      'exercise': _exercises[_currentExIdx]['name'],
      'restTime': _totalRestSeconds,
      'actualTime': _totalRestSeconds - _restSeconds,
    });

    setState(() {
      _isResting = false;
      if (_isLastSetOfExercise) {
        _currentExIdx++;
        _currentSetIdx = 0;
      } else {
        _currentSetIdx++;
      }
      _weightController.clear();
      _repsController.clear();
    });
  }

  void _saveAndReturn() {
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

    widget.onNavigate('home');
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
            onBack: () => widget.onNavigate('home'),
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
            onBack: () => widget.onNavigate('home'),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle:
                                      TextStyle(color: colors.textMuted),
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
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle:
                                      TextStyle(color: colors.textMuted),
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

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            onBack: () => widget.onNavigate('home'),
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
                  const Text(
                    '训练完成',
                    style: TextStyle(
                      color: Colors.white,
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
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14),
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
