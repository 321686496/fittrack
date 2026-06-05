import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class HomePage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _streak = {};
  List<Map<String, dynamic>> _personalRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _plans = Storage.getPlans();
    _records = Storage.getRecords();
    _stats = Storage.getStats();
    _streak = _computeStreak();
    _personalRecords = _computePersonalRecords();
    setState(() {});
  }

  Map<String, dynamic> _computeStreak() {
    if (_records.isEmpty) {
      return {'current': 0, 'longest': 0, 'thisMonth': 0, 'monthTotal': 0};
    }

    final dates = <String>{};
    for (final r in _records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
    }

    final sortedDates = dates.toList()..sort();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    int currentStreak = 0;
    if (sortedDates.contains(todayStr)) {
      currentStreak = 1;
      var checkDate = today.subtract(const Duration(days: 1));
      while (dates.contains('${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      if (sortedDates.contains(yesterdayStr)) {
        currentStreak = 1;
        var checkDate = yesterday.subtract(const Duration(days: 1));
        while (dates.contains('${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
    }

    int longestStreak = 0;
    if (sortedDates.isNotEmpty) {
      int temp = 1;
      for (int i = 1; i < sortedDates.length; i++) {
        final prev = DateTime.parse(sortedDates[i - 1]);
        final curr = DateTime.parse(sortedDates[i]);
        if (curr.difference(prev).inDays == 1) {
          temp++;
        } else {
          if (temp > longestStreak) longestStreak = temp;
          temp = 1;
        }
      }
      if (temp > longestStreak) longestStreak = temp;
    }

    int thisMonth = 0;
    for (final r in _records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        if (d.year == today.year && d.month == today.month) {
          thisMonth++;
        }
      }
    }

    return {
      'current': currentStreak,
      'longest': longestStreak,
      'thisMonth': thisMonth,
      'monthTotal': DateTime(today.year, today.month + 1, 0).day,
    };
  }

  List<Map<String, dynamic>> _computePersonalRecords() {
    final prMap = <String, Map<String, dynamic>>{};
    for (final r in _records) {
      final exercises = r['exercises'];
      if (exercises is! List) continue;
      for (final ex in exercises) {
        if (ex is! Map) continue;
        final name = ex['name'] as String? ?? '';
        final weight = ex['weight'];
        final w = weight is num ? weight.toDouble() : 0.0;
        if (!prMap.containsKey(name) || w > (prMap[name]!['weight'] as double)) {
          prMap[name] = {'name': name, 'weight': w};
        }
      }
    }
    final result = prMap.values.toList()
      ..sort((a, b) => (b['weight'] as double).compareTo(a['weight'] as double));
    return result.take(3).map((e) => {'name': e['name'], 'weight': '${(e['weight'] as double).toInt()}kg'}).toList();
  }

  Map<String, dynamic>? get _activePlan {
    try {
      return _plans.firstWhere((p) => p['status'] == 'active');
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> get _todayPlan {
    final active = _activePlan;
    if (active != null) {
      final days = active['days'] as List? ?? [];
      if (days.isNotEmpty) {
        final weekday = DateTime.now().weekday;
        final dayIndex = weekday <= days.length ? weekday - 1 : 0;
        final dayData = days[dayIndex] as Map<String, dynamic>;
        final exercises = (dayData['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        return {
          'name': dayData['label'] ?? '今日训练',
          'muscle': dayData['muscle'] ?? '',
          'duration': 60,
          'exerciseCount': exercises.length,
          'completed': 0,
          'planId': active['id'],
          'dayIndex': dayIndex,
        };
      }
    }
    return Map<String, dynamic>.from(MockData.todayPlan);
  }

  Map<String, dynamic> get _weeklyStats {
    if (_stats['weeklyData'] is List && (_stats['weeklyData'] as List).isNotEmpty) {
      final weeklyData = _stats['weeklyData'] as List;
      final latest = weeklyData.last as Map<String, dynamic>;
      return {
        'trainings': latest['trainings'] ?? 0,
        'duration': '${((latest['duration'] ?? 0 as num) / 60).toStringAsFixed(1)}h',
        'weight': '${((latest['weight'] ?? 0 as num) / 1000).toStringAsFixed(1)}t',
        'calories': (((latest['trainings'] ?? 0) as int) * 420).toString(),
      };
    }
    return Map<String, dynamic>.from(MockData.weeklyStats);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final todayPlan = _todayPlan;
    final weeklyStats = _weeklyStats;
    final streakData = _streak;
    final prData = _personalRecords.isNotEmpty ? _personalRecords : MockData.personalRecords;
    final activePlan = _activePlan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: '你好, ${MockData.user['name']}',
            subtitle: MockData.getTodayDate(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.accentGlow,
              backgroundColor: colors.bgCard,
              onRefresh: () async {
                _loadData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTodayPlanCard(colors, todayPlan),
                    const SizedBox(height: 20),
                    _buildWeeklyStatsGrid(colors, weeklyStats),
                    const SizedBox(height: 20),
                    _buildWeeklyCalendar(colors),
                    const SizedBox(height: 20),
                    _buildStreakCard(colors, streakData),
                    const SizedBox(height: 20),
                    _buildRecentTrainings(colors),
                    const SizedBox(height: 20),
                    _buildPersonalRecords(colors, prData),
                    const SizedBox(height: 20),
                    _buildDailyTip(colors),
                    if (activePlan != null) ...[
                      const SizedBox(height: 20),
                      _buildCurrentPlanCard(colors, activePlan),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPlanCard(FitTrackColors colors, Map<String, dynamic> plan) {
    final completed = plan['completed'] as int? ?? 0;
    final total = plan['exerciseCount'] as int? ?? 1;
    final progress = total > 0 ? completed / total : 0.0;

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              const Text(
                '今日训练',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              BadgeWidget(text: progress > 0 ? '进行中' : '待开始', variant: progress > 0 ? BadgeVariant.accent : BadgeVariant.info),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan['name'] as String? ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            plan['muscle'] as String? ?? '',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${plan['duration'] ?? 0}min',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.list_alt, size: 16, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '$total个动作',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(progress: progress),
          const SizedBox(height: 4),
          Text(
            '$completed/$total 已完成',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onNavigate(
                  'training',
                  params: {
                    'planId': plan['planId'] ?? _activePlan?['id'] ?? 'plan1',
                    'dayIndex': plan['dayIndex'] ?? 0,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('开始训练', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsGrid(FitTrackColors colors, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '本周统计'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            StatCard(
              icon: Icons.fitness_center,
              value: '${stats['trainings'] ?? 0}',
              label: '训练次数',
              color: colors.accentGlow,
            ),
            StatCard(
              icon: Icons.timer_outlined,
              value: '${stats['duration'] ?? '0h'}',
              label: '训练时长',
              color: colors.infoColor,
            ),
            StatCard(
              icon: Icons.monitor_weight_outlined,
              value: '${stats['weight'] ?? '0t'}',
              label: '总重量',
              color: colors.warningColor,
            ),
            StatCard(
              icon: Icons.local_fire_department_outlined,
              value: '${stats['calories'] ?? '0'}',
              label: '消耗',
              color: colors.successColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(FitTrackColors colors) {
    final calendarData = MockData.weeklyCalendar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '本周日历'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: calendarData.map((day) {
            final isDone = day['done'] == true;
            final isToday = day['today'] == true;
            final isRest = day['rest'] == true;

            Color dotColor;
            if (isDone && !isRest) {
              dotColor = colors.successColor;
            } else if (isToday) {
              dotColor = colors.accentGlow;
            } else if (isRest) {
              dotColor = colors.textMuted;
            } else {
              dotColor = Colors.transparent;
            }

            return Column(
              children: [
                Text(
                  '周${day['day']}',
                  style: TextStyle(
                    color: isToday ? colors.accentGlow : colors.textMuted,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isToday ? colors.accentGlow.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: colors.accentGlow, width: 1.5) : null,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day['label']}',
                  style: TextStyle(
                    color: isRest ? colors.textMuted : colors.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStreakCard(FitTrackColors colors, Map<String, dynamic> streak) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 20, color: colors.warningColor),
              const SizedBox(width: 8),
              const Text(
                '连续打卡',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStreakItem(colors, '${streak['current'] ?? 0}', '当前连续', colors.accentGlow),
              _buildStreakItem(colors, '${streak['longest'] ?? 0}', '最长连续', colors.warningColor),
              _buildStreakItem(colors, '${streak['thisMonth'] ?? 0}', '本月打卡', colors.successColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(FitTrackColors colors, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentTrainings(FitTrackColors colors) {
    final recentList = _records.take(3).toList();
    final displayList = recentList.isNotEmpty
        ? recentList.map((r) => {
              'name': r['name'] ?? r['planName'] ?? '训练记录',
              'date': _formatDate(r['date'] ?? r['createTime']),
              'duration': '${r['duration'] ?? 0}min',
              'calories': r['calories'] ?? 0,
              'exercises': r['exerciseCount'] ?? (r['exercises'] is List ? (r['exercises'] as List).length : 0),
            }).toList()
        : MockData.recentTrainings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '最近训练',
          moreText: '查看全部',
          onMore: () => widget.onNavigate('records'),
        ),
        const SizedBox(height: 12),
        ...displayList.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardWidget(
                padding: const EdgeInsets.all(12),
                onTap: () => widget.onNavigate('records'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.fitness_center, size: 20, color: colors.accentGlow),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['name']}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['date']}',
                            style: TextStyle(color: colors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['duration']}',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          '${item['calories']}kcal',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  String _formatDate(dynamic ts) {
    if (ts is int) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final now = DateTime.now();
      final diff = now.difference(d).inDays;
      if (diff == 0) return '今天';
      if (diff == 1) return '昨天';
      if (diff < 7) return '$diff天前';
      return '${d.month}/${d.day}';
    }
    return '$ts';
  }

  Widget _buildPersonalRecords(FitTrackColors colors, List<Map<String, dynamic>> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '个人记录'),
        const SizedBox(height: 12),
        ...records.map((record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardWidget(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, size: 20, color: colors.warningColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${record['name']}',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Text(
                      '${record['weight']}',
                      style: TextStyle(color: colors.accentGlow, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildDailyTip(FitTrackColors colors) {
    final tip = MockData.dailyTip;
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: colors.warningColor),
              const SizedBox(width: 8),
              Text(
                '每日贴士 · ${tip['category']}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${tip['text']}',
            style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(FitTrackColors colors, Map<String, dynamic> plan) {
    final progress = (plan['progress'] as num? ?? 0) / 100.0;
    final totalWeeks = plan['totalWeeks'] ?? 0;
    final currentWeek = plan['week'] ?? 0;

    return CardWidget(
      onTap: () => widget.onNavigate('plan_detail', params: {'planId': plan['id']}),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              const Text(
                '当前计划',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              BadgeWidget(text: '${plan['badge'] ?? '进行中'}', variant: BadgeVariant.accent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${plan['name']}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '第$currentWeek/$totalWeeks周',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Text(
                '${plan['frequency'] ?? ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(progress: progress),
        ],
      ),
    );
  }
}
