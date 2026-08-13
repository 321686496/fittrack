import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 健身卡统计页
class GymCardStatsPage extends StatefulWidget {
  const GymCardStatsPage({super.key});

  @override
  State<GymCardStatsPage> createState() => _GymCardStatsPageState();
}

class _GymCardStatsPageState extends State<GymCardStatsPage> {
  List<Map<String, dynamic>> _cards = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final cards = Storage.getGymCards();
    setState(() {
      _cards = cards;
      _loaded = true;
    });
  }

  // ── 状态判定（独立实现，参考 gym_card_page 思路） ──────────────
  String _getCardStatus(Map<String, dynamic> card) {
    final now = DateTime.now();
    final endDate = card['endDate'] as int? ?? 0;
    final remainingCount = card['remainingCount'] as int? ?? -1;
    final cardType = card['cardType'] as String? ?? '';

    // 次卡：根据剩余次数判断
    if (cardType == '次卡' && remainingCount >= 0) {
      if (remainingCount == 0) return 'used_up';
      if (remainingCount <= 3) return 'low_count';
      return 'active';
    }

    // 期限卡：根据到期日期判断
    if (endDate > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final diff = end.difference(now).inDays;
      if (diff < 0) return 'expired';
      if (diff == 0) return 'expiring_today';
      if (diff <= 7) return 'expiring_soon';
      return 'active'; // normal/active 统一视为活跃
    }
    return 'unknown';
  }

  /// 已投入金额：期限卡按 (now-startDate) 天数分摊 price，次卡按已用次数分摊
  double _calcAllocatedAmount(Map<String, dynamic> card) {
    final price = (card['price'] as num?)?.toDouble() ?? 0;
    final startDate = card['startDate'] as int? ?? 0;
    final endDate = card['endDate'] as int? ?? 0;
    final cardType = card['cardType'] as String? ?? '';
    final totalCount = card['totalCount'] as int? ?? -1;
    final remainingCount = card['remainingCount'] as int? ?? -1;

    if (price <= 0) return 0;

    // 次卡：按已用次数分摊
    if (cardType == '次卡' && totalCount > 0) {
      final used = totalCount - (remainingCount >= 0 ? remainingCount : 0);
      return price * (used / totalCount);
    }

    // 期限卡：按已用天数分摊
    if (startDate > 0 && endDate > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final now = DateTime.now();
      final totalDays = end.difference(start).inDays;
      if (totalDays > 0) {
        int elapsed = now.difference(start).inDays;
        if (elapsed < 0) elapsed = 0;
        if (elapsed > totalDays) elapsed = totalDays;
        return price * (elapsed / totalDays);
      }
    }
    return 0;
  }

  /// 期限卡已用天数（用于日均成本计算）
  int _calcElapsedDays(Map<String, dynamic> card) {
    final startDate = card['startDate'] as int? ?? 0;
    final endDate = card['endDate'] as int? ?? 0;
    final cardType = card['cardType'] as String? ?? '';
    if (cardType == '次卡') return 0;
    if (startDate > 0 && endDate > 0) {
      final start = DateTime.fromMillisecondsSinceEpoch(startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final now = DateTime.now();
      final totalDays = end.difference(start).inDays;
      if (totalDays > 0) {
        int elapsed = now.difference(start).inDays;
        if (elapsed < 0) elapsed = 0;
        if (elapsed > totalDays) elapsed = totalDays;
        return elapsed;
      }
    }
    return 0;
  }

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return '未设置';
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatMonth(int timestamp) {
    if (timestamp <= 0) return '未设置';
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}';
  }

  String _formatMoney(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }

  // ── 统计聚合 ──────────────────────────────────────────────
  Map<String, int> _groupCount(String Function(Map<String, dynamic>) keyFn) {
    final m = <String, int>{};
    for (final c in _cards) {
      final k = keyFn(c);
      if (k.isEmpty) continue;
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '健身卡统计',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: !_loaded
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                    ? const EmptyState(
                        icon: Icons.credit_card_outlined,
                        message: '暂无健身卡数据',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _loadStats(),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          children: [
                            _buildOverviewSection(colors),
                            const SizedBox(height: 16),
                            _buildTypeDistributionSection(colors),
                            const SizedBox(height: 16),
                            _buildInvestmentSection(colors),
                            const SizedBox(height: 16),
                            _buildGymDistributionSection(colors),
                            const SizedBox(height: 16),
                            _buildTimeDistributionSection(colors),
                            const SizedBox(height: 16),
                            _buildCountCardUsageSection(colors),
                            const SizedBox(height: 16),
                            _buildExpiringListSection(colors),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── 区块 1：总览卡 ────────────────────────────────────────
  Widget _buildOverviewSection(LiftTrackColors colors) {
    int active = 0;
    int expired = 0;
    int expiring7 = 0;
    for (final c in _cards) {
      final s = _getCardStatus(c);
      if (s == 'active') {
        active++;
      } else if (s == 'expired') {
        expired++;
      } else if (s == 'expiring_today' || s == 'expiring_soon') {
        expiring7++;
      }
    }

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '总览'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.credit_card,
                  value: '${_cards.length}',
                  label: '总卡数',
                  color: colors.accentGlow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  icon: Icons.check_circle_outline,
                  value: '$active',
                  label: '活跃',
                  color: colors.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.error_outline,
                  value: '$expired',
                  label: '已过期',
                  color: colors.warningColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                  icon: Icons.alarm_on,
                  value: '$expiring7',
                  label: '即将到期7天内',
                  color: colors.infoColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 区块 2：卡类型分布（饼图） ────────────────────────────
  Widget _buildTypeDistributionSection(LiftTrackColors colors) {
    final typeCounts = _groupCount((c) => (c['cardType'] as String? ?? '').trim());
    // 类型 -> 颜色 映射
    final typeColorMap = <String, Color>{
      '年卡': colors.accentGlow,
      '季卡': colors.accentSecondary,
      '月卡': colors.successColor,
      '次卡': colors.warningColor,
    };
    final otherColor = colors.infoColor;

    final orderedTypes = <String>['年卡', '季卡', '月卡', '次卡'];
    final presentTypes = <String>[
      ...orderedTypes.where((t) => typeCounts.containsKey(t)),
      ...typeCounts.keys.where((t) => !orderedTypes.contains(t)),
    ];

    final total = _cards.length;
    final sections = <PieChartSectionData>[];
    for (final t in presentTypes) {
      final count = typeCounts[t] ?? 0;
      if (count == 0) continue;
      final color = typeColorMap[t] ?? otherColor;
      sections.add(PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '$count',
        radius: 54,
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '卡类型分布'),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: presentTypes.isEmpty
                ? Center(
                    child: Text('暂无数据',
                        style:
                            TextStyle(color: colors.textMuted, fontSize: 13)))
                : Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: sections,
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: presentTypes.map((t) {
                            final count = typeCounts[t] ?? 0;
                            final pct =
                                total > 0 ? (count / total * 100) : 0.0;
                            final color = typeColorMap[t] ?? otherColor;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$t $count张',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── 区块 3：投入分析 ──────────────────────────────────────
  Widget _buildInvestmentSection(LiftTrackColors colors) {
    double totalAmount = 0;
    double allocatedTotal = 0;
    int totalUsedDays = 0;
    final typeAmount = <String, double>{};

    for (final c in _cards) {
      final price = (c['price'] as num?)?.toDouble() ?? 0;
      totalAmount += price;
      allocatedTotal += _calcAllocatedAmount(c);
      totalUsedDays += _calcElapsedDays(c);
      final t = (c['cardType'] as String? ?? '其他').trim().isEmpty
          ? '其他'
          : (c['cardType'] as String? ?? '其他').trim();
      typeAmount[t] = (typeAmount[t] ?? 0) + price;
    }

    final dailyAvg = totalUsedDays > 0 ? allocatedTotal / totalUsedDays : 0.0;

    final sortedTypes = typeAmount.keys.toList()
      ..sort((a, b) => typeAmount[b]!.compareTo(typeAmount[a]!));
    final maxAmount = sortedTypes.isEmpty
        ? 1.0
        : typeAmount.values.reduce((a, b) => a > b ? a : b);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '投入分析'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _moneyBlock(colors, '总金额', totalAmount,
                    colors.accentGlow, Icons.account_balance_wallet),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyBlock(colors, '已投入', allocatedTotal,
                    colors.successColor, Icons.trending_up),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _moneyBlock(colors, '日均成本', dailyAvg,
                    colors.infoColor, Icons.calendar_today),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('按卡类型金额汇总',
              style:
                  TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          if (sortedTypes.isEmpty)
            Text('暂无数据',
                style: TextStyle(color: colors.textMuted, fontSize: 12))
          else
            ...sortedTypes.map((t) {
              final amt = typeAmount[t] ?? 0;
              final ratio = maxAmount > 0 ? amt / maxAmount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 13)),
                        Text('${_formatMoney(amt)}元',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ProgressBar(
                      progress: ratio.clamp(0.0, 1.0),
                      fillColor: colors.accentSecondary,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _moneyBlock(LiftTrackColors colors, String label, double value,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            '${_formatMoney(value)}元',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // ── 区块 4：健身房分布（柱状图） ──────────────────────────
  Widget _buildGymDistributionSection(LiftTrackColors colors) {
    final gymCounts = _groupCount((c) => (c['gymName'] as String? ?? '').trim());
    final gyms = gymCounts.keys.toList()
      ..sort((a, b) => gymCounts[b]!.compareTo(gymCounts[a]!));
    final maxCount = gyms.isEmpty ? 1.0 : gymCounts.values.reduce((a, b) => a > b ? a : b).toDouble();

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < gyms.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: gymCounts[gyms[i]]!.toDouble(),
            color: colors.accentGlow,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '健身房分布'),
          const SizedBox(height: 16),
          if (gyms.isEmpty)
            Text('暂无数据',
                style: TextStyle(color: colors.textMuted, fontSize: 13))
          else
            SizedBox(
              height: 220,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount + 1).ceilToDouble(),
                minY: 0,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: colors.borderColor, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        if (v % 1 != 0 || v < 0) return const SizedBox.shrink();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${v.toInt()}',
                              style: TextStyle(
                                  color: colors.textSecondary, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= gyms.length) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          angle: -0.6,
                          child: Text(
                            gyms[idx],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  // ── 区块 5：时间分布（开卡/到期月份柱状图） ────────────────
  Widget _buildTimeDistributionSection(LiftTrackColors colors) {
    final startMonths = <String, int>{};
    final endMonths = <String, int>{};
    for (final c in _cards) {
      final s = c['startDate'] as int? ?? 0;
      if (s > 0) {
        final m = _formatMonth(s);
        startMonths[m] = (startMonths[m] ?? 0) + 1;
      }
      final e = c['endDate'] as int? ?? 0;
      if (e > 0) {
        final m = _formatMonth(e);
        endMonths[m] = (endMonths[m] ?? 0) + 1;
      }
    }
    final startKeys = startMonths.keys.toList()..sort();
    final endKeys = endMonths.keys.toList()..sort();

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '时间分布'),
          const SizedBox(height: 16),
          _monthBarChart(colors, '开卡月份', startMonths, startKeys,
              colors.accentGlow),
          const SizedBox(height: 20),
          _monthBarChart(colors, '到期月份', endMonths, endKeys,
              colors.accentSecondary),
        ],
      ),
    );
  }

  Widget _monthBarChart(LiftTrackColors colors, String title,
      Map<String, int> months, List<String> keys, Color barColor) {
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < keys.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: months[keys[i]]!.toDouble(),
            color: barColor,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      ));
    }
    final maxV = keys.isEmpty
        ? 1.0
        : months.values.reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        if (keys.isEmpty)
          Text('暂无数据',
              style: TextStyle(color: colors.textMuted, fontSize: 12))
        else
          SizedBox(
            height: 160,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (maxV + 1).ceilToDouble(),
              minY: 0,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: colors.borderColor, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      if (v % 1 != 0 || v < 0) return const SizedBox.shrink();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text('${v.toInt()}',
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 10)),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= keys.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        angle: -0.6,
                        child: Text(
                          keys[idx].substring(keys[idx].length >= 5 ? 2 : 0),
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
            )),
          ),
      ],
    );
  }

  // ── 区块 6：次卡使用率 ────────────────────────────────────
  Widget _buildCountCardUsageSection(LiftTrackColors colors) {
    int totalCountSum = 0;
    int usedCountSum = 0;
    int remainingSum = 0;
    final countCards = _cards.where((c) => (c['cardType'] as String? ?? '') == '次卡').toList();

    for (final c in countCards) {
      final total = c['totalCount'] as int? ?? 0;
      final remaining = c['remainingCount'] as int? ?? 0;
      final used = total - (remaining >= 0 ? remaining : 0);
      totalCountSum += total;
      usedCountSum += used > 0 ? used : 0;
      remainingSum += remaining >= 0 ? remaining : 0;
    }

    final usage = totalCountSum > 0 ? usedCountSum / totalCountSum : 0.0;

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '次卡使用率'),
          const SizedBox(height: 14),
          if (countCards.isEmpty)
            Text('暂无次卡',
                style: TextStyle(color: colors.textMuted, fontSize: 13))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _usageBlock(colors, '总次数', '$totalCountSum',
                          colors.accentGlow),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _usageBlock(colors, '已用次数', '$usedCountSum',
                          colors.warningColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _usageBlock(colors, '剩余次数', '$remainingSum',
                          colors.successColor),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('总体使用率',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 13)),
                    Text('${(usage * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: colors.accentGlow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ProgressBar(
                  progress: usage.clamp(0.0, 1.0),
                  fillColor: colors.warningColor,
                  height: 8,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _usageBlock(LiftTrackColors colors, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: colors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  // ── 区块 7：即将到期列表（未来30天到期） ──────────────────
  Widget _buildExpiringListSection(LiftTrackColors colors) {
    final now = DateTime.now();
    final expiring = <Map<String, dynamic>>[];
    for (final c in _cards) {
      final endDate = c['endDate'] as int? ?? 0;
      if (endDate <= 0) continue;
      final end = DateTime.fromMillisecondsSinceEpoch(endDate);
      final diff = end.difference(now).inDays;
      if (diff >= 0 && diff <= 30) {
        expiring.add({...c, '_diff': diff});
      }
    }
    expiring.sort((a, b) => (a['_diff'] as int).compareTo(b['_diff'] as int));

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: '即将到期（未来30天）'),
          const SizedBox(height: 12),
          if (expiring.isEmpty)
            Text('暂无即将到期的健身卡',
                style: TextStyle(color: colors.textMuted, fontSize: 13))
          else
            ...expiring.map((c) {
              final diff = c['_diff'] as int;
              final isUrgent = diff <= 7;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isUrgent
                          ? colors.warningColor.withOpacity(0.5)
                          : colors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['name']?.toString() ?? '未命名',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c['gymName']?.toString() ?? '未知健身房'} · 到期 ${_formatDate(c['endDate'] as int? ?? 0)}',
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isUrgent
                                ? colors.warningColor
                                : colors.infoColor)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        diff == 0 ? '今天到期' : '剩$diff天',
                        style: TextStyle(
                          color: isUrgent
                              ? colors.warningColor
                              : colors.infoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
