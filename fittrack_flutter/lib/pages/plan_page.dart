import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  const PlanPage({super.key});

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
      if (_selectedPlanId == planId) {
        _selectedPlanId = null;
      }
      _loadPlans();
    }
  }

  void _showPlanEditor({Map<String, dynamic>? existingPlan}) {
    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.85,
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
          if (_plans.isEmpty) ...[
            _buildRecommendedPlans(colors),
          ],
          const SizedBox(height: 200),
        ],
      ),
    );
  }

  Widget _buildRecommendedPlans(FitTrackColors colors) {
    final settings = Storage.getSettings();
    final gender = settings['gender'] as String? ?? '';
    final goal = settings['fitnessGoal'] as String? ?? '';
    final level = settings['fitnessLevel'] as String? ?? '';
    final frequency = settings['trainingFrequency'] as String? ?? '';

    // 根据用户信息生成推荐计划
    final recommendedPlans = _generateRecommendedPlans(gender, goal, level, frequency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 20, color: colors.accentGlow),
            const SizedBox(width: 6),
            Text(
              '为你推荐',
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '基于你的信息',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recommendedPlans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecommendedPlanCard(colors, plan),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPlanEditor(),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('自定义计划'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentGlow,
                  side: BorderSide(color: colors.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateRecommendedPlans(String gender, String goal, String level, String frequency) {
    final plans = <Map<String, dynamic>>[];

    // 主推荐计划
    if (goal == '增肌') {
      if (frequency.contains('4') || frequency.contains('5') || frequency.contains('6')) {
        plans.add(_makeRecommendedPlan(
          name: '五分化增肌计划',
          type: '五分化',
          difficulty: level == '新手' ? '初级' : (level.isEmpty ? '进阶' : level),
          frequency: '5天/周',
          totalWeeks: 8,
          desc: '胸/背/腿/肩/手臂 五天循环，最大化肌肉刺激',
          icon: Icons.fitness_center,
        ));
      } else {
        plans.add(_makeRecommendedPlan(
          name: '三分化增肌计划',
          type: '三分化',
          difficulty: level == '新手' ? '初级' : (level.isEmpty ? '进阶' : level),
          frequency: '6天/周',
          totalWeeks: 8,
          desc: '推/拉/腿 三天循环，高效增肌',
          icon: Icons.fitness_center,
        ));
      }
    } else if (goal == '减脂') {
      plans.add(_makeRecommendedPlan(
        name: 'HIIT燃脂计划',
        type: '全身训练',
        difficulty: level == '新手' ? '入门' : (level.isEmpty ? '初级' : level),
        frequency: '3天/周',
        totalWeeks: 6,
        desc: '高强度间歇训练，快速燃烧脂肪',
        icon: Icons.local_fire_department,
      ));
    } else if (goal == '塑形') {
      plans.add(_makeRecommendedPlan(
        name: '塑形美体计划',
        type: '四分化',
        difficulty: level == '新手' ? '初级' : (level.isEmpty ? '进阶' : level),
        frequency: '4天/周',
        totalWeeks: 8,
        desc: '均衡训练各部位，打造匀称体型',
        icon: Icons.accessibility_new,
      ));
    } else {
      plans.add(_makeRecommendedPlan(
        name: '全身健康计划',
        type: '全身训练',
        difficulty: level == '新手' ? '入门' : (level.isEmpty ? '初级' : level),
        frequency: '3天/周',
        totalWeeks: 6,
        desc: '全身均衡训练，提升整体健康水平',
        icon: Icons.favorite_outline,
      ));
    }

    // 新手/初级额外推荐入门计划
    if (level == '新手' || level == '初级' || level.isEmpty) {
      plans.add(_makeRecommendedPlan(
        name: '新手入门计划',
        type: '全身训练',
        difficulty: '入门',
        frequency: '3天/周',
        totalWeeks: 4,
        desc: '从基础动作开始，循序渐进建立训练习惯',
        icon: Icons.directions_run,
      ));
    }

    // 女性用户额外推荐
    if (gender == '女') {
      plans.add(_makeRecommendedPlan(
        name: '女性塑形计划',
        type: '四分化',
        difficulty: level == '新手' ? '初级' : (level.isEmpty ? '进阶' : level),
        frequency: '4天/周',
        totalWeeks: 8,
        desc: '针对女性体型特点，重点塑形臀腿和核心',
        icon: Icons.self_improvement,
      ));
    }

    // 如果没有用户信息，提供默认推荐
    if (goal.isEmpty && gender.isEmpty && level.isEmpty) {
      plans.clear();
      plans.add(_makeRecommendedPlan(
        name: '三分化增肌计划',
        type: '三分化',
        difficulty: '进阶',
        frequency: '6天/周',
        totalWeeks: 8,
        desc: '推/拉/腿 三天循环，经典增肌方案',
        icon: Icons.fitness_center,
      ));
      plans.add(_makeRecommendedPlan(
        name: '全身健康计划',
        type: '全身训练',
        difficulty: '初级',
        frequency: '3天/周',
        totalWeeks: 6,
        desc: '全身均衡训练，适合大多数健身者',
        icon: Icons.favorite_outline,
      ));
      plans.add(_makeRecommendedPlan(
        name: '新手入门计划',
        type: '全身训练',
        difficulty: '入门',
        frequency: '3天/周',
        totalWeeks: 4,
        desc: '从基础动作开始，循序渐进',
        icon: Icons.directions_run,
      ));
    }

    return plans;
  }

  Map<String, dynamic> _makeRecommendedPlan({
    required String name,
    required String type,
    required String difficulty,
    required String frequency,
    required int totalWeeks,
    required String desc,
    required IconData icon,
  }) {
    // 从快速设置模板获取训练日
    List<Map<String, dynamic>> days;
    final template = _quickSetup[type];
    if (template != null) {
      days = template.map((d) {
        final map = Map<String, dynamic>.from(d);
        final exs = map['exercises'];
        if (exs is List) {
          map['exercises'] = exs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return map;
      }).toList();
    } else {
      days = [
        {'day': 1, 'label': '训练日1', 'muscle': '全身', 'exercises': <Map<String, dynamic>>[]},
      ];
    }

    return {
      'name': name,
      'type': type,
      'difficulty': difficulty,
      'frequency': frequency,
      'totalWeeks': totalWeeks,
      'desc': desc,
      'icon': icon,
      'days': days,
      'defaultRestTime': 90,
    };
  }

  Widget _buildRecommendedPlanCard(FitTrackColors colors, Map<String, dynamic> plan) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(plan['icon'] as IconData, size: 24, color: colors.accentGlow),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['name'] as String,
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan['desc'] as String,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTag(colors, plan['frequency'] as String),
              const SizedBox(width: 8),
              _buildTag(colors, plan['difficulty'] as String),
              const SizedBox(width: 8),
              _buildTag(colors, '${plan['totalWeeks']}周'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _adoptRecommendedPlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('采用此计划', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(FitTrackColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentGlow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.accentGlow.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _adoptRecommendedPlan(Map<String, dynamic> plan) {
    final planData = Map<String, dynamic>.from(plan);
    planData.remove('icon');
    planData.remove('desc');
    planData['status'] = 'active';
    planData['badge'] = '进行中';
    planData['week'] = 0;
    planData['progress'] = 0;
    Storage.addPlan(planData);
    _loadPlans();
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
              ...exercises.map((ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center, size: 14, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${ex['name']}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${ex['sets']}x${ex['reps']}',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
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

  // 缓存每个训练日的 label 控制器，避免在 build 中重复创建
  final Map<int, TextEditingController> _labelControllers = {};

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
    // 初始化 label 控制器
    _syncLabelControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalWeeksController.dispose();
    _restTimeController.dispose();
    for (final ctrl in _labelControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _syncLabelControllers() {
    // 为每个 day 创建/更新控制器
    for (int i = 0; i < _days.length; i++) {
      if (!_labelControllers.containsKey(i)) {
        _labelControllers[i] = TextEditingController(
          text: '${_days[i]['label'] ?? ''}',
        );
      }
    }
    // 清理多余的控制器
    final keysToRemove = _labelControllers.keys.where((k) => k >= _days.length).toList();
    for (final k in keysToRemove) {
      _labelControllers[k]!.dispose();
      _labelControllers.remove(k);
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
    _syncLabelControllers();
    setState(() {});
  }

  void _addDay() {
    _days.add({
      'day': _days.length + 1,
      'label': '训练日${_days.length + 1}',
      'muscle': '',
      'exercises': <Map<String, dynamic>>[],
    });
    _syncLabelControllers();
    setState(() {});
  }

  void _removeDay(int index) {
    _days.removeAt(index);
    for (int i = 0; i < _days.length; i++) {
      _days[i]['day'] = i + 1;
    }
    _syncLabelControllers();
    setState(() {});
  }

  void _addExercise(int dayIndex) {
    final settings = Storage.getSettings();
    final defaultSets = (settings['defaultSets'] as num?)?.toInt() ?? 3;
    final defaultReps = (settings['defaultReps'] as num?)?.toInt() ?? 10;
    final defaultWeight = (settings['defaultWeight'] as num?)?.toDouble() ?? 20.0;
    final defaultRestTime = (settings['defaultRestTime'] as num?)?.toInt() ?? 90;

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.65,
      builder: (ctx) => _ExercisePickerSheet(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultWeight: defaultWeight,
        defaultRestTime: defaultRestTime,
        onPick: (exercise, sets, reps, weight, restTime) {
          // 深拷贝 exercises 列表避免 unmodifiable list 问题
          final existing = _days[dayIndex]['exercises'];
          final exercises = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          exercises.add({
            'id': exercise['id'],
            'name': exercise['name'],
            'sets': sets,
            'reps': '$reps',
            'weight': weight,
            'restTime': restTime,
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
      FitToast.warning(context, '请输入计划名称');
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

  Widget _buildDayEditor(FitTrackColors colors, int dayIndex, Map<String, dynamic> day) {
    final exercises = (day['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final labelController = _labelControllers[dayIndex] ?? TextEditingController(text: '${day['label'] ?? ''}');

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
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.fitness_center, size: 12, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ex['name']}  ${ex['sets']}x${ex['reps']}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeExercise(dayIndex, exIdx),
                    child: Icon(Icons.close, size: 14, color: colors.textMuted),
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
  final void Function(Map<String, dynamic> exercise, int sets, int reps, double weight, int restTime) onPick;

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
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _restTimeCtrl;

  @override
  void initState() {
    super.initState();
    _setsCtrl = TextEditingController(text: '${widget.defaultSets}');
    _repsCtrl = TextEditingController(text: '${widget.defaultReps}');
    _weightCtrl = TextEditingController(text: '${widget.defaultWeight}');
    _restTimeCtrl = TextEditingController(text: '${widget.defaultRestTime}');
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restTimeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
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
            Expanded(child: _buildConfigView(colors))
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
              ...filtered.map((ex) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _selectedExercise = ex;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, size: 18, color: colors.accentGlow),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ex['name']}',
                                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${ex['category']} · ${ex['equip']}',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.add, size: 20, color: colors.accentGlow),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        }).toList(),
    );
  }

  Widget _buildConfigView(FitTrackColors colors) {
    final ex = _selectedExercise!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
          const SizedBox(height: 20),
          // 组数
          Text('组数', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildNumberButton(colors, Icons.remove, () {
                final v = int.tryParse(_setsCtrl.text) ?? 1;
                if (v > 1) _setsCtrl.text = '${v - 1}';
              }),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _setsCtrl,
                  keyboardType: TextInputType.number,
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
                ),
              ),
              const SizedBox(width: 8),
              _buildNumberButton(colors, Icons.add, () {
                final v = int.tryParse(_setsCtrl.text) ?? 0;
                _setsCtrl.text = '${v + 1}';
              }),
              const SizedBox(width: 8),
              Text('组', style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // 每组次数
          Text('每组次数', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildNumberButton(colors, Icons.remove, () {
                final v = int.tryParse(_repsCtrl.text) ?? 1;
                if (v > 1) _repsCtrl.text = '${v - 1}';
              }),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
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
                ),
              ),
              const SizedBox(width: 8),
              _buildNumberButton(colors, Icons.add, () {
                final v = int.tryParse(_repsCtrl.text) ?? 0;
                _repsCtrl.text = '${v + 1}';
              }),
              const SizedBox(width: 8),
              Text('次/组', style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // 每组重量
          Text('每组重量 (kg)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildNumberButton(colors, Icons.remove, () {
                final v = double.tryParse(_weightCtrl.text) ?? 0;
                if (v >= 2.5) _weightCtrl.text = '${v - 2.5}';
              }),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                ),
              ),
              const SizedBox(width: 8),
              _buildNumberButton(colors, Icons.add, () {
                final v = double.tryParse(_weightCtrl.text) ?? 0;
                _weightCtrl.text = '${v + 2.5}';
              }),
              const SizedBox(width: 8),
              Text('kg', style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // 组间休息
          Text('组间休息 (秒)', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildNumberButton(colors, Icons.remove, () {
                final v = int.tryParse(_restTimeCtrl.text) ?? 90;
                if (v > 10) _restTimeCtrl.text = '${v - 10}';
              }),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _restTimeCtrl,
                  keyboardType: TextInputType.number,
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
                ),
              ),
              const SizedBox(width: 8),
              _buildNumberButton(colors, Icons.add, () {
                final v = int.tryParse(_restTimeCtrl.text) ?? 0;
                _restTimeCtrl.text = '${v + 10}';
              }),
              const SizedBox(width: 8),
              Text('秒', style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          // 确认按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final sets = int.tryParse(_setsCtrl.text) ?? widget.defaultSets;
                final reps = int.tryParse(_repsCtrl.text) ?? widget.defaultReps;
                final weight = double.tryParse(_weightCtrl.text) ?? widget.defaultWeight;
                final restTime = int.tryParse(_restTimeCtrl.text) ?? widget.defaultRestTime;
                widget.onPick(ex, sets, reps, weight, restTime);
              },
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
      ),
    );
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
