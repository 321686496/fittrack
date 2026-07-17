import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

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

    if (recordDay == today) return '今天';
    if (recordDay == yesterday) return '昨天';

    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (recordDay.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
      return '本周';
    }

    return '更早';
  }

  Map<String, List<Map<String, dynamic>>> _groupRecords() {
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = ['今天', '昨天', '本周', '更早'];

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
    return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(dynamic minutes) {
    final m = (minutes as num?)?.toInt() ?? 0;
    if (m < 60) return '${m}分钟';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}小时${rem}分钟' : '${h}小时';
  }

  void _deleteRecord(String recordId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '确认删除',
      content: '确定要删除这条训练记录吗？此操作不可恢复。',
      confirmText: '删除',
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
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    // 列表视图
    final grouped = _groupRecords();

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '训练记录',
            isTabPage: false,
            onBack: () => context.pop(),
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
                            '暂无训练记录',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '你的训练记录将显示在这里，包括每个动作的组数、重量和时长',
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
                              BadgeWidget(text: '训练详情'),
                              const SizedBox(width: 8),
                              BadgeWidget(
                                  text: '重量追踪',
                                  variant: BadgeVariant.info),
                              const SizedBox(width: 8),
                              BadgeWidget(
                                  text: '时长统计',
                                  variant: BadgeVariant.success),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.push('/plan'),
                              child: const Text('开始训练'),
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

  Widget _buildRecordCard(FitTrackColors colors, Map<String, dynamic> record) {
    final recordId = record['id'] as String? ?? '';
    final timestamp = record['date'] as int? ??
        record['createTime'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final muscles = (record['muscles'] as List?)?.cast<String>() ?? [];

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
                  record['planName'] as String? ?? record['name'] as String? ?? '训练记录',
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
          Row(
            children: [
              _buildStatItem(colors, Icons.timer_outlined,
                  _formatDuration(record['duration']), '时长'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.fitness_center,
                  '${record['totalSets'] ?? 0}', '组数'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.monitor_weight_outlined,
                  '${record['totalWeight'] ?? 0}kg', '重量'),
            ],
          ),
          const SizedBox(height: 6),
          // 点击查看详情提示
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '查看详情',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: colors.accentGlow),
              ],
            ),
          ),
        ],
      ),
    );
}

  Widget _buildStatItem(
      FitTrackColors colors, IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.accentGlow),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
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
