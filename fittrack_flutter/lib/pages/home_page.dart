import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
    Storage.dataChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_loadData);
    super.dispose();
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

  String get _userName {
    final settings = Storage.getSettings();
    return settings['userName'] as String? ?? '用户';
  }

  String get _todayDateStr {
    final now = DateTime.now();
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '${now.year}年${now.month}月${now.day}日 星期${weekdays[now.weekday % 7]}';
  }

  Map<String, dynamic>? get _todayPlan {
    final active = _activePlan;
    if (active != null) {
      final days = active['days'] as List? ?? [];
      if (days.isNotEmpty) {
        final weekday = DateTime.now().weekday;
        final dayIndex = weekday <= days.length ? weekday - 1 : 0;
        final dayData = days[dayIndex] as Map<String, dynamic>;
        final exercises = (dayData['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        // 当天没有训练动作或超出计划天数，返回 null 显示"今日休息"
        if (exercises.isEmpty) {
          return null;
        }
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
    return null;
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
    return {
      'trainings': 0,
      'duration': '0h',
      'weight': '0t',
      'calories': '0',
    };
  }

  List<Map<String, dynamic>> get _weeklyCalendarData {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon..7=Sun
    final weekStart = now.subtract(Duration(days: weekday - 1));
    const dayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    // 统计本周每天是否有训练记录
    final trainedDays = <int>{};
    for (final r in _records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        final diff = d.difference(weekStart).inDays;
        if (diff >= 0 && diff < 7) {
          trainedDays.add(diff);
        }
      }
    }

    // 从活跃计划获取每日安排
    final active = _activePlan;
    final planDays = <int, Map<String, dynamic>>{};
    if (active != null) {
      final days = active['days'] as List? ?? [];
      for (int i = 0; i < days.length && i < 7; i++) {
        planDays[i] = days[i] as Map<String, dynamic>;
      }
    }

    return List.generate(7, (i) {
      final isToday = i == weekday - 1;
      final isDone = trainedDays.contains(i);
      final planDay = planDays[i];
      final exercises = (planDay?['exercises'] as List?) ?? [];
      // 没有计划或当天没有训练动作，标记为休息日
      final isRest = exercises.isEmpty;

      return {
        'day': dayLabels[i],
        'label': isRest ? '休息' : (planDay?['label'] ?? '休息'),
        'done': isDone,
        'today': isToday,
        'rest': isRest,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final todayPlan = _todayPlan;
    final weeklyStats = _weeklyStats;
    final streakData = _streak;
    final prData = _personalRecords;
    final activePlan = _activePlan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: '你好, $_userName',
            subtitle: _todayDateStr,
            isTabPage: true,
            onBellTap: () => _showNotifications(context),
            onCalendarTap: () => _showCalendar(context),
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
                    if (todayPlan != null)
                      _buildTodayPlanCard(colors, todayPlan)
                    else
                      _buildNoPlanCard(colors),
                    if (activePlan != null) ...[
                      const SizedBox(height: 14),
                      _buildCurrentPlanCard(colors, activePlan),
                    ],
                    const SizedBox(height: 14),
                    _buildWeeklyStatsGrid(colors, weeklyStats),
                    const SizedBox(height: 14),
                    _buildWeeklyCalendar(colors),
                    const SizedBox(height: 14),
                    _buildStreakCard(colors, streakData),
                    const SizedBox(height: 14),
                    _buildRecentTrainings(colors),
                    if (prData.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildPersonalRecords(colors, prData),
                    ],
                    const SizedBox(height: 14),
                    _buildDailyTip(colors),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard(FitTrackColors colors) {
    // 如果有活跃计划但今天没有训练动作，显示休息日提示
    final hasActivePlan = _activePlan != null;
    final title = hasActivePlan ? '今日休息' : '暂无训练计划';
    final subtitle = hasActivePlan ? '今天没有安排训练，好好休息' : '前往计划页创建训练计划';
    final buttonText = hasActivePlan ? '查看计划' : '创建计划';

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '今日训练',
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              BadgeWidget(text: hasActivePlan ? '休息日' : '未安排', variant: BadgeVariant.info),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(buttonText, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              Text(
                '今日训练',
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              BadgeWidget(text: progress > 0 ? '进行中' : '待开始', variant: progress > 0 ? BadgeVariant.accent : BadgeVariant.info),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan['name'] as String? ?? '',
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
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
                context.push('/training?planId=${plan['planId'] ?? _activePlan?['id'] ?? 'plan1'}&dayIndex=${plan['dayIndex'] ?? 0}');
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
    final items = [
      {'icon': Icons.fitness_center, 'value': '${stats['trainings'] ?? 0}', 'label': '训练次数', 'color': colors.accentGlow},
      {'icon': Icons.timer_outlined, 'value': '${stats['duration'] ?? '0h'}', 'label': '训练时长', 'color': colors.infoColor},
      {'icon': Icons.monitor_weight_outlined, 'value': '${stats['weight'] ?? '0t'}', 'label': '总重量', 'color': colors.warningColor},
      {'icon': Icons.local_fire_department_outlined, 'value': '${stats['calories'] ?? '0'}', 'label': '消耗', 'color': colors.successColor},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '本周统计'),
        const SizedBox(height: 8),
        // 2x2 网格，用 Row+Column 避免 GridView 溢出
        Row(
          children: [
            Expanded(child: StatCard(icon: items[0]['icon'] as IconData, value: items[0]['value'] as String, label: items[0]['label'] as String, color: items[0]['color'] as Color)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(icon: items[1]['icon'] as IconData, value: items[1]['value'] as String, label: items[1]['label'] as String, color: items[1]['color'] as Color)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: StatCard(icon: items[2]['icon'] as IconData, value: items[2]['value'] as String, label: items[2]['label'] as String, color: items[2]['color'] as Color)),
            const SizedBox(width: 10),
            Expanded(child: StatCard(icon: items[3]['icon'] as IconData, value: items[3]['value'] as String, label: items[3]['label'] as String, color: items[3]['color'] as Color)),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar(FitTrackColors colors) {
    final calendarData = _weeklyCalendarData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '本周日历'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: calendarData.map((day) {
            final isDone = day['done'] == true;
            final isToday = day['today'] == true;
            final isRest = day['rest'] == true;

            // 根据日期状态构建指示器
            Widget indicator;
            if (isRest) {
              // 休息日：灰色小圆点
              indicator = Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.textMuted,
                  shape: BoxShape.circle,
                ),
              );
            } else if (isDone) {
              // 训练日且已完成：绿色对勾
              indicator = Icon(Icons.check, size: 14, color: colors.successColor);
            } else if (isToday) {
              // 训练日且今天：橙色小圆点
              indicator = Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors.accentGlow,
                  shape: BoxShape.circle,
                ),
              );
            } else {
              // 训练日且未完成：空心圆环
              indicator = Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accentGlow, width: 1.5),
                ),
              );
            }

            return Expanded(
              child: Column(
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
                    child: Center(child: indicator),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 24,
                    child: Text(
                      '${day['label']}',
                      style: TextStyle(
                        color: isRest ? colors.textMuted : colors.textSecondary,
                        fontSize: 9,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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
              Text(
                '连续打卡',
                style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
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
    final displayList = recentList.map((r) => {
          'name': r['name'] ?? r['planName'] ?? '训练记录',
          'date': _formatDate(r['date'] ?? r['createTime']),
          'duration': '${r['duration'] ?? 0}min',
          'calories': r['calories'] ?? 0,
          'exercises': r['exerciseCount'] ?? (r['exercises'] is List ? (r['exercises'] as List).length : 0),
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '最近训练',
          moreText: recentList.isNotEmpty ? '查看全部' : null,
          onMore: recentList.isNotEmpty ? () => context.go('/records') : null,
        ),
        const SizedBox(height: 12),
        if (displayList.isEmpty)
          CardWidget(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined, size: 36, color: colors.textMuted),
                    const SizedBox(height: 8),
                    Text('暂无训练记录', style: TextStyle(color: colors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
        else
          ...displayList.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CardWidget(
                padding: const EdgeInsets.all(12),
                onTap: () => context.go('/records'),
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
                            style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
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
                        style: TextStyle(color: colors.textPrimary, fontSize: 14),
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
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
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
      onTap: () => context.push('/plan?planId=${plan['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '当前计划',
                style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              BadgeWidget(text: '${plan['badge'] ?? '进行中'}', variant: BadgeVariant.accent),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${plan['name']}',
            style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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

  void _showNotifications(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final records = Storage.getRecords();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: colors.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: colors.borderColor, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Text('通知', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(onTap: () => Navigator.of(ctx).pop(), child: Icon(Icons.close, color: colors.textMuted)),
                  ]),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _notifItem(colors, Icons.celebration, '欢迎使用 FitTrack', '开始你的健身之旅吧！'),
                      if (records.isNotEmpty)
                        _notifItem(colors, Icons.fitness_center, '训练提醒', '你已完成 ${records.length} 次训练，继续加油！'),
                      _notifItem(colors, Icons.tips_and_updates, '每日贴士', MockData.dailyTip['text'] as String),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notifItem(FitTrackColors colors, IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.borderColor)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: colors.accentGlow)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(body, style: TextStyle(color: colors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  void _showCalendar(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final records = Storage.getRecords();
    final now = DateTime.now();
    final trainedDays = <int>{};
    for (final r in records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        if (d.year == now.year && d.month == now.month) trainedDays.add(d.day);
      }
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final firstDay = DateTime(now.year, now.month, 1);
        final startWeekday = firstDay.weekday - 1;
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final cells = <Widget>[];
        for (var i = 0; i < startWeekday; i++) cells.add(const SizedBox());
        for (var day = 1; day <= daysInMonth; day++) {
          final isToday = day == now.day;
          final isTrained = trainedDays.contains(day);
          cells.add(Container(
            height: 36,
            decoration: BoxDecoration(color: isToday ? colors.accentGlow.withOpacity(0.3) : isTrained ? colors.accentGlow.withOpacity(0.1) : Colors.transparent, shape: BoxShape.circle),
            child: Center(child: Text('$day', style: TextStyle(color: isToday ? colors.accentGlow : isTrained ? colors.textPrimary : colors.textMuted, fontSize: 13, fontWeight: isToday || isTrained ? FontWeight.w600 : FontWeight.normal))),
          ));
        }
        final weeks = <Widget>[];
        List<Widget> currentWeek = [];
        for (var i = 0; i < startWeekday; i++) {
          currentWeek.add(const Expanded(child: SizedBox()));
        }
        for (var day = 1; day <= daysInMonth; day++) {
          final isToday = day == now.day;
          final isTrained = trainedDays.contains(day);
          currentWeek.add(Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isToday ? colors.accentGlow.withOpacity(0.3) : isTrained ? colors.accentGlow.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday ? colors.accentGlow : isTrained ? colors.textPrimary : colors.textMuted,
                    fontSize: 13,
                    fontWeight: isToday || isTrained ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ));
          if (currentWeek.length == 7) {
            weeks.add(Row(children: currentWeek));
            currentWeek = [];
          }
        }
        if (currentWeek.isNotEmpty) {
          while (currentWeek.length < 7) {
            currentWeek.add(const Expanded(child: SizedBox()));
          }
          weeks.add(Row(children: currentWeek));
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
            decoration: BoxDecoration(color: colors.bgSecondary, borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), border: Border.all(color: colors.borderColor)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: colors.borderColor, borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                Text('${now.year}年${now.month}月', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(onTap: () => Navigator.of(ctx).pop(), child: Icon(Icons.close, color: colors.textMuted)),
              ])),
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: ['一','二','三','四','五','六','日'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))))).toList())),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: weeks),
              ),
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentGlow, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('已训练 ${trainedDays.length} 天', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.3), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('今天', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              ])),
              const SizedBox(height: 20),
            ]),
          ),
        );
      },
    );
  }
}
