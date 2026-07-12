import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

// ============================================================
// Quick setup templates for auto-generating plan days
// ============================================================
const Map<String, List<Map<String, dynamic>>> _quickSetup = {
  '三分化': [
    {
      'day': 1, 'label': '胸部 + 三头肌', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'restTime': 60},
      ],
    },
    {
      'day': 2, 'label': '背部 + 二头肌', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 75},
        {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 60},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 60},
      ],
    },
    {
      'day': 3, 'label': '腿部', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
        {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
      ],
    },
    {
      'day': 4, 'label': '肩部 + 核心', 'muscle': '肩',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'restTime': 60},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '60秒', 'restTime': 45},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 45},
      ],
    },
    {
      'day': 5, 'label': '胸部 + 背部', 'muscle': '胸/背',
      'exercises': <Map<String, dynamic>>[],
    },
    {
      'day': 6, 'label': '腿部 + 手臂', 'muscle': '腿/手臂',
      'exercises': <Map<String, dynamic>>[],
    },
  ],
  '四分化': [
    {
      'day': 1, 'label': '胸部', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
      ],
    },
    {
      'day': 2, 'label': '背部', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 75},
      ],
    },
    {
      'day': 3, 'label': '腿部', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
        {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
      ],
    },
    {
      'day': 4, 'label': '肩部 + 手臂', 'muscle': '肩/手臂',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'restTime': 60},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60},
      ],
    },
  ],
  '五分化': [
    {
      'day': 1, 'label': '胸部', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'restTime': 60},
      ],
    },
    {
      'day': 2, 'label': '背部', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 75},
        {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 60},
      ],
    },
    {
      'day': 3, 'label': '腿部', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
        {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
      ],
    },
    {
      'day': 4, 'label': '肩部', 'muscle': '肩',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'restTime': 60},
      ],
    },
    {
      'day': 5, 'label': '手臂', 'muscle': '手臂',
      'exercises': [
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 60},
      ],
    },
  ],
  '全身训练': [
    {
      'day': 1, 'label': '全身训练A', 'muscle': '全身',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'restTime': 90},
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
        {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'restTime': 90},
      ],
    },
    {
      'day': 2, 'label': '全身训练B', 'muscle': '全身',
      'exercises': [
        {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'restTime': 90},
        {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
      ],
    },
    {
      'day': 3, 'label': '全身训练C', 'muscle': '全身',
      'exercises': [
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
        {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'restTime': 30},
      ],
    },
  ],
};

const List<String> _planTypes = ['三分化', '四分化', '五分化', '全身训练', '自定义'];
const List<String> _difficulties = ['入门', '初级', '进阶', '高级'];

class PlanPage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const PlanPage({super.key, required this.onNavigate});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  List<Map<String, dynamic>> _plans = [];
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() {
    _plans = Storage.getPlans();
    setState(() {});
  }

  List<Map<String, dynamic>> get _activePlans =>
      _plans.where((p) => p['status'] == 'active').toList();

  List<Map<String, dynamic>> get _otherPlans =>
      _plans.where((p) => p['status'] != 'active').toList();

  Map<String, dynamic>? get _selectedPlan {
    if (_selectedPlanId == null) return null;
    try {
      return _plans.firstWhere((p) => p['id'] == _selectedPlanId);
    } catch (_) {
      return null;
    }
  }

  void _selectPlan(String? planId) {
    setState(() {
      _selectedPlanId = planId;
    });
  }

  void _deletePlan(String planId) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(
        onConfirm: () {
          Storage.deletePlan(planId);
          if (_selectedPlanId == planId) {
            _selectedPlanId = null;
          }
          _loadPlans();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showPlanEditor({Map<String, dynamic>? existingPlan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PlanEditorSheet(
        existingPlan: existingPlan,
        onSave: (planData) {
          if (existingPlan != null) {
            Storage.updatePlan(existingPlan['id'] as String, planData);
          } else {
            Storage.addPlan(planData);
          }
          _loadPlans();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final selectedPlan = _selectedPlan;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            onBack: selectedPlan != null ? () => _selectPlan(null) : null,
            title: selectedPlan != null ? '${selectedPlan['name']}' : '训练计划',
            subtitle: selectedPlan != null ? '${selectedPlan['frequency']} · ${selectedPlan['difficulty']}' : null,
            isTabPage: selectedPlan == null,
          ),
          Expanded(
            child: selectedPlan != null
                ? _buildPlanDetail(colors, selectedPlan)
                : _buildPlanList(colors),
          ),
        ],
      ),
      floatingActionButton: selectedPlan == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 96),
              child: FloatingActionButton(
                onPressed: () => _showPlanEditor(),
                child: const Icon(Icons.add),
              ),
            )
          : null,
    );
  }

  // ── Plan List View ─────────────────────────────────────────

  Widget _buildPlanList(FitTrackColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_activePlans.isNotEmpty) ...[
            const SectionHeader(title: '进行中的计划'),
            const SizedBox(height: 12),
            ..._activePlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlanCard(colors, plan),
                )),
            const SizedBox(height: 8),
          ],
          if (_otherPlans.isNotEmpty) ...[
            SectionHeader(
              title: _activePlans.isNotEmpty ? '其他计划' : '训练计划',
            ),
            const SizedBox(height: 12),
            ..._otherPlans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPlanCard(colors, plan),
                )),
          ],
          if (_plans.isEmpty)
            EmptyState(
              icon: Icons.assignment_outlined,
              message: '还没有训练计划，点击右下角按钮创建',
            ),
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildPlanCard(FitTrackColors colors, Map<String, dynamic> plan) {
    final progress = ((plan['progress'] as num? ?? 0) / 100.0).clamp(0.0, 1.0);
    final status = plan['status'] as String? ?? 'pending';
    final badgeText = plan['badge'] as String? ?? _statusLabel(status);

    BadgeVariant badgeVariant;
    switch (status) {
      case 'active':
        badgeVariant = BadgeVariant.accent;
        break;
      case 'done':
        badgeVariant = BadgeVariant.success;
        break;
      default:
        badgeVariant = BadgeVariant.info;
    }

    return CardWidget(
      onTap: () => _selectPlan(plan['id'] as String?),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan['name']}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              BadgeWidget(text: badgeText, variant: badgeVariant),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${plan['frequency'] ?? ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Text(
                '${plan['difficulty'] ?? ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Text(
                '第${plan['week'] ?? 0}/${plan['totalWeeks'] ?? 0}周',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(progress: progress),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconBtn(
                icon: Icons.edit_outlined,
                onTap: () => _showPlanEditor(existingPlan: plan),
              ),
              const SizedBox(width: 8),
              IconBtn(
                icon: Icons.delete_outline,
                onTap: () => _deletePlan(plan['id'] as String),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return '进行中';
      case 'done':
        return '已完成';
      case 'pending':
        return '待开始';
      default:
        return status;
    }
  }

  // ── Plan Detail View ───────────────────────────────────────

  Widget _buildPlanDetail(FitTrackColors colors, Map<String, dynamic> plan) {
    final days = (plan['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final progress = ((plan['progress'] as num? ?? 0) / 100.0).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                  onPressed: () => _showPlanEditor(existingPlan: plan),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDayCard(FitTrackColors colors, Map<String, dynamic> plan, Map<String, dynamic> day, int dayIndex) {
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
                  widget.onNavigate(
                    'training',
                    params: {
                      'planId': plan['id'],
                      'dayIndex': dayIndex,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.black,
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

  // ── Exercise detail item (plan detail view) ──────────────────
  Widget _buildExerciseDetailItem(FitTrackColors colors, Map<String, dynamic> ex) {
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
            _buildPerSetTable(colors, setConfig)
          else
            _buildUniformStats(colors, ex),
        ],
      ),
    );
  }

  // ── Uniform stats display (all sets same) ────────────────────
  Widget _buildUniformStats(FitTrackColors colors, Map<String, dynamic> ex) {
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

  // ── Per-set table (each set has different params) ────────────
  Widget _buildPerSetTable(FitTrackColors colors, List setConfig) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: colors.borderColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('组', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('次数', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('重量', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('休息', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...setConfig.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value as Map;
            final isLast = idx == setConfig.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast ? BorderSide.none : BorderSide(color: colors.borderColor.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('第${idx + 1}组', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                  Expanded(flex: 3, child: Text('${s['reps'] ?? '-'}', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text('${_formatWeight(s['weight'])}kg', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text('${s['restTime'] ?? 90}秒', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(FitTrackColors colors, IconData icon, String label, String value) {
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

  String _formatWeight(dynamic w) {
    if (w == null) return '-';
    final d = (w is num) ? w.toDouble() : double.tryParse('$w') ?? 0;
    return d == d.toInt().toDouble() ? '${d.toInt()}' : '$d';
  }
}

// ============================================================
// Delete Confirmation Dialog
// ============================================================

class _DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const _DeleteConfirmDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return AlertDialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.borderColor),
      ),
      title: Text('确认删除', style: TextStyle(color: colors.textPrimary)),
      content: const Text(
        '删除后无法恢复，确定要删除这个计划吗？',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('取消', style: TextStyle(color: colors.textSecondary)),
        ),
        TextButton(
          onPressed: onConfirm,
          child: Text('删除', style: TextStyle(color: colors.warningColor)),
        ),
      ],
    );
  }
}

// ============================================================
// Plan Editor Bottom Sheet
// ============================================================

class _PlanEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existingPlan;
  final void Function(Map<String, dynamic> data) onSave;

  const _PlanEditorSheet({
    this.existingPlan,
    required this.onSave,
  });

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  late TextEditingController _nameController;
  String _selectedType = '三分化';
  String _selectedDifficulty = '进阶';
  late TextEditingController _totalWeeksController;
  late TextEditingController _restTimeController;
  List<Map<String, dynamic>> _days = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPlan;
    _nameController = TextEditingController(text: existing?['name'] as String? ?? '');
    _selectedType = existing?['type'] as String? ?? '三分化';
    _selectedDifficulty = existing?['difficulty'] as String? ?? '进阶';
    _totalWeeksController = TextEditingController(
      text: '${existing?['totalWeeks'] ?? 8}',
    );
    _restTimeController = TextEditingController(
      text: '${existing?['defaultRestTime'] ?? 90}',
    );

    if (existing != null && existing['days'] is List) {
      _days = (existing['days'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      _applyQuickSetup(_selectedType);
    }
  }

  void _applyQuickSetup(String type) {
    if (type == '自定义') {
      _days = [
        {'day': 1, 'label': '训练日1', 'muscle': '', 'exercises': <Map<String, dynamic>>[]},
      ];
    } else {
      final template = _quickSetup[type];
      if (template != null) {
        _days = template.map((d) {
          final map = Map<String, dynamic>.from(d);
          // 深拷贝 exercises 列表，避免 unmodifiable list
          final exs = map['exercises'];
          if (exs is List) {
            map['exercises'] = exs
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          return map;
        }).toList();
      }
    }
    setState(() {});
  }

  void _addDay() {
    _days.add({
      'day': _days.length + 1,
      'label': '训练日${_days.length + 1}',
      'muscle': '',
      'exercises': <Map<String, dynamic>>[],
    });
    setState(() {});
  }

  void _removeDay(int index) {
    _days.removeAt(index);
    for (int i = 0; i < _days.length; i++) {
      _days[i]['day'] = i + 1;
    }
    setState(() {});
  }

  void _addExercise(int dayIndex) {
    final settings = Storage.getSettings();
    final defaultSets = (settings['defaultSets'] as num?)?.toInt() ?? 3;
    final defaultReps = (settings['defaultReps'] as num?)?.toInt() ?? 10;
    final defaultWeight = (settings['defaultWeight'] as num?)?.toDouble() ?? 20.0;
    final defaultRest = int.tryParse(_restTimeController.text) ??
        (settings['defaultRestTime'] as num?)?.toInt() ?? 90;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExercisePickerSheet(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultWeight: defaultWeight,
        defaultRestTime: defaultRest,
        onPick: (exercise, config) {
          // 深拷贝 exercises 列表避免 unmodifiable list 问题
          final existing = _days[dayIndex]['exercises'];
          final exercises = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          exercises.add({
            'id': exercise['id'],
            'name': exercise['name'],
            'sets': config['sets'],
            'reps': config['reps'],
            'weight': config['weight'],
            'restTime': config['restTime'],
            if (config['setConfig'] != null) 'setConfig': config['setConfig'],
          });
          _days[dayIndex]['exercises'] = exercises;
          setState(() {});
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _removeExercise(int dayIndex, int exIndex) {
    final existing = _days[dayIndex]['exercises'];
    final exercises = (existing is List)
        ? List<Map<String, dynamic>>.from(
            existing.map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];
    if (exIndex < exercises.length) {
      exercises.removeAt(exIndex);
      _days[dayIndex]['exercises'] = exercises;
      setState(() {});
    }
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入计划名称')),
      );
      return;
    }

    final totalWeeks = int.tryParse(_totalWeeksController.text) ?? 8;
    final restTime = int.tryParse(_restTimeController.text) ?? 90;

    String frequency;
    switch (_selectedType) {
      case '三分化':
        frequency = '6天/周';
        break;
      case '四分化':
        frequency = '4天/周';
        break;
      case '五分化':
        frequency = '5天/周';
        break;
      case '全身训练':
        frequency = '3天/周';
        break;
      default:
        frequency = '${_days.length}天/周';
    }

    widget.onSave({
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'frequency': frequency,
      'difficulty': _selectedDifficulty,
      'totalWeeks': totalWeeks,
      'defaultRestTime': restTime,
      'days': _days,
      'week': widget.existingPlan?['week'] ?? 0,
      'progress': widget.existingPlan?['progress'] ?? 0,
      'status': widget.existingPlan?['status'] ?? 'active',
      'badge': widget.existingPlan?['badge'] ?? '进行中',
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  widget.existingPlan != null ? '编辑计划' : '创建计划',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildLabel(colors, '计划名称'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: const InputDecoration(hintText: '输入计划名称'),
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  _buildLabel(colors, '训练类型'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _planTypes.map((type) {
                      final isSelected = type == _selectedType;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = type);
                          _applyQuickSetup(type);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty selector
                  _buildLabel(colors, '难度等级'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _difficulties.map((diff) {
                      final isSelected = diff == _selectedDifficulty;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = diff),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            diff,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Total weeks & Rest time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, '总周数'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _totalWeeksController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: const InputDecoration(hintText: '8'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, '默认休息(秒)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _restTimeController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: const InputDecoration(hintText: '90'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Days editor
                  Row(
                    children: [
                      _buildLabel(colors, '训练日'),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addDay,
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18, color: colors.accentGlow),
                            Text('添加', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._days.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final day = entry.value;
                    return _buildDayEditor(colors, idx, day);
                  }),

                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('保存计划', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(FitTrackColors colors, String text) {
    return Text(
      text,
      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildEditorStatTag(FitTrackColors colors, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.borderColor.withOpacity(0.4)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label ', style: TextStyle(color: colors.textMuted, fontSize: 9)),
            TextSpan(text: value, style: TextStyle(color: colors.textPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  String _formatWeight(dynamic w) {
    if (w == null) return '-';
    final d = (w is num) ? w.toDouble() : double.tryParse('$w') ?? 0;
    return d == d.toInt().toDouble() ? '${d.toInt()}' : '$d';
  }

  Widget _buildDayEditor(FitTrackColors colors, int dayIndex, Map<String, dynamic> day) {
    final exercises = (day['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final labelController = TextEditingController(text: '${day['label'] ?? ''}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${dayIndex + 1}',
                    style: TextStyle(color: colors.accentGlow, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: labelController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: '训练日名称',
                  ),
                  onChanged: (val) => _days[dayIndex]['label'] = val,
                ),
              ),
              if (_days.length > 1)
                GestureDetector(
                  onTap: () => _removeDay(dayIndex),
                  child: Icon(Icons.close, size: 18, color: colors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Exercise list
          ...exercises.asMap().entries.map((exEntry) {
            final exIdx = exEntry.key;
            final ex = exEntry.value;
            final setConfig = ex['setConfig'] as List?;
            final hasPerSet = setConfig != null && setConfig.length > 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.bgSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.borderColor.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center, size: 12, color: colors.accentGlow),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${ex['name']}',
                          style: TextStyle(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.accentGlow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${ex['sets'] ?? 0}组',
                          style: TextStyle(color: colors.accentGlow, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeExercise(dayIndex, exIdx),
                        child: Icon(Icons.close, size: 14, color: colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (hasPerSet)
                    Text(
                      '逐组设置 · ${setConfig.length}组独立参数',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    )
                  else
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        _buildEditorStatTag(colors, '次数', '${ex['reps'] ?? '-'}'),
                        _buildEditorStatTag(colors, '重量', ex['weight'] == null ? '-' : '${_formatWeight(ex['weight'])}kg'),
                        _buildEditorStatTag(colors, '休息', '${ex['restTime'] ?? 90}秒'),
                      ],
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _addExercise(dayIndex),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colors.borderColor, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text('添加动作', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Exercise Picker Sheet
// ============================================================

class _ExercisePickerSheet extends StatefulWidget {
  final int defaultSets;
  final int defaultReps;
  final double defaultWeight;
  final int defaultRestTime;
  final void Function(Map<String, dynamic> exercise, Map<String, dynamic> config) onPick;

  const _ExercisePickerSheet({
    required this.onPick,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeight = 20.0,
    this.defaultRestTime = 90,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  Map<String, dynamic>? _selectedExercise;

  // 统一参数模式控制器
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _restCtrl;

  // 模式：true = 逐组设置，false = 统一参数
  bool _perSetMode = false;

  // 逐组设置模式的控制器列表
  final List<TextEditingController> _setRepsCtrls = [];
  final List<TextEditingController> _setWeightCtrls = [];
  final List<TextEditingController> _setRestCtrls = [];

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(text: '${widget.defaultSets}');
    _repsCtrl = TextEditingController(text: '${widget.defaultReps}');
    _weightCtrl = TextEditingController(text: '${widget.defaultWeight}');
    _restCtrl = TextEditingController(text: '${widget.defaultRestTime}');
    _syncSetControllers(widget.defaultSets);
  }

  void _syncSetControllers(int count) {
    final current = _setRepsCtrls.length;
    if (count > current) {
      for (int i = current; i < count; i++) {
        final src = i > 0 ? i - 1 : 0;
        final reps = _setRepsCtrls.isNotEmpty ? _setRepsCtrls[src].text : '${widget.defaultReps}';
        final weight = _setWeightCtrls.isNotEmpty ? _setWeightCtrls[src].text : '${widget.defaultWeight}';
        final rest = _setRestCtrls.isNotEmpty ? _setRestCtrls[src].text : '${widget.defaultRestTime}';
        _setRepsCtrls.add(TextEditingController(text: reps));
        _setWeightCtrls.add(TextEditingController(text: weight));
        _setRestCtrls.add(TextEditingController(text: rest));
      }
    } else if (count < current) {
      for (int i = current - 1; i >= count; i--) {
        _setRepsCtrls[i].dispose();
        _setWeightCtrls[i].dispose();
        _setRestCtrls[i].dispose();
        _setRepsCtrls.removeAt(i);
        _setWeightCtrls.removeAt(i);
        _setRestCtrls.removeAt(i);
      }
    }
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restCtrl.dispose();
    for (final c in _setRepsCtrls) {
      c.dispose();
    }
    for (final c in _setWeightCtrls) {
      c.dispose();
    }
    for (final c in _setRestCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _copyFromPrevious(int index) {
    if (index <= 0 || index >= _setRepsCtrls.length) return;
    _setRepsCtrls[index].text = _setRepsCtrls[index - 1].text;
    _setWeightCtrls[index].text = _setWeightCtrls[index - 1].text;
    _setRestCtrls[index].text = _setRestCtrls[index - 1].text;
    setState(() {});
  }

  void _confirm() {
    final ex = _selectedExercise!;
    final sets = int.tryParse(_setsCtrl.text) ?? widget.defaultSets;

    if (_perSetMode) {
      final setConfig = <Map<String, dynamic>>[];
      final n = sets < _setRepsCtrls.length ? sets : _setRepsCtrls.length;
      for (int i = 0; i < n; i++) {
        setConfig.add({
          'reps': _setRepsCtrls[i].text.isNotEmpty ? _setRepsCtrls[i].text : '${widget.defaultReps}',
          'weight': double.tryParse(_setWeightCtrls[i].text) ?? widget.defaultWeight,
          'restTime': int.tryParse(_setRestCtrls[i].text) ?? widget.defaultRestTime,
        });
      }
      widget.onPick(ex, {
        'sets': sets,
        'reps': setConfig.isNotEmpty ? setConfig.first['reps'] : '${widget.defaultReps}',
        'weight': setConfig.isNotEmpty ? setConfig.first['weight'] : widget.defaultWeight,
        'restTime': setConfig.isNotEmpty ? setConfig.first['restTime'] : widget.defaultRestTime,
        'setConfig': setConfig,
      });
    } else {
      widget.onPick(ex, {
        'sets': sets,
        'reps': _repsCtrl.text.isNotEmpty ? _repsCtrl.text : '${widget.defaultReps}',
        'weight': double.tryParse(_weightCtrl.text) ?? widget.defaultWeight,
        'restTime': int.tryParse(_restCtrl.text) ?? widget.defaultRestTime,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedExercise != null ? '设置动作参数' : '选择动作',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedExercise != null)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: bottomInset + 16),
                child: _buildConfigView(colors),
              ),
            )
          else
            Expanded(child: _buildExerciseList(colors)),
        ],
      ),
    );
  }

  Widget _buildExerciseList(FitTrackColors colors) {
    final exercises = MockData.exercises;
    final categories = MockData.categories;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: categories.map((category) {
        final filtered = category == '全部'
            ? exercises
            : exercises.where((e) => e['category'] == category).toList();
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category != '全部')
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  category,
                  style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ...filtered.map((ex) => ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(Icons.fitness_center, size: 18, color: colors.accentGlow),
                  title: Text(
                    '${ex['name']}',
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${ex['category']} · ${ex['equip']}',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                  trailing: Icon(Icons.add, size: 20, color: colors.accentGlow),
                  onTap: () {
                    setState(() {
                      _selectedExercise = ex;
                    });
                  },
                )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConfigView(FitTrackColors colors) {
    final ex = _selectedExercise!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 选中动作信息
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fitness_center, size: 24, color: colors.accentGlow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex['name'] as String,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ex['category']} · ${ex['equip']}',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 模式切换：统一参数 / 逐组设置
        _buildModeToggle(colors),
        const SizedBox(height: 16),

        // 组数（共用）
        _buildLabelRow(colors, '组数', '共 ${_setsCtrl.text} 组'),
        const SizedBox(height: 6),
        _buildStepperRow(
          colors,
          controller: _setsCtrl,
          unit: '组',
          step: 1,
          min: 1,
          isInt: true,
          onChanged: () {
            final v = int.tryParse(_setsCtrl.text) ?? 1;
            if (v >= 1) _syncSetControllers(v);
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        if (!_perSetMode) ...[
          // 统一参数：次数 / 重量 / 休息
          _buildLabelRow(colors, '每组次数', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(
            colors,
            controller: _repsCtrl,
            unit: '次/组',
            step: 1,
            min: 1,
            isInt: true,
          ),
          const SizedBox(height: 16),
          _buildLabelRow(colors, '每组重量', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(
            colors,
            controller: _weightCtrl,
            unit: 'kg',
            step: 2.5,
            min: 0,
            isInt: false,
          ),
          const SizedBox(height: 16),
          _buildLabelRow(colors, '组间休息', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(
            colors,
            controller: _restCtrl,
            unit: '秒',
            step: 15,
            min: 0,
            isInt: true,
          ),
        ] else ...[
          // 逐组设置：每组独立的次数 / 重量 / 休息
          _buildPerSetEditor(colors),
        ],

        const SizedBox(height: 24),
        // 确认按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentGlow,
              foregroundColor: colors.bgCard,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('确认添加', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── 模式切换 ──────────────────────────────────────────────────
  Widget _buildModeToggle(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleItem(colors, '统一参数', Icons.layers, !_perSetMode, () {
              setState(() => _perSetMode = false);
            }),
          ),
          Expanded(
            child: _buildToggleItem(colors, '逐组设置', Icons.view_list, _perSetMode, () {
              setState(() => _perSetMode = true);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(FitTrackColors colors, String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? colors.accentGlow.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? colors.accentGlow : colors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? colors.accentGlow : colors.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 逐组编辑器 ────────────────────────────────────────────────
  Widget _buildPerSetEditor(FitTrackColors colors) {
    final sets = int.tryParse(_setsCtrl.text) ?? 1;
    final count = sets < _setRepsCtrls.length ? sets : _setRepsCtrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('逐组参数设置', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('每组可独立调整', style: TextStyle(color: colors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        // 表头
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: colors.borderColor.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              SizedBox(width: 38, child: Text('组', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
              Expanded(child: Text('次数', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(child: Text('重量(kg)', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(child: Text('休息(秒)', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              const SizedBox(width: 28),
            ],
          ),
        ),
        // 每组输入行
        ...List.generate(count, (i) => _buildPerSetRow(colors, i)),
      ],
    );
  }

  Widget _buildPerSetRow(FitTrackColors colors, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.4),
        border: Border(
          bottom: BorderSide(color: colors.borderColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text('第${index + 1}组', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
          ),
          Expanded(
            child: _buildMiniField(colors, _setRepsCtrls[index], TextInputType.number),
          ),
          Expanded(
            child: _buildMiniField(colors, _setWeightCtrls[index], const TextInputType.numberWithOptions(decimal: true)),
          ),
          Expanded(
            child: _buildMiniField(colors, _setRestCtrls[index], TextInputType.number),
          ),
          SizedBox(
            width: 28,
            child: index > 0
                ? GestureDetector(
                    onTap: () => _copyFromPrevious(index),
                    child: Icon(Icons.copy, size: 14, color: colors.textMuted),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniField(FitTrackColors colors, TextEditingController controller, TextInputType kbType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller: controller,
        keyboardType: kbType,
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: colors.bgCard,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colors.accentGlow),
          ),
        ),
      ),
    );
  }

  // ── 通用组件 ──────────────────────────────────────────────────
  Widget _buildLabelRow(FitTrackColors colors, String label, String hint) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(hint, style: TextStyle(color: colors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildStepperRow(
    FitTrackColors colors, {
    required TextEditingController controller,
    required String unit,
    required double step,
    required double min,
    required bool isInt,
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        _buildNumberButton(colors, Icons.remove, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            final nv = (v - step.toInt()).clamp(min.toInt(), 9999);
            controller.text = '$nv';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            final nv = (v - step).clamp(min, 9999.0);
            controller.text = _formatDouble(nv);
          }
          onChanged?.call();
        }),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            keyboardType: isInt ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accentGlow),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const SizedBox(width: 8),
        _buildNumberButton(colors, Icons.add, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            controller.text = '${v + step.toInt()}';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            controller.text = _formatDouble(v + step);
          }
          onChanged?.call();
        }),
        const SizedBox(width: 8),
        Text(unit, style: TextStyle(color: colors.textMuted, fontSize: 14)),
      ],
    );
  }

  String _formatDouble(double v) {
    return v == v.toInt().toDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  Widget _buildNumberButton(FitTrackColors colors, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderColor),
        ),
        child: Icon(icon, size: 18, color: colors.accentGlow),
      ),
    );
  }
}
