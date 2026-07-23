import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_refresh_mixin.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with TabRefreshMixin<StatsPage> {
  // ── Data ─────────────────────────────────────────────────────
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _records = [];

  // ── Chart toggle ─────────────────────────────────────────────
  bool _showWeek = true;

  // ── Computed chart data ──────────────────────────────────────
  List<Map<String, dynamic>> _weekChartData = [];
  List<Map<String, dynamic>> _monthChartData = [];

  // ── Muscle distribution ──────────────────────────────────────
  List<Map<String, dynamic>> _muscleData = [];

  // ── Personal records ─────────────────────────────────────────
  List<Map<String, dynamic>> _personalRecords = [];

  // ── Daily counts for heatmap ─────────────────────────────────
  Map<String, int> _dailyCounts = {};

  // ── Muscle color map ─────────────────────────────────────────
  static const Map<String, Color> _muscleColors = {
    '胸': Color(0xFF3b82f6),
    '胸部': Color(0xFF3b82f6),
    '背': Color(0xFF0ea5e9),
    '背部': Color(0xFF0ea5e9),
    '腿': Color(0xFF22c55e),
    '腿部': Color(0xFF22c55e),
    '肩': Color(0xFFf59e0b),
    '肩部': Color(0xFFf59e0b),
    '手臂': Color(0xFFa855f7),
    '核心': Color(0xFFef4444),
  };

  // ── Lifecycle ────────────────────────────────────────────────

  @override
  int get tabIndex => 3;

  @override
  void onTabBecameActive() {
    _loadAndCompute();
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    _loadAndCompute();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadAndCompute();
  }

  void _loadAndCompute() {
    _stats = Storage.getStats();
    _records = Storage.getRecords();
    _computeWeekChart();
    _computeMonthChart();
    _computeMuscleDistribution();
    _computePersonalRecords();
    _computeDailyCounts();
  }

  // ── Compute daily counts for heatmap ─────────────────────────

  void _computeDailyCounts() {
    _dailyCounts = {};
    for (final r in _records) {
      final ts = r['date'] as int? ?? r['createTime'] as int?;
      if (ts == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final key = '${d.year}-${d.month}-${d.day}';
      _dailyCounts[key] = (_dailyCounts[key] ?? 0) + 1;
    }
  }

  // ── Compute week chart ───────────────────────────────────────

  void _computeWeekChart() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon .. 7=Sun
    final weekStart = now.subtract(Duration(days: weekday - 1));

    // Initialize 7 days
    final dailyCounts = <int, int>{};
    for (int i = 0; i < 7; i++) {
      dailyCounts[i] = 0;
    }

    const dayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    for (final r in _records) {
      final ts = r['date'] as int?;
      if (ts == null) continue;
      final recordDate = DateTime.fromMillisecondsSinceEpoch(ts);
      final diff = recordDate.difference(weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        dailyCounts[diff] = (dailyCounts[diff] ?? 0) + 1;
      }
    }

    _weekChartData = List.generate(7, (i) {
      return {'label': dayLabels[i], 'value': dailyCounts[i] ?? 0};
    });
  }

  // ── Compute month chart ──────────────────────────────────────

  void _computeMonthChart() {
    final weeklyData = _stats['weeklyData'] as List<dynamic>? ?? [];
    final list = List<Map<String, dynamic>>.from(
      weeklyData.map((e) => Map<String, dynamic>.from(e as Map)),
    );

    // Take last 5 weeks
    final recent = list.length > 5 ? list.sublist(list.length - 5) : list;

    _monthChartData = recent.map((w) {
      final weekStr = w['week'] as String? ?? '';
      final label = weekStr.isNotEmpty ? 'W${weekStr.split('-W').last}' : '';
      return {
        'label': label,
        'value': w['trainings'] ?? 0,
      };
    }).toList();

    // Ensure at least 1 entry so chart is not empty
    if (_monthChartData.isEmpty) {
      _monthChartData = [
        {'label': '本周', 'value': 0}
      ];
    }
  }

  // ── Compute muscle distribution ──────────────────────────────

  void _computeMuscleDistribution() {
    final raw = _stats['muscleData'];
    if (raw is! Map || raw.isEmpty) {
      _muscleData = [];
      return;
    }

    final muscleMap = Map<String, int>.from(
      raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
    );

    final total = muscleMap.values.fold(0, (sum, v) => sum + v);

    _muscleData = muscleMap.entries.map((e) {
      final pct = total > 0 ? (e.value / total * 100).round() : 0;
      return {
        'name': e.key,
        'pct': pct,
        'count': e.value,
        'color': _muscleColors[e.key] ?? const Color(0xFF6b7280),
      };
    }).toList();

    _muscleData.sort((a, b) => (b['pct'] as int).compareTo(a['pct'] as int));
  }

  // ── Compute personal records ─────────────────────────────────

  void _computePersonalRecords() {
    // Build exercise id -> name lookup
    final exLookup = <String, String>{};
    for (final ex in MockData.exercises) {
      exLookup[ex['id'] as String] = ex['name'] as String;
    }

    final allSets = <Map<String, dynamic>>[];

    for (final r in _records) {
      final sr = r['setRecords'];
      if (sr is! Map) continue;
      final date = r['date'] as int?;
      final dateStr = date != null
          ? DateTime.fromMillisecondsSinceEpoch(date)
              .toString()
              .substring(0, 10)
          : '';

      for (final entry in sr.entries) {
        final exId = entry.key.toString();
        final exName = exLookup[exId] ?? exId;
        final sets = entry.value as List<dynamic>? ?? [];
        for (final s in sets) {
          final sm = s as Map<dynamic, dynamic>;
          final weight = (sm['weight'] as num?) ?? 0;
          if (weight.toDouble() > 0) {
            allSets.add({
              'name': exName,
              'weight': weight.toDouble(),
              'reps': (sm['reps'] as num?) ?? 0,
              'date': dateStr,
            });
          }
        }
      }
    }

    allSets.sort((a, b) =>
        (b['weight'] as double).compareTo(a['weight'] as double));

    _personalRecords = allSets.take(3).toList();
  }

  // ── 按周聚合数据（近6周）─────────────────────────────────────
  Map<int, Map<String, dynamic>> _computeWeeklyStats() {
    final now = DateTime.now();
    final result = <int, Map<String, dynamic>>{};
    for (int weekOffset = 0; weekOffset < 6; weekOffset++) {
      result[weekOffset] = {
        'totalVolume': 0.0,
        'totalDuration': 0,
        'trainingCount': 0,
      };
    }
    for (final r in _records) {
      final ts = r['date'] as int? ?? r['createTime'] as int?;
      if (ts == null) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final diff = now.difference(d).inDays;
      if (diff < 0) continue;
      final weekOffset = diff ~/ 7;
      if (weekOffset >= 0 && weekOffset < 6) {
        final sr = r['setRecords'];
        double volume = 0;
        if (sr is Map) {
          for (final entry in sr.entries) {
            final sets = entry.value as List<dynamic>? ?? [];
            for (final s in sets) {
              final sm = s as Map<dynamic, dynamic>;
              final w = (sm['weight'] as num?) ?? 0;
              final reps = (sm['reps'] as num?) ?? 0;
              volume += w * reps;
            }
          }
        }
        result[weekOffset]!['totalVolume'] =
            (result[weekOffset]!['totalVolume'] as double) + volume;
        final duration = (r['duration'] as num?) ?? 0;
        result[weekOffset]!['totalDuration'] =
            (result[weekOffset]!['totalDuration'] as int) + duration.toInt();
        result[weekOffset]!['trainingCount'] =
            (result[weekOffset]!['trainingCount'] as int) + 1;
      }
    }
    return result;
  }

  // ── 动作热度计数 Top 5 ──────────────────────────────────────
  List<Map<String, dynamic>> _computeExercisePopularity() {
    final counts = <String, int>{};
    for (final r in _records) {
      final sr = r['setRecords'];
      if (sr is! Map) continue;
      for (final entry in sr.entries) {
        final exId = entry.key.toString();
        counts[exId] = (counts[exId] ?? 0) + 1;
      }
    }
    final exLookup = <String, String>{};
    for (final ex in MockData.exercises) {
      exLookup[ex['id'] as String] = ex['name'] as String;
    }
    final list = counts.entries.map((e) {
      return {
        'name': exLookup[e.key] ?? e.key,
        'count': e.value,
      };
    }).toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(5).toList();
  }

  // ── PR 进度追踪（Top 3 动作近6周最大重量）─────────────────────
  Map<String, List<Map<String, dynamic>>> _computePrProgression() {
    final topExercises = _computeExercisePopularity().take(3).toList();
    final exLookup = <String, String>{};
    for (final ex in MockData.exercises) {
      exLookup[ex['id'] as String] = ex['name'] as String;
    }
    // 反向查找 name → id
    final nameToId = <String, String>{};
    for (final entry in exLookup.entries) {
      nameToId[entry.value] = entry.key;
    }

    final result = <String, List<Map<String, dynamic>>>{};
    for (final ex in topExercises) {
      final exName = ex['name'] as String;
      final exId = nameToId[exName];
      if (exId == null) continue;
      result[exName] = [];
      final now = DateTime.now();
      for (int weekOffset = 0; weekOffset < 6; weekOffset++) {
        double maxWeight = 0;
        for (final r in _records) {
          final ts = r['date'] as int? ?? r['createTime'] as int?;
          if (ts == null) continue;
          final d = DateTime.fromMillisecondsSinceEpoch(ts);
          final diff = now.difference(d).inDays;
          if (diff < 0) continue;
          final wOffset = diff ~/ 7;
          if (wOffset == weekOffset) {
            final sr = r['setRecords'];
            if (sr is Map) {
              final sets = sr[exId] as List<dynamic>? ?? [];
              for (final s in sets) {
                final sm = s as Map<dynamic, dynamic>;
                final w = (sm['weight'] as num?) ?? 0;
                if (w > maxWeight) maxWeight = w.toDouble();
              }
            }
          }
        }
        result[exName]!.add({
          'week': weekOffset,
          'maxWeight': maxWeight,
        });
      }
    }
    return result;
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h${m}m' : '${h}h';
    }
    return '$minutes分钟';
  }

  String _formatWeight(int grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(1)}t';
    }
    return '${grams}kg';
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    // 空状态：保留总览（值为0）+ 引导卡片
    if (_records.isEmpty) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              title: '训练统计',
              isTabPage: true,
            ),
            Expanded(
              child: RefreshIndicator(
                color: colors.accentGlow,
                backgroundColor: colors.bgCard,
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // ── 详细统计（值为0）───────────────────────
                      const SectionHeader(title: '详细统计'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: StatCard(icon: Icons.fitness_center, value: '0', label: '总训练次数', color: colors.accentGlow)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(icon: Icons.timer_outlined, value: '0分钟', label: '总训练时长', color: colors.infoColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: StatCard(icon: Icons.monitor_weight_outlined, value: '0kg', label: '累计重量', color: colors.warningColor)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(icon: Icons.local_fire_department, value: '0', label: '消耗卡路里', color: colors.successColor)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: StatCard(icon: Icons.trending_up, value: '0分钟', label: '平均时长', color: colors.purpleColor)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(icon: Icons.scale_outlined, value: '0kg', label: '平均重量', color: colors.accentSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: StatCard(icon: Icons.repeat, value: '0', label: '总训练组数', color: colors.infoColor)),
                          const SizedBox(width: 12),
                          Expanded(child: StatCard(icon: Icons.calendar_today_outlined, value: '0', label: '本月训练', color: colors.successColor)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // ── 热力图（空数据也显示）────────────────────
                      _buildHeatmap(colors),
                      const SizedBox(height: 24),
                      // ── 引导卡片 ──────────────────────────────
                      CardWidget(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 48, color: colors.accentGlow),
                            const SizedBox(height: 16),
                            Text(
                              '暂无训练数据',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '完成你的第一次训练，开始记录健身历程',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.push('/plan'),
                                child: const Text('去训练'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final totalTrainings = (_stats['totalTrainings'] as num?) ?? 0;
    final totalDuration = (_stats['totalDuration'] as num?) ?? 0;
    final totalWeight = (_stats['totalWeight'] as num?) ?? 0;
    final calories = (totalDuration.toInt() * 8); // ~8 cal/min estimate

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: '训练统计',
            isTabPage: true,
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.accentGlow,
              backgroundColor: colors.bgCard,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // ── 详细统计 ────────────────────────────────
                    const SectionHeader(title: '详细统计'),
                    const SizedBox(height: 8),
                    // 第一行：基础统计
                    Row(
                      children: [
                        Expanded(child: StatCard(icon: Icons.fitness_center, value: '$totalTrainings', label: '总训练次数', color: colors.accentGlow)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(icon: Icons.timer_outlined, value: _formatDuration(totalDuration.toInt()), label: '总训练时长', color: colors.infoColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第二行：重量与热量
                    Row(
                      children: [
                        Expanded(child: StatCard(icon: Icons.monitor_weight_outlined, value: _formatWeight(totalWeight.toInt()), label: '累计重量', color: colors.warningColor)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(icon: Icons.local_fire_department, value: '$calories', label: '消耗卡路里', color: colors.successColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第三行：详细统计 - 平均时长与平均重量
                    Row(
                      children: [
                        Expanded(child: StatCard(
                          icon: Icons.trending_up,
                          value: totalTrainings > 0 ? _formatDuration((totalDuration / totalTrainings).round()) : '0分钟',
                          label: '平均时长',
                          color: colors.purpleColor,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(
                          icon: Icons.scale_outlined,
                          value: totalTrainings > 0 ? _formatWeight((totalWeight / totalTrainings).round()) : '0kg',
                          label: '平均重量',
                          color: colors.accentSecondary,
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第四行：总组数与完成率
                    Row(
                      children: [
                        Expanded(child: StatCard(
                          icon: Icons.repeat,
                          value: '${_records.fold<int>(0, (sum, r) => sum + ((r['setRecords'] as Map?)?.length ?? 0))}',
                          label: '总训练组数',
                          color: colors.infoColor,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(
                          icon: Icons.calendar_today_outlined,
                          value: '${_records.where((r) {
                            final date = r['date'] as int? ?? 0;
                            final now = DateTime.now();
                            final recordDate = DateTime.fromMillisecondsSinceEpoch(date);
                            return recordDate.month == now.month && recordDate.year == now.year;
                          }).length}',
                          label: '本月训练',
                          color: colors.successColor,
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 训练活跃度热力图 ──────────────────────────
                    _buildHeatmap(colors),
                    const SizedBox(height: 24),

                    // ── Training frequency chart ─────────────────
                    const SectionHeader(title: '训练频率'),
                    const SizedBox(height: 12),
                    _buildFrequencyChart(colors),
                    const SizedBox(height: 24),

                    // ── 训练容量趋势（新增）─────────────────────────
                    _buildVolumeChart(colors),
                    const SizedBox(height: 24),

                    // ── 动作热度榜（新增）─────────────────────────
                    _buildExercisePopularityChart(colors),
                    const SizedBox(height: 24),

                    // ── 训练时长趋势（新增）─────────────────────────
                    _buildDurationTrendChart(colors),
                    const SizedBox(height: 24),

                    // ── PR 进度追踪（新增）─────────────────────────
                    _buildPrProgressionChart(colors),
                    const SizedBox(height: 24),

                    // ── Muscle distribution ──────────────────────
                    if (_muscleData.isNotEmpty) ...[
                      const SectionHeader(title: '肌群分布'),
                      const SizedBox(height: 12),
                      _buildMuscleDistribution(colors),
                      const SizedBox(height: 24),
                    ],

                    // ── Personal records ─────────────────────────
                    if (_personalRecords.isNotEmpty) ...[
                      const SectionHeader(title: '个人记录'),
                      const SizedBox(height: 12),
                      _buildPersonalRecords(colors),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 200),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 训练活跃度热力图 ──────────────────────────────────────────

  Widget _buildHeatmap(FitTrackColors colors) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = now.weekday; // 1=Mon..7=Sun
    // 本周一
    final currentWeekMonday = today.subtract(Duration(days: weekday - 1));
    // 12周范围起始（11周前的周一）
    final rangeStart =
        currentWeekMonday.subtract(const Duration(days: 7 * 11));

    const spacing = 4.0;
    const borderRadius = 3.0;

    // 根据训练次数返回对应颜色
    Color colorForCount(int count) {
      if (count == 0) return colors.bgSecondary;
      if (count == 1) return colors.accentGlow.withOpacity(0.3);
      if (count == 2) return colors.accentGlow.withOpacity(0.6);
      return colors.accentGlow;
    }

    // 星期标签（仅显示一/三/五）
    String weekdayLabel(int row) {
      switch (row) {
        case 0:
          return '一';
        case 2:
          return '三';
        case 4:
          return '五';
        default:
          return '';
      }
    }

    // 月份标签（月份变化时显示）
    String monthLabel(int col) {
      final colStart = rangeStart.add(Duration(days: col * 7));
      if (col == 0) return '${colStart.month}月';
      final prevColStart = rangeStart.add(Duration(days: (col - 1) * 7));
      if (colStart.month != prevColStart.month) return '${colStart.month}月';
      return '';
    }

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '训练活跃度',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '过去12周',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 热力图主体：星期标签 + 网格（LayoutBuilder 自适应宽度 + 横向滚动兜底）
          LayoutBuilder(
            builder: (context, constraints) {
              // 减去星期标签列(14) + 间距(6) = 20
              final availableWidth = constraints.maxWidth - 20;
              final cellSize =
                  ((availableWidth - 11 * spacing) / 12).clamp(18.0, 28.0);
              final gridWidth = 12 * cellSize + 11 * spacing;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 20 + gridWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 星期标签列
                      Column(
                        children: [
                          for (int r = 0; r < 7; r++) ...[
                            if (r > 0) const SizedBox(height: spacing),
                            SizedBox(
                              width: 14,
                              height: cellSize,
                              child: Center(
                                child: Text(
                                  weekdayLabel(r),
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: 6),
                      // 网格 + 月份标签
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 网格
                          Row(
                            children: [
                              for (int c = 0; c < 12; c++) ...[
                                if (c > 0) const SizedBox(width: spacing),
                                Column(
                                  children: [
                                    for (int r = 0; r < 7; r++) ...[
                                      if (r > 0) const SizedBox(height: spacing),
                                      Builder(builder: (_) {
                                        final date = rangeStart
                                            .add(Duration(days: c * 7 + r));
                                        // 未来日期渲染浅灰色背景
                                        if (date.isAfter(today)) {
                                          return Container(
                                            width: cellSize,
                                            height: cellSize,
                                            decoration: BoxDecoration(
                                              color: colors.borderColor.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(borderRadius),
                                            ),
                                          );
                                        }
                                        final key =
                                            '${date.year}-${date.month}-${date.day}';
                                        final count = _dailyCounts[key] ?? 0;
                                        return Container(
                                          width: cellSize,
                                          height: cellSize,
                                          decoration: BoxDecoration(
                                            color: colorForCount(count),
                                            borderRadius:
                                                BorderRadius.circular(borderRadius),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 月份标签（Stack 精确定位）
                          SizedBox(
                            height: 14,
                            width: gridWidth,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                for (int c = 0; c < 12; c++)
                                  if (monthLabel(c).isNotEmpty)
                                    Positioned(
                                      left: c * (cellSize + spacing),
                                      top: 0,
                                      child: Text(
                                        monthLabel(c),
                                        style: TextStyle(
                                          color: colors.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // 图例：少 → 多
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '少',
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
                const SizedBox(width: 4),
                for (int i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorForCount(i),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Text(
                  '多',
                  style: TextStyle(color: colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Frequency chart ──────────────────────────────────────────

  Widget _buildFrequencyChart(FitTrackColors colors) {
    final data = _showWeek ? _weekChartData : _monthChartData;
    final maxVal = data.fold(0, (max, d) {
      final v = (d['value'] as num?) ?? 0;
      return v > max ? v.toInt() : max;
    });
    final chartMax = maxVal > 0 ? maxVal : 1;

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(
            children: [
              _buildToggleBtn('周', _showWeek, () {
                setState(() => _showWeek = true);
              }, colors),
              const SizedBox(width: 8),
              _buildToggleBtn('月', !_showWeek, () {
                setState(() => _showWeek = false);
              }, colors),
            ],
          ),
          const SizedBox(height: 20),
          // Bar chart
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final value = (item['value'] as num?) ?? 0;
                final label = item['label'] as String? ?? '';
                final barHeight = (value / chartMax) * 120;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (value > 0)
                          Text(
                            '$value',
                            style: TextStyle(
                              color: colors.accentGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: value > 0 ? barHeight.clamp(4.0, 120.0) : 4,
                          decoration: BoxDecoration(
                            color: value > 0
                                ? colors.accentGlow
                                : colors.borderColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
      String text, bool active, VoidCallback onTap, FitTrackColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? colors.accentGlow.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? colors.accentGlow : colors.borderColor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? colors.accentGlow : colors.textMuted,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Muscle distribution ──────────────────────────────────────

  Widget _buildMuscleDistribution(FitTrackColors colors) {
    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.start,
        children: _muscleData.map((m) {
          final name = m['name'] as String;
          final pct = m['pct'] as int;
          final color = m['color'] as Color;

          return SizedBox(
            width: 80,
            child: Column(
              children: [
                // Circular indicator
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          value: pct / 100.0,
                          strokeWidth: 4,
                          backgroundColor: color.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Personal records ─────────────────────────────────────────

  Widget _buildPersonalRecords(FitTrackColors colors) {
    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _personalRecords.asMap().entries.map((entry) {
          final idx = entry.key;
          final pr = entry.value;
          final isLast = idx == _personalRecords.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? colors.warningColor.withOpacity(0.15)
                            : colors.bgSecondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: idx == 0
                                ? colors.warningColor
                                : colors.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pr['name'] as String,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if ((pr['date'] as String).isNotEmpty)
                            Text(
                              pr['date'] as String,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${(pr['weight'] as double).toStringAsFixed(1)}kg',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const DividerWidget(indent: 40),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── 训练容量趋势（柱状图）─────────────────────────────────────
  Widget _buildVolumeChart(FitTrackColors colors) {
    final weeklyStats = _computeWeeklyStats();
    final volumes = List.generate(6, (i) {
      final stat = weeklyStats[5 - i]!; // 倒序：最旧→最新
      return {
        'label': 'W${i + 1}',
        'value': (stat['totalVolume'] as double) / 1000, // 转换为 kg
      };
    });
    final maxVol = volumes.fold(0.0, (max, d) {
      final v = d['value'] as double;
      return v > max ? v : max;
    });
    final chartMax = maxVol > 0 ? maxVol : 1.0;

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('训练容量趋势',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('近6周总重量 (kg)',
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          if (maxVol == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('暂无训练数据',
                    style: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: volumes.map((item) {
                  final value = item['value'] as double;
                  final label = item['label'] as String;
                  final barHeight = (value / chartMax) * 100;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (value > 0)
                            Text(
                              '${value.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: colors.accentGlow,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: value > 0 ? barHeight.clamp(4.0, 100.0) : 4,
                            decoration: BoxDecoration(
                              color: value > 0
                                  ? colors.accentGlow
                                  : colors.borderColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(label,
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── 动作热度榜（水平条形图 Top 5）─────────────────────────────
  Widget _buildExercisePopularityChart(FitTrackColors colors) {
    final data = _computeExercisePopularity();
    if (data.isEmpty) return const SizedBox.shrink();
    final maxCount = data.first['count'] as int;

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('动作热度榜',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Top 5 训练次数',
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          ...data.map((item) {
            final name = item['name'] as String;
            final count = item['count'] as int;
            final barWidth = maxCount > 0 ? count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accentGlow,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(name,
                        style: TextStyle(
                            color: colors.textPrimary, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: barWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors.accentGlow,
                                  colors.accentGlow.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$count',
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 12)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 训练时长趋势（折线图）─────────────────────────────────────
  Widget _buildDurationTrendChart(FitTrackColors colors) {
    final weeklyStats = _computeWeeklyStats();
    final durations = List.generate(6, (i) {
      final stat = weeklyStats[5 - i]!;
      return {
        'label': 'W${i + 1}',
        'value': (stat['totalDuration'] as int) / 60, // 转换为小时
      };
    });
    final maxDur = durations.fold(0.0, (max, d) {
      final v = d['value'] as double;
      return v > max ? v : max;
    });
    if (maxDur == 0) return const SizedBox.shrink();

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('训练时长趋势',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('近6周总时长 (小时)',
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                data: durations,
                lineColor: colors.accentGlow,
                fillColor: colors.accentGlow.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PR 进度追踪（多折线图）─────────────────────────────────────
  Widget _buildPrProgressionChart(FitTrackColors colors) {
    final prData = _computePrProgression();
    if (prData.isEmpty) return const SizedBox.shrink();
    final colorsList = [colors.accentGlow, colors.successColor, colors.warningColor];

    return CardWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PR 进度追踪',
              style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('近6周最大重量 (kg)',
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _MultiLineChartPainter(
                data: prData,
                colors: colorsList,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 图例
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: prData.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final name = entry.value.key;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 3,
                    color: colorsList[idx % colorsList.length],
                  ),
                  const SizedBox(width: 4),
                  Text(name,
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final Color fillColor;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = data.fold(0.0, (max, d) {
      final v = d['value'] as double;
      return v > max ? v : max;
    });
    if (maxVal == 0) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1
          ? (size.width / (data.length - 1)) * i
          : size.width / 2;
      final v = data[i]['value'] as double;
      final y = size.height - (v / (maxVal * 1.2)) * size.height;
      points.add(Offset(x, y));
    }

    // 填充区域
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // 折线
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points) {
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // 数据点
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MultiLineChartPainter extends CustomPainter {
  final Map<String, List<Map<String, dynamic>>> data;
  final List<Color> colors;

  _MultiLineChartPainter({
    required this.data,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = <double>[];
    for (final entry in data.values) {
      for (final d in entry) {
        allValues.add(d['maxWeight'] as double);
      }
    }
    final maxVal = allValues.isEmpty ? 1.0 : allValues.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    int colorIdx = 0;
    for (final entry in data.entries) {
      final points = <Offset>[];
      final lineData = entry.value;
      for (int i = 0; i < lineData.length; i++) {
        final x = lineData.length > 1
            ? (size.width / (lineData.length - 1)) * i
            : size.width / 2;
        final v = lineData[i]['maxWeight'] as double;
        final y = size.height - (v / (maxVal * 1.2)) * size.height;
        points.add(Offset(x, y));
      }
      if (points.length < 2) continue;
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points) {
        linePath.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
          linePath,
          Paint()
            ..color = colors[colorIdx % colors.length]
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
      for (final p in points) {
        canvas.drawCircle(p, 3, Paint()..color = colors[colorIdx % colors.length]);
      }
      colorIdx++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
