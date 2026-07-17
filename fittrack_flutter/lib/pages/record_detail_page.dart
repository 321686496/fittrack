import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';

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
    return '${d.year}年${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
      if (mounted) context.go('/records');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final record = _record;

    if (record == null || record.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bgSecondary,
        appBar: AppBar(
          backgroundColor: colors.bgSecondary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/records'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textMuted),
              const SizedBox(height: 16),
              Text('记录不存在或已删除',
                  style: TextStyle(color: colors.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/records'),
                child: const Text('返回记录页'),
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
    final exerciseNames = setRecords.keys.toList();

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      appBar: AppBar(
        backgroundColor: colors.bgSecondary,
        title: Text(
          '训练详情',
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/records'),
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
                          record['planName'] as String? ?? record['name'] as String? ?? '训练记录',
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
                          _formatDuration(record['duration']), '训练时长'),
                      _buildDetailStat(colors, Icons.fitness_center,
                          '${record['totalSets'] ?? 0}', '总组数'),
                      _buildDetailStat(colors, Icons.monitor_weight_outlined,
                          '${record['totalWeight'] ?? 0}kg', '总重量'),
                      _buildDetailStat(colors, Icons.sports_gymnastics,
                          '${record['exerciseCount'] ?? exerciseNames.length}', '动作数'),
                    ],
                  ),
                ],
              ),
            ),

            // 动作详情列表
            if (exerciseNames.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: '训练动作'),
              const SizedBox(height: 12),
              ...exerciseNames.map((exName) {
                final sets = setRecords[exName];
                return _buildExerciseDetailCard(colors, exName.toString(), sets);
              }),
            ],

            // 休息记录
            if (restLog.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionHeader(title: '休息记录'),
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
                    final after = logMap['after'] as String? ?? '';
                    final seconds = logMap['seconds'] as num?;
                    final skipped = logMap['skipped'] as bool? ?? false;
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
                              after.isNotEmpty ? after : '休息 ${idx + 1}',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13),
                            ),
                          ),
                          Text(
                            skipped ? '已跳过' : '${seconds ?? 0}秒',
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

  Widget _buildExerciseDetailCard(FitTrackColors colors, String exName, dynamic setsData) {
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
              border: Border(bottom: BorderSide(color: colors.borderColor)),
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
                  '${sets.length}组',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                            '× $reps次',
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
                '暂无组数据',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(FitTrackColors colors, IconData icon, String value, String label) {
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
