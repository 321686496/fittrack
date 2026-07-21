import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/plan_recommendation_service.dart';
import '../widgets/common_widgets.dart';

const List<String> _planTypes = ['三分化', '四分化', '五分化', '全身训练', '自定义'];
const List<String> _difficulties = ['入门', '初级', '进阶', '高级'];

const Map<String, List<Map<String, dynamic>>> _quickSetup = {
  '三分化': [
    {'day': 1, 'label': '胸部 + 三头肌', 'muscle': '胸', 'exercises': [{'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}, {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60}]},
    {'day': 2, 'label': '背部 + 二头肌', 'muscle': '背', 'exercises': [{'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90}, {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}]},
    {'day': 3, 'label': '腿部', 'muscle': '腿', 'exercises': [{'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'weight': 50.0, 'restTime': 120}, {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'weight': 80.0, 'restTime': 90}]},
    {'day': 4, 'label': '肩部 + 核心', 'muscle': '肩', 'exercises': [{'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90}, {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'weight': 8.0, 'restTime': 60}]},
  ],
  '四分化': [
    {'day': 1, 'label': '胸部', 'muscle': '胸', 'exercises': [{'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}, {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60}]},
    {'day': 2, 'label': '背部', 'muscle': '背', 'exercises': [{'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90}, {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}]},
    {'day': 3, 'label': '腿部', 'muscle': '腿', 'exercises': [{'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'weight': 50.0, 'restTime': 120}]},
    {'day': 4, 'label': '肩部 + 手臂', 'muscle': '肩/手臂', 'exercises': [{'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90}, {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60}]},
  ],
  '五分化': [
    {'day': 1, 'label': '胸部', 'muscle': '胸', 'exercises': [{'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}, {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60}]},
    {'day': 2, 'label': '背部', 'muscle': '背', 'exercises': [{'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90}, {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90}]},
    {'day': 3, 'label': '腿部', 'muscle': '腿', 'exercises': [{'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'weight': 50.0, 'restTime': 120}]},
    {'day': 4, 'label': '肩部', 'muscle': '肩', 'exercises': [{'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90}]},
    {'day': 5, 'label': '手臂', 'muscle': '手臂', 'exercises': [{'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60}, {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60}]},
  ],
  '全身训练': [
    {'day': 1, 'label': '全身训练A', 'muscle': '全身', 'exercises': [{'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'weight': 50.0, 'restTime': 90}, {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'weight': 40.0, 'restTime': 90}]},
    {'day': 2, 'label': '全身训练B', 'muscle': '全身', 'exercises': [{'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'weight': 80.0, 'restTime': 90}, {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'weight': 40.0, 'restTime': 90}]},
    {'day': 3, 'label': '全身训练C', 'muscle': '全身', 'exercises': [{'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60}, {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'weight': 35.0, 'restTime': 75}]},
  ],
};

class AddPlanPage extends StatefulWidget {
  final String? editPlanId;

  const AddPlanPage({super.key, this.editPlanId});

  @override
  State<AddPlanPage> createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddPlanPage> {
  final _nameController = TextEditingController();
  final _totalWeeksController = TextEditingController(text: '8');
  final _restTimeController = TextEditingController(text: '90');

  String _selectedType = '三分化';
  String _selectedDifficulty = '初级';
  List<Map<String, dynamic>> _days = [];
  Map<String, dynamic>? _editingPlan;

  @override
  void initState() {
    super.initState();
    _applyQuickSetup(_selectedType);
    if (widget.editPlanId != null) {
      _loadExistingPlan(widget.editPlanId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalWeeksController.dispose();
    _restTimeController.dispose();
    super.dispose();
  }

  void _loadExistingPlan(String planId) {
    final plans = Storage.getPlans();
    final plan = plans.cast<Map<String, dynamic>>().firstWhere(
      (p) => p['id'] == planId,
      orElse: () => <String, dynamic>{},
    );
    if (plan.isNotEmpty) {
      _editingPlan = plan;
      _nameController.text = plan['name'] as String? ?? '';
      _selectedType = plan['type'] as String? ?? '三分化';
      _selectedDifficulty = plan['difficulty'] as String? ?? '初级';
      _totalWeeksController.text = '${plan['totalWeeks'] ?? 8}';
      _restTimeController.text = '${plan['defaultRestTime'] ?? 90}';
      final days = plan['days'] as List?;
      if (days != null) {
        _days = days.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
    }
  }

  void _applyQuickSetup(String type) {
    final template = _quickSetup[type];
    if (template != null) {
      _days = template.map((d) => Map<String, dynamic>.from(d)).toList();
    } else {
      _days = [
        {'day': 1, 'label': '训练日 1', 'muscle': '', 'exercises': <Map<String, dynamic>>[]},
      ];
    }
    setState(() {});
  }

  List<PlanRecommendation> _generateRecommendedPlans() {
    if (!SystemPlanLibrary.instance.isLoaded) return [];
    return PlanRecommendationService.instance.recommend(limit: 3);
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入计划名称')));
      return;
    }
    final totalWeeks = int.tryParse(_totalWeeksController.text) ?? 8;
    final restTime = int.tryParse(_restTimeController.text) ?? 90;

    String frequency;
    switch (_selectedType) {
      case '三分化': frequency = '6天/周'; break;
      case '四分化': frequency = '4天/周'; break;
      case '五分化': frequency = '5天/周'; break;
      case '全身训练': frequency = '3天/周'; break;
      default: frequency = '${_days.length}天/周';
    }

    if (_editingPlan == null) {
      final existingPlans = Storage.getPlans();
      for (final p in existingPlans) {
        if (p['status'] == 'active') {
          Storage.updatePlan(p['id'] as String, {...p, 'status': 'pending', 'badge': '待开始'});
        }
      }
    }

    final planData = {
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'frequency': frequency,
      'difficulty': _selectedDifficulty,
      'totalWeeks': totalWeeks,
      'defaultRestTime': restTime,
      'days': _days,
      'week': _editingPlan?['week'] ?? 0,
      'progress': _editingPlan?['progress'] ?? 0,
      'status': _editingPlan?['status'] ?? 'active',
      'badge': _editingPlan?['badge'] ?? '进行中',
    };

    if (_editingPlan != null) {
      Storage.updatePlan(_editingPlan!['id'] as String, planData);
    } else {
      Storage.addPlan(planData);
    }

    context.go('/plan');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final isEditing = _editingPlan != null;
    final recommendedPlans = _generateRecommendedPlans();

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      appBar: AppBar(
        backgroundColor: colors.bgSecondary,
        title: Text(isEditing ? '编辑计划' : '创建计划', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: colors.textPrimary), onPressed: () => context.go('/plan')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 自定义计划表单 ──
            Text(isEditing ? '编辑计划信息' : '或自定义计划', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // 计划名称
            _buildLabel(colors, '计划名称'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(hintText: '输入计划名称', hintStyle: TextStyle(color: colors.textMuted)),
            ),
            const SizedBox(height: 16),

            // 训练类型
            _buildLabel(colors, '训练类型'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _planTypes.map((type) {
                final isSelected = type == _selectedType;
                return GestureDetector(
                  onTap: () { setState(() => _selectedType = type); _applyQuickSetup(type); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? colors.accentGlow : colors.borderColor),
                    ),
                    child: Text(type, style: TextStyle(color: isSelected ? colors.accentGlow : colors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 难度等级
            _buildLabel(colors, '难度等级'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _difficulties.map((diff) {
                final isSelected = diff == _selectedDifficulty;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDifficulty = diff),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? colors.accentGlow : colors.borderColor),
                    ),
                    child: Text(diff, style: TextStyle(color: isSelected ? colors.accentGlow : colors.textSecondary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 总周数 & 休息时间
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(colors, '总周数'), const SizedBox(height: 6), TextField(controller: _totalWeeksController, keyboardType: TextInputType.number, style: TextStyle(color: colors.textPrimary), decoration: const InputDecoration(hintText: '8'))])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(colors, '默认休息(秒)'), const SizedBox(height: 6), TextField(controller: _restTimeController, keyboardType: TextInputType.number, style: TextStyle(color: colors.textPrimary), decoration: const InputDecoration(hintText: '90'))])),
              ],
            ),
            const SizedBox(height: 20),

            // 训练日预览
            _buildLabel(colors, '训练日预览 (${_days.length}天)'),
            const SizedBox(height: 8),
            ..._days.asMap().entries.map((entry) {
              final idx = entry.key;
              final day = entry.value;
              final exCount = (day['exercises'] as List?)?.length ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.borderColor)),
                child: Row(
                  children: [
                    Container(width: 24, height: 24, decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Center(child: Text('${idx + 1}', style: TextStyle(color: colors.accentGlow, fontSize: 12, fontWeight: FontWeight.w600)))),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${day['label'] ?? '训练日 ${idx + 1}'}', style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
                    Text('$exCount 个动作', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // ── 系统推荐 ──
            if (!isEditing && recommendedPlans.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 20, color: colors.accentGlow),
                  const SizedBox(width: 6),
                  Text('为你推荐', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('基于你的信息', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              ...recommendedPlans.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRecommendedCard(colors, rec),
              )),
              const SizedBox(height: 24),
            ],

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(backgroundColor: colors.accentGlow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(isEditing ? '保存修改' : '创建计划', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(FitTrackColors colors, PlanRecommendation rec) {
    final plan = rec.plan;
    final difficultyLabel = kDifficultyLabelsZh[plan.difficulty] ?? plan.difficulty;
    final typeLabel = kTrainingTypeLabelsZh[plan.trainingType] ?? plan.trainingType;
    final frequencyLabel = '${plan.recommendedFrequency}天/周';
    return CardWidget(
      onTap: () => context.push('/plan-library/detail/${plan.id}'),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text(plan.coverEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$typeLabel · $frequencyLabel · $difficultyLabel · ${plan.totalWeeks}周', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(plan.description, style: TextStyle(color: colors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (rec.reasons.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: rec.reasons.take(2).map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(r, style: TextStyle(color: colors.accentGlow, fontSize: 10, fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 22, color: colors.accentGlow),
        ],
      ),
    );
  }

  Widget _buildLabel(FitTrackColors colors, String text) {
    return Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
  }
}
