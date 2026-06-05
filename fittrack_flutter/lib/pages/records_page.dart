import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class RecordsPage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const RecordsPage({super.key, required this.onNavigate});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  List<Map<String, dynamic>> _records = [];
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
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

    // Check if within this week (Mon-Sun)
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

    // Sort by group order
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

  void _deleteRecord(String recordId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(context).extension<FitTrackColors>()!;
        return AlertDialog(
          backgroundColor: colors.bgCard,
          title: const Text('确认删除', style: TextStyle(color: Colors.white)),
          content: const Text(
            '确定要删除这条训练记录吗？此操作不可恢复。',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Storage.deleteRecord(recordId);
                Navigator.pop(ctx);
                _loadRecords();
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final grouped = _groupRecords();

    return Column(
      children: [
        PageHeader(
          onBack: () => widget.onNavigate('profile'),
          title: '训练记录',
        ),
        Expanded(
          child: _records.isEmpty
              ? EmptyState(
                  icon: Icons.history,
                  message: '暂无训练记录',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: grouped.entries.map((entry) {
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
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(FitTrackColors colors, Map<String, dynamic> record) {
    final recordId = record['id'] as String? ?? '';
    final isExpanded = _expandedIds.contains(recordId);
    final timestamp = record['date'] as int? ??
        record['createTime'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final muscles = (record['muscles'] as List?)?.cast<String>() ?? [];
    final exercises = (record['exercises'] as List?) ?? [];

    return CardWidget(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIds.remove(recordId);
          } else {
            _expandedIds.add(recordId);
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: plan name + delete
          Row(
            children: [
              Expanded(
                child: Text(
                  record['planName'] as String? ?? record['name'] as String? ?? '训练记录',
                  style: const TextStyle(
                    color: Colors.white,
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
          // Muscle badges
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
          // Stats row
          Row(
            children: [
              _buildStatItem(colors, Icons.timer_outlined,
                  '${record['duration'] ?? 0}min', '时长'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.fitness_center,
                  '${record['totalSets'] ?? 0}', '组数'),
              const SizedBox(width: 16),
              _buildStatItem(colors, Icons.monitor_weight_outlined,
                  '${record['totalWeight'] ?? 0}kg', '重量'),
            ],
          ),
          // Expand indicator
          if (exercises.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                  color: colors.textMuted,
                ),
              ),
            ),
          // Expanded detail
          if (isExpanded && exercises.isNotEmpty) ...[
            const SizedBox(height: 8),
            DividerWidget(),
            const SizedBox(height: 8),
            ...exercises.map((ex) {
              final exMap = ex as Map<String, dynamic>;
              final sets = exMap['sets'] as List? ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exMap['name'] as String? ?? '',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (sets.isNotEmpty)
                      ...sets.map((s) {
                        final set = s as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Row(
                            children: [
                              Text(
                                '第${set['set'] ?? '?'}组',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${set['weight'] ?? 0}kg × ${set['reps'] ?? 0}',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              if (set['rest'] != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '休息${set['rest']}s',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      })
                    else
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${exMap['sets'] ?? 0}组 × ${exMap['reps'] ?? '-'}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
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
          style: const TextStyle(
            color: Colors.white,
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
