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
  String? _detailRecordId;

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

    // 详情视图
    if (_detailRecordId != null) {
      final record = _records.firstWhere(
        (r) => r['id'] == _detailRecordId,
        orElse: () => <String, dynamic>{},
      );
      if (record.isNotEmpty) {
        return _buildDetailView(colors, record);
      }
    }

    // 列表视图
    final grouped = _groupRecords();

    return Column(
      children: [
        PageHeader(
          title: '训练记录',
          isTabPage: true,
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
        setState(() {
          _detailRecordId = recordId;
        });
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

  // ── 详情视图 ──────────────────────────────────────────────────

  Widget _buildDetailView(FitTrackColors colors, Map<String, dynamic> record) {
    final recordId = record['id'] as String? ?? '';
    final timestamp = record['date'] as int? ??
        record['createTime'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final muscles = (record['muscles'] as List?)?.cast<String>() ?? [];
    final setRecords = record['setRecords'] as Map? ?? {};
    final restLog = record['restLog'] as List? ?? [];

    // 从 setRecords 中提取动作列表
    final exerciseNames = setRecords.keys.toList();

    return Column(
      children: [
        PageHeader(
          onBack: () => setState(() => _detailRecordId = null),
          title: '训练详情',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                            onTap: () {
                              setState(() => _detailRecordId = null);
                              _deleteRecord(recordId);
                            },
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
                          _buildDetailStat(colors, Icons.timer_outlined, _formatDuration(record['duration']), '训练时长'),
                          _buildDetailStat(colors, Icons.fitness_center, '${record['totalSets'] ?? 0}', '总组数'),
                          _buildDetailStat(colors, Icons.monitor_weight_outlined, '${record['totalWeight'] ?? 0}kg', '总重量'),
                          _buildDetailStat(colors, Icons.sports_gymnastics, '${record['exerciseCount'] ?? exerciseNames.length}', '动作数'),
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

                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ],
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
          // 动作名头部
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
          // 每组详情
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
                    // 组号
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
                    // 重量
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
                    // 休息时间
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
