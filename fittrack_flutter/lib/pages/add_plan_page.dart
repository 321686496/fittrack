import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/plan_recommendation_service.dart';
import '../services/rest_preference_service.dart';
import '../utils/art_assets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/exercise_set_table.dart';

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
  String _selectedGender = 'all';
  List<Map<String, dynamic>> _days = [];
  Map<String, dynamic>? _editingPlan;

  // 缓存每个训练日的 label 控制器，避免在 build 中重复创建
  final Map<int, TextEditingController> _labelControllers = {};

  @override
  void initState() {
    super.initState();
    // 新建计划默认为空：不预填模板数据，由用户主动选择模板或手动添加训练日
    _selectedType = '自定义';
    _days = [];
    if (widget.editPlanId != null) {
      _loadExistingPlan(widget.editPlanId!);
    }
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
    for (int i = 0; i < _days.length; i++) {
      if (!_labelControllers.containsKey(i)) {
        _labelControllers[i] = TextEditingController(
          text: '${_days[i]['label'] ?? ''}',
        );
      }
    }
    final keysToRemove = _labelControllers.keys.where((k) => k >= _days.length).toList();
    for (final k in keysToRemove) {
      _labelControllers[k]!.dispose();
      _labelControllers.remove(k);
    }
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
      _selectedGender = plan['gender'] as String? ?? 'all';
      _totalWeeksController.text = '${plan['totalWeeks'] ?? 8}';
      _restTimeController.text = '${plan['defaultRestTime'] ?? 90}';
      final days = plan['days'] as List?;
      if (days != null) {
        _days = days.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
    }
  }

  void _applyQuickSetup(String type) {
    if (type == '自定义') {
      // 自定义模式保持空白，由用户手动添加训练日
      _days = [];
    } else {
      final template = _quickSetup[type];
      if (template != null) {
        // 深拷贝，避免修改到常量模板
        _days = template.map((d) {
          final map = Map<String, dynamic>.from(d);
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

  // ── 训练日/动作编辑方法（与 _PlanEditorSheet 一致） ──────────

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

  void _addRestDay() {
    _days.add({
      'day': _days.length + 1,
      'label': '休息日',
      'muscle': '',
      'isRest': true,
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
      maxHeightRatio: 0.7,
      builder: (ctx) => ExercisePickerSheet(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultWeight: defaultWeight,
        defaultRestTime: defaultRestTime,
        onPick: (exercise, sets, reps, weight, restTime, setConfig) {
          final existing = _days[dayIndex]['exercises'];
          final exercises = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          final newEx = {
            'id': exercise['id'],
            'name': exercise['name'],
            'sets': sets,
            'reps': reps,
            'weight': weight,
            'restTime': restTime,
          };
          if (setConfig != null) {
            newEx['setConfig'] = setConfig;
          }
          exercises.add(newEx);
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

  void _editExercise(int dayIndex, int exIndex) {
    final exercises = _days[dayIndex]['exercises'] as List? ?? [];
    if (exIndex >= exercises.length) return;
    final ex = Map<String, dynamic>.from(exercises[exIndex] as Map);

    final setConfigRaw = ex['setConfig'] as List?;
    final initialSetConfig = setConfigRaw
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .cast<Map<String, dynamic>>();

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.7,
      builder: (ctx) => ExercisePickerSheet(
        defaultSets: (ex['sets'] as num?)?.toInt() ?? 3,
        defaultReps: int.tryParse(ex['reps']?.toString() ?? '10') ?? 10,
        defaultWeight: (ex['weight'] as num?)?.toDouble() ?? 20.0,
        defaultRestTime: (ex['restTime'] as num?)?.toInt() ?? 90,
        initialExercise: Storage.getAllExercises().firstWhere(
          (e) => e['id'] == ex['id'],
          orElse: () => {'id': ex['id'], 'name': ex['name'], 'category': '', 'equip': ''},
        ),
        initialSetConfig: initialSetConfig,
        onPick: (exercise, sets, reps, weight, restTime, setConfig) {
          final existing = _days[dayIndex]['exercises'];
          final exList = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          if (exIndex < exList.length) {
            final updated = {
              'id': exercise['id'],
              'name': exercise['name'],
              'sets': sets,
              'reps': reps,
              'weight': weight,
              'restTime': restTime,
            };
            if (setConfig != null) {
              updated['setConfig'] = setConfig;
            }
            exList[exIndex] = updated;
          }
          _days[dayIndex]['exercises'] = exList;
          setState(() {});
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  List<PlanRecommendation> _generateRecommendedPlans() {
    if (!SystemPlanLibrary.instance.isLoaded) return [];
    return PlanRecommendationService.instance.recommend(limit: 3);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      FitToast.info(context, '请输入计划名称');
      return;
    }
    if (_days.isEmpty) {
      FitToast.warning(context, '请先添加训练日（右上角「+ 训练日」），或选择训练类型使用模板');
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

    final planData = <String, dynamic>{
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'frequency': frequency,
      'difficulty': _selectedDifficulty,
      'gender': _selectedGender,
      'totalWeeks': totalWeeks,
      'defaultRestTime': restTime,
      'days': _days,
      'currentDayIndex': _editingPlan?['currentDayIndex'] ?? 0,
      'week': _editingPlan?['week'] ?? 0,
      'progress': _editingPlan?['progress'] ?? 0,
      'status': _editingPlan?['status'] ?? 'active',
      'badge': _editingPlan?['badge'] ?? '进行中',
    };

    try {
      if (_editingPlan == null) {
        // 新建计划：先暂停其他活跃计划，再写入新计划（await 确保持久化完成）
        final existingPlans = Storage.getPlans();
        for (final p in existingPlans) {
          if (p['status'] == 'active') {
            await Storage.updatePlanAsync(
                p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
          }
        }
        await Storage.addPlanAsync(planData);
      } else {
        await Storage.updatePlanAsync(
            _editingPlan!['id'] as String, planData);
      }
      // 保存成功后跳转首页并提示用户可以开始训练
      if (mounted) {
        FitToast.success(context, _editingPlan == null ? '计划已创建，开始训练吧！' : '计划已更新，开始训练吧！');
        context.go('/home');
      }
    } catch (e) {
      debugPrint('保存计划失败: $e');
      if (mounted) {
        FitToast.error(context, '保存失败，请重试');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
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

            // 适用人群
            _buildLabel(colors, '适用人群'),
            const SizedBox(height: 6),
            _buildGenderSelector(colors),
            const SizedBox(height: 16),

            // 总周数 & 休息时间
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(colors, '总周数'), const SizedBox(height: 6), TextField(controller: _totalWeeksController, keyboardType: TextInputType.number, style: TextStyle(color: colors.textPrimary), decoration: const InputDecoration(hintText: '8'))])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel(colors, '默认休息(秒)'), const SizedBox(height: 6), TextField(controller: _restTimeController, keyboardType: TextInputType.number, style: TextStyle(color: colors.textPrimary), decoration: const InputDecoration(hintText: '90'))])),
              ],
            ),
            _buildRestRecommendationCard(colors),
            const SizedBox(height: 20),

            // 训练日编辑器（可添加/删除训练日与动作）
            Row(
              children: [
                _buildLabel(colors, '训练日 (${_days.length}天)'),
                const Spacer(),
                GestureDetector(
                  onTap: _addDay,
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 18, color: colors.accentGlow),
                      Text('训练日', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addRestDay,
                  child: Row(
                    children: [
                      Icon(Icons.bedtime_outlined, size: 18, color: colors.infoColor),
                      Text('休息日', style: TextStyle(color: colors.infoColor, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_days.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_note_outlined, size: 36, color: colors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      '还没有训练日',
                      style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击上方「+ 训练日」开始添加，或选择训练类型使用模板快速生成',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ..._days.asMap().entries.map((entry) {
              final idx = entry.key;
              final day = entry.value;
              return _buildDayEditor(colors, idx, day);
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
                style: ElevatedButton.styleFrom(backgroundColor: colors.accentGlow, foregroundColor: Theme.of(context).colorScheme.onPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text(isEditing ? '保存修改' : '创建计划', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedCard(LiftTrackColors colors, PlanRecommendation rec) {
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              plan.coverImage ?? goalArtAsset(plan.goal) ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(plan.coverEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
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

  Widget _buildLabel(LiftTrackColors colors, String text) {
    return Text(text, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
  }

  Widget _buildGenderSelector(LiftTrackColors colors) {
    const options = <Map<String, String>>[
      {'value': 'all', 'label': '全部人群'},
      {'value': 'male', 'label': '男性'},
      {'value': 'female', 'label': '女性'},
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((g) {
        final value = g['value']!;
        final selected = _selectedGender == value;
        return GestureDetector(
          onTap: () => setState(() => _selectedGender = value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? colors.accentGlow : colors.borderColor),
            ),
            child: Text(
              g['label']!,
              style: TextStyle(
                color: selected ? colors.accentGlow : colors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 历史休息偏好推荐卡片：基于历史训练数据推荐休息时间
  Widget _buildRestRecommendationCard(LiftTrackColors colors) {
    final recommended = RestPreferenceService.instance.computeRecommendedRestSeconds();
    if (recommended == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.accentGlow.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb, color: colors.accentGlow, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '根据您的历史组间休息偏好, 推荐休息时间 $recommended 秒',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => _restTimeController.text = recommended.toString(),
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  // 训练动作的小标签：用于展示组数/次数/重量/休息时间
  Widget _buildMiniTag(LiftTrackColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 10),
      ),
    );
  }

  // 训练日编辑器卡片 —— 可编辑训练日名称、添加/删除/编辑动作
  Widget _buildDayEditor(LiftTrackColors colors, int dayIndex, Map<String, dynamic> day) {
    final isRest = day['isRest'] == true;
    final exercises = (day['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final labelController = _labelControllers[dayIndex] ?? TextEditingController(text: '${day['label'] ?? ''}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRest ? colors.infoColor.withOpacity(0.06) : colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isRest ? colors.infoColor.withOpacity(0.3) : colors.borderColor),
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
                  color: isRest ? colors.infoColor.withOpacity(0.15) : colors.accentGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    isRest ? Icons.bedtime_outlined : Icons.fitness_center,
                    size: 14,
                    color: isRest ? colors.infoColor : colors.accentGlow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: labelController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: isRest ? '休息日名称' : '训练日名称',
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
          if (isRest) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colors.infoColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement, size: 16, color: colors.infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '休息日 — 充分恢复，准备下一次训练',
                      style: TextStyle(color: colors.infoColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
          const SizedBox(height: 8),
          // Exercise list
          ...exercises.asMap().entries.map((exEntry) {
            final exIdx = exEntry.key;
            final ex = exEntry.value;
            final setConfig = ex['setConfig'] as List?;
            final hasPerSet = setConfig != null && setConfig.length > 1;
            final weightVal = ex['weight'];
            String weightStr;
            if (weightVal == null) {
              weightStr = '-';
            } else if (weightVal is num && weightVal == weightVal.toInt()) {
              weightStr = '${weightVal.toInt()}';
            } else {
              weightStr = '$weightVal';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _editExercise(dayIndex, exIdx),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ex['name']}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    if (hasPerSet) ...[
                      Row(
                        children: [
                          _buildMiniTag(colors, '共${ex['sets']}组 · 逐组设置'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _removeExercise(dayIndex, exIdx),
                            child: Icon(Icons.close, size: 14, color: colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ExerciseSetTable(setConfig: setConfig!),
                    ] else
                      Row(
                        children: [
                          _buildMiniTag(colors, '${ex['sets']}组'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${ex['reps']}次'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${weightStr}kg'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${ex['restTime']}秒'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _removeExercise(dayIndex, exIdx),
                            child: Icon(Icons.close, size: 14, color: colors.textMuted),
                          ),
                        ],
                      ),
                  ],
                ),
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
        ],
      ),
    );
  }
}
