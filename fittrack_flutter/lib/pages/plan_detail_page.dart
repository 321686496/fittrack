import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/exercise_set_table.dart';

class PlanDetailPage extends StatefulWidget {
  final String planId;

  const PlanDetailPage({super.key, required this.planId});

  @override
  State<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _loadPlan();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadPlan();
  }

  void _loadPlan() {
    final plans = Storage.getPlans();
    setState(() {
      _plan = plans.cast<Map<String, dynamic>>().firstWhere(
        (p) => p['id'] == widget.planId,
        orElse: () => <String, dynamic>{},
      );
    });
  }

  void _deletePlan(String planId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '确认删除',
      content: '删除后无法恢复，确定要删除这个计划吗？',
      confirmText: '删除',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed == true) {
      Storage.deletePlan(planId);
      if (mounted) context.go('/plan');
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return '进行中';
      case 'done':
        return '已完成';
      case 'pending':
        return '待开始';
      case 'paused':
        return '已暂停';
      default:
        return status;
    }
  }

  String _formatWeight(dynamic w) {
    if (w == null) return '-';
    final d = (w is num) ? w.toDouble() : double.tryParse('$w') ?? 0;
    return d == d.toInt().toDouble() ? '${d.toInt()}' : '$d';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final plan = _plan;

    if (plan == null || plan.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bgSecondary,
        appBar: AppBar(
          backgroundColor: colors.bgSecondary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/plan'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textMuted),
              const SizedBox(height: 16),
              Text('计划不存在或已删除',
                  style: TextStyle(color: colors.textSecondary, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/plan'),
                child: const Text('返回计划页'),
              ),
            ],
          ),
        ),
      );
    }

    final days = (plan['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final progress = ((plan['progress'] as num? ?? 0) / 100.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      appBar: AppBar(
        backgroundColor: colors.bgSecondary,
        title: Text(
          plan['name'] as String? ?? '训练计划',
          style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.go('/plan'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan info card
            CardWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BadgeWidget(
                        text: '${plan['badge'] ?? _statusLabel(plan['status'] as String? ?? '')}',
                        variant: plan['status'] == 'active' ? BadgeVariant.accent : BadgeVariant.info,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${plan['frequency'] ?? ''} · ${plan['difficulty'] ?? ''}',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '第${plan['week'] ?? 0}/${plan['totalWeeks'] ?? 0}周',
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(color: colors.accentGlow, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(progress: progress),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 当前训练日选择器（循环训练日，用户可手动调整当前处于第几天）
            _buildCurrentDaySelector(colors, plan, days),
            const SizedBox(height: 20),

            // Days list
            const SectionHeader(title: '训练日'),
            const SizedBox(height: 12),
            ...days.asMap().entries.map((entry) {
              final index = entry.key;
              final day = entry.value;
              return _buildDayCard(colors, plan, day, index);
            }),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // 编辑计划：跳转到独立添加页面
                      context.push('/add-plan?editPlanId=${plan['id']}');
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('编辑计划'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletePlan(plan['id'] as String),
                    icon: Icon(Icons.delete_outline, size: 18, color: colors.warningColor),
                    label: Text('删除计划', style: TextStyle(color: colors.warningColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 当前训练日选择器 —— 允许用户手动调整当前处于循环训练的第几天
  Widget _buildCurrentDaySelector(
      LiftTrackColors colors, Map<String, dynamic> plan, List days) {
    if (days.isEmpty) return const SizedBox.shrink();
    final currentDayIndex = (plan['currentDayIndex'] as num?)?.toInt() ?? 0;
    final activeDayIdx = currentDayIndex.clamp(0, days.length - 1);

    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, size: 18, color: colors.accentGlow),
              const SizedBox(width: 6),
              Text('当前训练日',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('点击切换',
                  style: TextStyle(color: colors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.asMap().entries.map((entry) {
              final idx = entry.key;
              final day = entry.value;
              final isSelected = idx == activeDayIdx;
              return GestureDetector(
                onTap: () {
                  Storage.updatePlan(
                      plan['id'] as String, {'currentDayIndex': idx});
                  setState(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.accentGlow.withOpacity(0.15)
                        : colors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isSelected
                            ? colors.accentGlow
                            : colors.borderColor),
                  ),
                  child: Text(
                    '第${idx + 1}天 ${day['label'] ?? ''}',
                    style: TextStyle(
                      color: isSelected ? colors.accentGlow : colors.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(LiftTrackColors colors, Map<String, dynamic> plan, Map<String, dynamic> day, int dayIndex) {
    final exercises = (day['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day['day'] ?? dayIndex + 1}',
                      style: TextStyle(color: colors.accentGlow, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${day['label'] ?? '训练日 ${dayIndex + 1}'}',
                    style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (day['muscle'] != null)
                  BadgeWidget(text: '${day['muscle']}', variant: BadgeVariant.purple),
              ],
            ),
            if (exercises.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...exercises.map((ex) => _buildExerciseDetailItem(colors, ex)),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '暂无动作，编辑计划添加',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/training?planId=${plan['id']}&dayIndex=$dayIndex');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('开始训练', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailItem(LiftTrackColors colors, Map<String, dynamic> ex) {
    final setConfig = ex['setConfig'] as List?;
    final hasPerSet = setConfig != null && setConfig.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.bgSecondary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, size: 14, color: colors.accentGlow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${ex['name']}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '共${ex['sets'] ?? 0}组',
                  style: TextStyle(color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasPerSet)
            ExerciseSetTable(setConfig: setConfig)
          else
            _buildUniformStats(colors, ex),
        ],
      ),
    );
  }

  Widget _buildUniformStats(LiftTrackColors colors, Map<String, dynamic> ex) {
    final reps = ex['reps'] ?? '-';
    final weight = ex['weight'];
    final restTime = ex['restTime'] ?? 90;
    final weightStr = (weight == null) ? '-' : '${_formatWeight(weight)}kg';

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildStatChip(colors, Icons.repeat, '次数', '$reps'),
        _buildStatChip(colors, Icons.monitor_weight_outlined, '重量', weightStr),
        _buildStatChip(colors, Icons.timer_outlined, '休息', '$restTime秒'),
      ],
    );
  }

  Widget _buildStatChip(LiftTrackColors colors, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.textMuted),
          const SizedBox(width: 3),
          Text('$label ', style: TextStyle(color: colors.textMuted, fontSize: 10)),
          Text(value, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
