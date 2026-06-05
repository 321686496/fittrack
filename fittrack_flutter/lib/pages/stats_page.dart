import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class StatsPage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const StatsPage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
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
    final totalTrainings = (_stats['totalTrainings'] as num?) ?? 0;
    final totalDuration = (_stats['totalDuration'] as num?) ?? 0;
    final totalWeight = (_stats['totalWeight'] as num?) ?? 0;
    final calories = (totalDuration.toInt() * 8); // ~8 cal/min estimate

    if (totalTrainings.toInt() == 0) {
      return Scaffold(
        body: Column(
          children: [
            PageHeader(
              onBack: () => widget.onNavigate('home'),
              title: '训练统计',
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.bar_chart_outlined,
                message: '暂无训练数据，完成训练后即可查看统计',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            onBack: () => widget.onNavigate('home'),
            title: '训练统计',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // ── Overview stats ───────────────────────────
                  const SectionHeader(title: '总览'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        icon: Icons.fitness_center,
                        value: '$totalTrainings',
                        label: '总训练',
                        color: colors.accentGlow,
                      ),
                      StatCard(
                        icon: Icons.timer_outlined,
                        value: _formatDuration(totalDuration.toInt()),
                        label: '总时长',
                        color: colors.infoColor,
                      ),
                      StatCard(
                        icon: Icons.monitor_weight_outlined,
                        value: _formatWeight(totalWeight.toInt()),
                        label: '总重量',
                        color: colors.warningColor,
                      ),
                      StatCard(
                        icon: Icons.local_fire_department,
                        value: '$calories',
                        label: '卡路里',
                        color: colors.successColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Training frequency chart ─────────────────
                  const SectionHeader(title: '训练频率'),
                  const SizedBox(height: 12),
                  _buildFrequencyChart(colors),
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
                ],
              ),
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
                            style: const TextStyle(
                              color: Colors.white,
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
}
