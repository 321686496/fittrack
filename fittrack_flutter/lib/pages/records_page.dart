import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

import '../l10n/i18n.dart';
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadRecords();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _records = Storage.getRecords();
    });
  }

  String _getGroupLabel(DateTime recordDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDay = DateTime(recordDate.year, recordDate.month, recordDate.day);

    if (recordDay == today) return tr(context, '今天');
    if (recordDay == yesterday) return tr(context, '昨天');

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (recordDay.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
      return tr(context, '本周');
    }

    return tr(context, '更早');
  }

  Map<String, List<Map<String, dynamic>>> _groupRecords() {
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = [tr(context, '今天'), tr(context, '昨天'), tr(context, '本周'), tr(context, '更早')];

    for (final record in _records) {
      final timestamp = record['date'] as int? ??
          record['createTime'] as int? ??
          DateTime.now().millisecondsSinceEpoch;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final label = _getGroupLabel(date);
      groups.putIfAbsent(label, () => []).add(record);
    }

    final sorted = <String, List<Map<String, dynamic>>>{};
    for (final key in order) {
      if (groups.containsKey(key)) {
        sorted[key] = groups[key]!;
      }
    }
    return sorted;
  }

  String _formatDate(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return tr(context, '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}');
  }

  String _formatDuration(dynamic minutes) {
    final m = (minutes as num?)?.toInt() ?? 0;
    if (m < 60) return tr(context, '$m分钟');
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? tr(context, '$h小时$rem分钟') : tr(context, '$h小时');
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
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    // 列表视图
    final grouped = _groupRecords();

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: tr(context, '训练记录'),
            isTabPage: false,
            onBack: () {
              // 正常 pop 回来源页；若栈内无上级页面则回到首页
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          Expanded(
          child: _records.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CardWidget(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_outlined,
                              size: 48, color: colors.accentGlow),
                          const SizedBox(height: 16),
                          Text(
                            tr(context, '暂无训练记录'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(context, '你的训练记录将显示在这里，包括每个动作的组数、重量和时长'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 功能亮点标签
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BadgeWidget(text: tr(context, '训练详情')),
                              const SizedBox(width: 8),
                              BadgeWidget(
                                  text: tr(context, '重量追踪'),
                                  variant: BadgeVariant.info),
                              const SizedBox(width: 8),
                              BadgeWidget(
                                  text: tr(context, '时长统计'),
                                  variant: BadgeVariant.success),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.go('/plan'),
                              child: Text(tr(context, '开始训练')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...grouped.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, top: 8),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...entry.value.map((record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildRecordCard(colors, record),
                                )),
                          ],
                        );
                      }),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
        ),
      ],
      ),
    );
  }

  Widget _buildRecordCard(LiftTrackColors colors, Map<String, dynamic> record) {
    final recordId = record['id'] as String? ?? '';
    final timestamp = record['date'] as int? ??
        record['createTime'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final muscles = (record['muscles'] as List?)?.cast<String>() ?? [];
    final setRecords = record['setRecords'] as Map? ?? {};
    final exerciseCount = record['exerciseCount'] as int? ?? setRecords.length;

    return CardWidget(
      onTap: () {
        context.push('/records/$recordId');
      },
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _deleteRecord(recordId),
                child: Icon(Icons.delete_outline,
                    size: 20, color: colors.textMuted),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(timestamp),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
            ),
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
          const SizedBox(height: 10),
          _buildStatsGrid(colors, record, exerciseCount),
        ],
      ),
    );
}

  Widget _buildStatsGrid(
      LiftTrackColors colors, Map<String, dynamic> record, int exerciseCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgSecondary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCell(colors, Icons.timer_outlined,
                  _formatDuration(record['duration']), tr(context, '时长')),
              _buildGridDivider(colors),
              _buildStatCell(colors, Icons.fitness_center,
                  '${record['totalSets'] ?? 0}', tr(context, '组数')),
            ],
          ),
          Container(height: 1, color: colors.borderColor.withOpacity(0.6)),
          Row(
            children: [
              _buildStatCell(colors, Icons.monitor_weight_outlined,
                  '${record['totalWeight'] ?? 0}kg', tr(context, '重量')),
              _buildGridDivider(colors),
              _buildStatCell(colors, Icons.sports_gymnastics,
                  '$exerciseCount', tr(context, '动作数')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell(
      LiftTrackColors colors, IconData icon, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.accentGlow),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(label,
                    style:
                        TextStyle(color: colors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridDivider(LiftTrackColors colors) {
    return Container(
      width: 1,
      height: 36,
      color: colors.borderColor.withOpacity(0.6),
    );
  }
}
