import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';

import '../l10n/i18n.dart';
class RecordDetailPage extends StatefulWidget {
  final String recordId;

  const RecordDetailPage({super.key, required this.recordId});

  @override
  State<RecordDetailPage> createState() => _RecordDetailPageState();
}

class _RecordDetailPageState extends State<RecordDetailPage> {
  Map<String, dynamic>? _record;

  @override
  void initState() {
    super.initState();
    _loadRecord();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadRecord();
  }

  void _loadRecord() {
    final records = Storage.getRecords();
    setState(() {
      _record = records.cast<Map<String, dynamic>>().firstWhere(
        (r) => r['id'] == widget.recordId,
        orElse: () => <String, dynamic>{},
      );
    });
  }

  String _formatDate(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return tr(context, '${d.year}年${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}');
  }

  String _formatDuration(dynamic minutes) {
    final m = (minutes as num?)?.toInt() ?? 0;
    if (m < 60) return tr(context, '$m分钟');
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? tr(context, '$h小时$rem分钟') : tr(context, '$h小时');
  }

  /// 三级反查动作名：自定义动作库 → 计划内嵌动作 → 内置动作
  Map<String, String> _buildExerciseNameLookup() {
    final lookup = <String, String>{};
    for (final ex in Storage.getCustomExercises()) {
      final id = ex['id']?.toString() ?? '';
      final name = ex['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
    }
    for (final plan in Storage.getPlans()) {
      final days = plan['days'] as List? ?? [];
      for (final day in days) {
        final exercises = (day as Map)['exercises'] as List? ?? [];
        for (final ex in exercises) {
          final id = ex['id']?.toString() ?? '';
          final name = ex['name']?.toString() ?? '';
          if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
        }
      }
    }
    for (final ex in MockData.exercises) {
      final id = ex['id']?.toString() ?? '';
      final name = ex['name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) lookup[id] = name;
    }
    return lookup;
  }

  void _deleteRecord(String recordId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: tr(context, '确认删除'),
      content: tr(context, '确定要删除这条训练记录吗？此操作不可恢复。'),
      confirmText: tr(context, '删除'),
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed == true) {
      Storage.deleteRecord(recordId);
      // 返回来源页（列表页会自动刷新，首页也会刷新）
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final record = _record;

    if (record == null || record.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bgSecondary,
        appBar: AppBar(
          backgroundColor: colors.bgSecondary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(tr(context, '记录不存在或已删除'),
                  style: TextStyle(color: colors.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(tr(context, '返回')),
              ),
            ],
          ),
        ),
      );
    }

    final timestamp = record['date'] as int? ??
        record['createTime'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final muscles = (record['muscles'] as List?)?.cast<String>() ?? [];
    final setRecords = record['setRecords'] as Map? ?? {};
    final restLog = record['restLog'] as List? ?? [];
    final pureDuration = record['pureDuration'] as num?;
    // setRecords 的 key 是动作 id，需要解析成动作名展示
    final exLookup = _buildExerciseNameLookup();
    final exerciseNames = setRecords.keys
        .map((k) => exLookup[k.toString()] ?? tr(context, '未知动作'))
        .toList();

    // 容量分析数据（仅含有实际组数的动作）
    final volumeData = <Map<String, dynamic>>[];
    for (final entry in setRecords.entries) {
      // 值可能非 List（历史/导入的畸形数据），类型不匹配时按无组数据处理
      final setsList = entry.value is List ? entry.value as List : [];
      if (setsList.isEmpty) continue;
      double vol = 0;
      for (final s in setsList) {
        if (s is Map) {
          vol += ((s['weight'] as num?) ?? 0).toDouble() *
              ((s['reps'] as num?) ?? 0).toDouble();
        }
      }
      volumeData.add({
        'name': exLookup[entry.key.toString()] ?? tr(context, '未知动作'),
        'volume': vol,
      });
    }

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      appBar: AppBar(
        backgroundColor: colors.bgSecondary,
        title: Text(
          tr(context, '训练详情'),
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 训练概要卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record['planName'] as String? ?? record['name'] as String? ?? tr(context, '训练记录'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteRecord(record['id'] as String),
                        child: Icon(Icons.delete_outline, size: 20, color: colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(timestamp),
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                  if (muscles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: muscles.map<Widget>((m) {
                        return BadgeWidget(text: m, variant: BadgeVariant.purple);
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStat(colors, Icons.timer_outlined,
                          _formatDuration(record['duration']), tr(context, '训练时长')),
                      _buildDetailStat(colors, Icons.fitness_center,
                          '${record['totalSets'] ?? 0}', tr(context, '总组数')),
                      _buildDetailStat(colors, Icons.monitor_weight_outlined,
                          '${record['totalWeight'] ?? 0}kg', tr(context, '总重量')),
                      _buildDetailStat(colors, Icons.sports_gymnastics,
                          '${record['exerciseCount'] ?? exerciseNames.length}', tr(context, '动作数')),
                      if (pureDuration != null && pureDuration > 0)
                        _buildDetailStat(colors, Icons.timer,
                            '${(pureDuration.toInt() / 60).round()}min', tr(context, '纯训练')),
                    ],
                  ),
                ],
              ),
            ),

            // 容量分析图表
            if (volumeData.length > 1) ...[
              const SizedBox(height: 20),
              _buildVolumeChartCard(colors, volumeData),
            ],

            // 动作详情列表
            if (exerciseNames.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: tr(context, '训练动作')),
              const SizedBox(height: 12),
              ...setRecords.entries.map((entry) {
                final exId = entry.key.toString();
                final exName = exLookup[exId] ?? tr(context, '未知动作');
                return _buildExerciseDetailCard(colors, exName, entry.value);
              }),
            ],

            // 休息记录
            if (restLog.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: tr(context, '休息记录')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  children: restLog.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final log = entry.value;
                    final logMap = log is Map<String, dynamic> ? log : <String, dynamic>{};
                    // 新格式字段，fallback 兼容旧数据
                    final exercise = logMap['exercise'] as String? ?? '';
                    final actual = (logMap['actualRestSeconds'] as num?)?.toInt()
                                ?? (logMap['actualTime'] as num?)?.toInt() ?? 0;
                    final reason = logMap['restEndReason'] as String? ?? 'manual';
                    final skipped = reason == 'skip';
                    return Padding(
                      padding: EdgeInsets.only(bottom: idx < restLog.length - 1 ? 8 : 0),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: skipped ? colors.warningColor : colors.successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              exercise.isNotEmpty ? exercise : tr(context, '休息 ${idx + 1}'),
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Text(
                            skipped ? tr(context, '已跳过') : tr(context, '$actual秒'),
                            style: TextStyle(
                              color: skipped ? colors.warningColor : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailCard(LiftTrackColors colors, String exName, dynamic setsData) {
    final sets = <Map<String, dynamic>>[];
    if (setsData is List) {
      for (final s in setsData) {
        if (s is Map<String, dynamic>) {
          sets.add(s);
        } else if (s is Map) {
          sets.add(Map<String, dynamic>.from(s));
        }
      }
    }

    // 汇总统计：总容量 / 最重组 / 总次数
    double totalVolume = 0;
    int totalReps = 0;
    double bestWeight = 0;
    int bestReps = 0;
    for (final s in sets) {
      final w = (s['weight'] as num?)?.toDouble() ?? 0;
      final r = (s['reps'] as num?)?.toInt() ?? 0;
      totalVolume += w * r;
      totalReps += r;
      if (w > bestWeight || (w == bestWeight && r > bestReps)) {
        bestWeight = w;
        bestReps = r;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.fitness_center, size: 16, color: colors.accentGlow),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    exName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  tr(context, '${sets.length}组'),
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.borderColor),
          if (sets.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: colors.borderColor.withOpacity(0.5)),
                ),
              ),
              child: Row(
                children: [
                  _buildSummaryStat(
                      colors, tr(context, '总容量'), '${_fmtKg(totalVolume)}kg'),
                  _buildSummaryDivider(colors),
                  _buildSummaryStat(
                      colors, tr(context, '最重组'), '${_fmtKg(bestWeight)}kg×$bestReps'),
                  _buildSummaryDivider(colors),
                  _buildSummaryStat(colors, tr(context, '总次数'), tr(context, '$totalReps次')),
                ],
              ),
            ),
          if (sets.isNotEmpty)
            ...sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              final weight = (set['weight'] as num?)?.toDouble() ?? 0;
              final reps = (set['reps'] as num?)?.toInt() ?? 0;
              final rest = set['rest'] as num?;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: idx < sets.length - 1
                        ? BorderSide(color: colors.borderColor.withOpacity(0.5))
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.accentGlow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: colors.accentGlow,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.monitor_weight_outlined, size: 14, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${weight}kg',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, '× $reps次'),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rest != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.infoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: colors.infoColor),
                            const SizedBox(width: 3),
                            Text(
                              '${rest}s',
                              style: TextStyle(
                                color: colors.infoColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                tr(context, '暂无组数据'),
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  /// 数值格式化：整数不带小数点，小数保留 1 位
  String _fmtKg(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildSummaryStat(
      LiftTrackColors colors, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider(LiftTrackColors colors) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.borderColor.withOpacity(0.6),
    );
  }

  Widget _buildVolumeChartCard(
      LiftTrackColors colors, List<Map<String, dynamic>> data) {
    final totalVolume = data.fold<double>(
        0, (sum, e) => sum + ((e['volume'] as num?) ?? 0).toDouble());
    final maxVol = data
        .map((e) => ((e['volume'] as num?) ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < data.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: ((data[i]['volume'] as num?) ?? 0).toDouble(),
            color: colors.accentGlow,
            width: 18,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SectionHeader(title: tr(context, '容量分析'))),
              Text(
                tr(context, '合计 ${_fmtKg(totalVolume)}kg'),
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVol <= 0 ? 1 : maxVol * 1.15,
              minY: 0,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: colors.borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIdx, rod, rodIdx) =>
                      BarTooltipItem(
                    '${data[groupIdx]['name']}\n${_fmtKg(rod.toY)}kg',
                    TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: maxVol > 0 ? maxVol / 3 : 1,
                    getTitlesWidget: (v, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        _fmtKg(v),
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final name = data[idx]['name'].toString();
                      final label =
                          name.length > 4 ? '${name.substring(0, 4)}…' : name;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(LiftTrackColors colors, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: colors.accentGlow),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
