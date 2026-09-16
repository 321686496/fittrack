import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../data/tutorial_content.dart';
import '../widgets/common_widgets.dart';
import '../widgets/default_exercise_cover.dart';
import '../widgets/page_header.dart';
import '../widgets/tutorial_share_card.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  String _selectedCategory = '全部';
  String _searchQuery = '';
  Map<String, dynamic>? _selectedExercise;

  List<Map<String, dynamic>> get _filteredExercises {
    var list = Storage.getAllExercises();
    if (_selectedCategory != '全部') {
      list = list.where((e) => e['category'] == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((e) =>
              (e['name'] as String).contains(_searchQuery) ||
              (e['category'] as String).contains(_searchQuery) ||
              (e['equip'] as String).contains(_searchQuery))
          .toList();
    }
    return list;
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case '胸部':
        return Icons.fitness_center;
      case '背部':
        return Icons.backpack;
      case '腿部':
        return Icons.directions_run;
      case '肩部':
        return Icons.accessibility_new;
      case '手臂':
        return Icons.sports_martial_arts;
      case '核心':
        return Icons.self_improvement;
      case '跑步':
        return Icons.directions_run;
      default:
        return Icons.sports_gymnastics;
    }
  }

  BadgeVariant _categoryBadgeVariant(String category) {
    switch (category) {
      case '胸部':
        return BadgeVariant.accent;
      case '背部':
        return BadgeVariant.info;
      case '腿部':
        return BadgeVariant.success;
      case '肩部':
        return BadgeVariant.purple;
      case '手臂':
        return BadgeVariant.accent;
      case '核心':
        return BadgeVariant.info;
      default:
        return BadgeVariant.accent;
    }
  }

  /// 根据动作数据渲染封面：自定义路径 → Image.file；
  /// asset 路径 → Image.asset；无 image → DefaultExerciseCover。
  Widget _buildCoverImage(Map<String, dynamic> ex, double? height, {BoxFit fit = BoxFit.cover}) {
    final image = ex['image'] as String?;
    if (image != null && image.isNotEmpty) {
      if (image.startsWith('assets/')) {
        return Image.asset(image, fit: fit,
            width: double.infinity, height: height);
      }
      return Image.file(File(image), fit: fit,
          width: double.infinity, height: height);
    }
    return DefaultExerciseCover(
      category: (ex['category'] as String?) ?? '其他',
      size: height ?? 180,
    );
  }

  void _showPlanPicker(Map<String, dynamic> exercise) {
    final plans = Storage.getPlans();
    if (plans.isEmpty) {
      FitToast.warning(context, '暂无可用计划，请先创建计划');
      return;
    }

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.85,
      builder: (ctx) => _AddToPlanSheet(exercise: exercise, plans: plans),
    );
  }

  /// 动作库单个动作分享：转成 [Tutorial] 后弹出 [TutorialShareCardSheet]，
  /// 复用教学动作分享卡片（带图 TutorialPoster）作为海报。
  void _shareExercise(Map<String, dynamic> ex) {
    final id = ex['id'] as String;
    final steps = (ex['steps'] as List?)?.isNotEmpty == true
        ? List<Map<String, dynamic>>.from(ex['steps'] as List)
        : (MockData.exerciseSteps[id] ?? <Map<String, dynamic>>[]);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TutorialShareCardSheet(
        tutorial: _exerciseToTutorial(ex),
        steps: steps,
      ),
    );
  }

  /// 将动作库的 ex Map 转换为 [Tutorial]，供分享卡片/海报使用
  Tutorial _exerciseToTutorial(Map<String, dynamic> ex) {
    final id = ex['id'] as String;
    final muscles = (ex['muscles'] as List?)?.isNotEmpty == true
        ? List<String>.from(ex['muscles'] as List)
        : <String>[];
    final description = (ex['description'] as String?)?.isNotEmpty == true
        ? ex['description'] as String
        : (MockData.exerciseDescriptions[id] ?? '暂无描述');
    // 训练步骤标题作为分享文本要点
    final steps = (ex['steps'] as List?)?.isNotEmpty == true
        ? List<Map<String, dynamic>>.from(ex['steps'] as List)
        : (MockData.exerciseSteps[id] ?? <Map<String, dynamic>>[]);
    final keyPoints = steps
        .map((s) => (s['title'] as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (keyPoints.isEmpty) {
      keyPoints.addAll(description
          .split(RegExp(r'[。.]'))
          .where((s) => s.trim().isNotEmpty)
          .take(3));
    }
    return Tutorial(
      id: id,
      name: ex['name'] as String,
      type: TutorialType.basic,
      difficulty: TutorialDifficulty.beginner,
      primaryMuscle: _muscleGroup(muscles),
      equipment: (ex['equip'] as String?) ?? '无器械',
      keyPoints: keyPoints,
      commonMistakes: const <String>[],
      coachName: 'LiftTrack 教练',
    );
  }

  /// 根据肌肉名称（或分类）推断主肌群，用于海报徽标
  MuscleGroup _muscleGroup(List<String> muscles) {
    String label = muscles.isNotEmpty ? muscles.first : '';
    if (label.isEmpty) label = _selectedExercise?['category'] as String? ?? '胸部';
    if (label.contains('胸')) return MuscleGroup.chest;
    if (label.contains('背')) return MuscleGroup.back;
    if (label.contains('腿')) return MuscleGroup.leg;
    if (label.contains('肩')) return MuscleGroup.shoulder;
    if (label.contains('手') || label.contains('臂')) return MuscleGroup.arm;
    if (label.contains('核')) return MuscleGroup.core;
    return MuscleGroup.chest;
  }

  void _showAddExerciseDialog() {
    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.9,
      builder: (ctx) => _AddExerciseSheet(
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      floatingActionButton: _selectedExercise == null
          ? FloatingActionButton(
              onPressed: () => _showAddExerciseDialog(),
              backgroundColor: colors.accentGlow,
              child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            )
          : null,
      body: _selectedExercise != null
          ? _buildDetailView(colors)
          : _buildListView(colors),
    );
  }

  Widget _buildListView(LiftTrackColors colors) {
    final filtered = _filteredExercises;

    return Column(
      children: [
        PageHeader(
          onBack: () => context.pop(),
          title: '动作库',
          subtitle: '浏览所有训练动作',
        ),
        // Category tabs
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: MockData.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final cat = MockData.categories[index];
                final isActive = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? colors.accentGlow.withOpacity(0.15)
                          : colors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? colors.accentGlow
                            : colors.borderColor,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isActive ? colors.accentGlow : colors.textSecondary,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Search input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: '搜索动作...',
              hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
              prefixIcon:
                  Icon(Icons.search, size: 20, color: colors.textMuted),
              filled: true,
              fillColor: colors.bgCard,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.accentGlow),
              ),
            ),
          ),
        ),
        // Exercise grid
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  message: '没有找到匹配的动作',
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 190,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final ex = filtered[index];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedExercise = ex),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 90,
                                width: double.infinity,
                                child: _buildCoverImage(ex, 90),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ex['name'] as String,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${ex['category']} · ${ex['equip']}',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetailView(LiftTrackColors colors) {
    final ex = _selectedExercise!;
    final exId = ex['id'] as String;
    final description = (ex['description'] as String?)?.isNotEmpty == true
        ? ex['description'] as String
        : (MockData.exerciseDescriptions[exId] ?? '暂无描述');
    final muscles = (ex['muscles'] as List?)?.isNotEmpty == true
        ? List<String>.from(ex['muscles'] as List)
        : (MockData.exerciseMuscles[exId] ?? <String>[]);
    final steps = (ex['steps'] as List?)?.isNotEmpty == true
        ? List<Map<String, dynamic>>.from(ex['steps'] as List)
        : (MockData.exerciseSteps[exId] ?? <Map<String, dynamic>>[]);

    return Column(
      children: [
        PageHeader(
          onBack: () => setState(() => _selectedExercise = null),
          title: ex['name'] as String,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    BadgeWidget(
                      text: ex['category'] as String,
                      variant: _categoryBadgeVariant(ex['category'] as String),
                    ),
                    BadgeWidget(
                      text: ex['equip'] as String,
                      variant: BadgeVariant.info,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Exercise hero image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCoverImage(ex, null, fit: BoxFit.fitWidth),
                ),
                const SizedBox(height: 20),
                // Description
                SectionHeader(title: '动作说明'),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                // Training steps cards
                if (steps.isNotEmpty) ...[
                  SectionHeader(title: '训练步骤'),
                  const SizedBox(height: 12),
                  ...steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    return _buildStepCard(colors, idx + 1, step);
                  }),
                  const SizedBox(height: 24),
                ],
                // Target muscles
                SectionHeader(title: '目标肌群'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: muscles.map<Widget>((m) {
                    return BadgeWidget(
                      text: m,
                      variant: BadgeVariant.purple,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 30),
                // 操作按钮：分享动作 + 添加到计划
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareExercise(ex),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('分享'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accentGlow,
                          side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPlanPicker(ex),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('添加到计划'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentGlow,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(LiftTrackColors colors, int stepNum, Map<String, dynamic> step) {
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
          // Step header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: colors.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNum',
                      style: TextStyle(
                        color: colors.bgCard,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step['title'] as String? ?? '',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Step image placeholder
          if (step['image'] != null)
            Container(
              width: double.infinity,
              color: colors.bgElevated,
              child: Image.asset(
                step['image'] as String,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              color: colors.bgElevated,
              child: Center(
                child: Icon(
                  Icons.fitness_center,
                  size: 36,
                  color: colors.textMuted.withOpacity(0.3),
                ),
              ),
            ),
          // Step description
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              step['desc'] as String? ?? '',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          // 关键姿势
          if ((step['keyPoses'] as List?)?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.center_focus_strong,
                    size: 14, color: colors.accentGlow),
                const SizedBox(width: 4),
                Text(
                  '关键姿势',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.accentGlow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...((step['keyPoses'] as List).map((k) => Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.accentGlow,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          k.toString(),
                          style: TextStyle(
                              fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ))),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Add To Plan Sheet — 三步流程：选计划 → 选训练日 → 配置动作参数
// ============================================================

class _AddToPlanSheet extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final List<Map<String, dynamic>> plans;

  const _AddToPlanSheet({
    required this.exercise,
    required this.plans,
  });

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  int _step = 0; // 0=选计划, 1=选训练日, 2=配置参数
  Map<String, dynamic>? _selectedPlan;
  int _selectedDayIndex = 0;

  // 参数配置
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _restTimeCtrl;
  bool _perSetMode = false;
  final List<TextEditingController> _setRepsCtrls = [];
  final List<TextEditingController> _setWeightCtrls = [];
  final List<TextEditingController> _setRestCtrls = [];

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    final defaultSets = (settings['defaultSets'] as num?)?.toInt() ?? 3;
    final defaultReps = (settings['defaultReps'] as num?)?.toInt() ?? 10;
    final defaultWeight = (settings['defaultWeight'] as num?)?.toDouble() ?? 20.0;
    final defaultRestTime = (settings['defaultRestTime'] as num?)?.toInt() ?? 90;

    _setsCtrl = TextEditingController(text: '$defaultSets');
    _repsCtrl = TextEditingController(text: '$defaultReps');
    _weightCtrl = TextEditingController(text: '$defaultWeight');
    _restTimeCtrl = TextEditingController(text: '$defaultRestTime');
    _syncSetControllers(defaultSets, null, defaultReps, defaultWeight, defaultRestTime);
  }

  void _syncSetControllers(int count, List<Map<String, dynamic>>? initial, int defReps, double defWeight, int defRest) {
    final current = _setRepsCtrls.length;
    if (count > current) {
      for (int i = current; i < count; i++) {
        String reps, weight, rest;
        if (initial != null && i < initial.length) {
          final cfg = initial[i];
          reps = cfg['reps']?.toString() ?? '$defReps';
          weight = cfg['weight']?.toString() ?? '$defWeight';
          rest = cfg['restTime']?.toString() ?? '$defRest';
        } else if (i > 0 && _setRepsCtrls.isNotEmpty) {
          reps = _setRepsCtrls[i - 1].text;
          weight = _setWeightCtrls[i - 1].text;
          rest = _setRestCtrls[i - 1].text;
        } else {
          reps = '$defReps';
          weight = '$defWeight';
          rest = '$defRest';
        }
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

  void _copyFromPrevious(int index) {
    if (index <= 0 || index >= _setRepsCtrls.length) return;
    _setRepsCtrls[index].text = _setRepsCtrls[index - 1].text;
    _setWeightCtrls[index].text = _setWeightCtrls[index - 1].text;
    _setRestCtrls[index].text = _setRestCtrls[index - 1].text;
    setState(() {});
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restTimeCtrl.dispose();
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

  void _confirmAdd() {
    final plan = _selectedPlan!;
    final days = List<Map<String, dynamic>>.from(
      (plan['days'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    if (_selectedDayIndex >= days.length) return;

    final exercises = List<Map<String, dynamic>>.from(
      (days[_selectedDayIndex]['exercises'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );

    final setsVal = int.tryParse(_setsCtrl.text) ?? 3;
    final newEx = <String, dynamic>{
      'id': widget.exercise['id'],
      'name': widget.exercise['name'],
      'sets': setsVal,
      'restTime': int.tryParse(_restTimeCtrl.text) ?? 90,
    };

    if (_perSetMode) {
      final setConfig = <Map<String, dynamic>>[];
      final n = setsVal < _setRepsCtrls.length ? setsVal : _setRepsCtrls.length;
      for (int i = 0; i < n; i++) {
        setConfig.add({
          'reps': _setRepsCtrls[i].text.isNotEmpty ? _setRepsCtrls[i].text : '10',
          'weight': double.tryParse(_setWeightCtrls[i].text) ?? 20.0,
          'restTime': int.tryParse(_setRestCtrls[i].text) ?? 90,
        });
      }
      newEx['reps'] = setConfig.isNotEmpty ? setConfig.first['reps'].toString() : '10';
      newEx['weight'] = setConfig.isNotEmpty ? setConfig.first['weight'] as double : 20.0;
      newEx['setConfig'] = setConfig;
    } else {
      newEx['reps'] = _repsCtrl.text;
      newEx['weight'] = double.tryParse(_weightCtrl.text) ?? 20.0;
    }

    exercises.add(newEx);
    days[_selectedDayIndex]['exercises'] = exercises;
    Storage.updatePlan(plan['id'] as String, {'days': days});

    FitToast.success(context, '已添加「${widget.exercise['name']}」到「${plan['name']}」的第${_selectedDayIndex + 1}天');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部标题 + 步骤指示
          _buildHeader(colors),
          const Divider(height: 1),
          // 内容区
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _step == 0
                  ? _buildPlanList(colors)
                  : _step == 1
                      ? _buildDayList(colors)
                      : _buildConfigView(colors),
            ),
          ),
          // 底部操作栏
          if (_step > 0) _buildBottomBar(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(LiftTrackColors colors) {
    final ex = widget.exercise;
    final stepTitles = ['选择计划', '选择训练日', '配置参数'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.fitness_center, size: 18, color: colors.accentGlow),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '添加「${ex['name']}」到计划',
                  style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 步骤指示器
          Row(
            children: List.generate(3, (i) {
              final active = i <= _step;
              final label = stepTitles[i];
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: active ? colors.accentGlow : colors.borderColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: active ? colors.textPrimary : colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: active ? colors.textSecondary : colors.textMuted,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 6),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 0: 计划列表 ──────────────────────────────────────────
  Widget _buildPlanList(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.plans.map((plan) {
        final days = (plan['days'] as List?) ?? [];
        final status = plan['status'] ?? 'active';
        final statusLabel = status == 'active'
            ? '进行中'
            : status == 'pending'
                ? '待开始'
                : status == 'paused'
                    ? '已暂停'
                    : '已完成';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedPlan = plan;
                _step = 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment, size: 22, color: colors.accentGlow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['name'] ?? '',
                          style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$statusLabel · ${days.length}个训练日',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 1: 训练日列表 ────────────────────────────────────────
  Widget _buildDayList(LiftTrackColors colors) {
    final plan = _selectedPlan!;
    final days = (plan['days'] as List?) ?? [];

    if (days.isEmpty) {
      return Center(
        child: Text('该计划暂无训练日', style: TextStyle(color: colors.textMuted, fontSize: 14)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: days.asMap().entries.map((entry) {
        final i = entry.key;
        final day = entry.value as Map;
        final exercises = (day['exercises'] as List?) ?? [];
        final dayName = day['name'] ?? '第${i + 1}天';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = i;
                _step = 2;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(color: colors.accentGlow, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${exercises.length}个动作',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: 参数配置 ──────────────────────────────────────────
  Widget _buildConfigView(LiftTrackColors colors) {
    final ex = widget.exercise;
    final plan = _selectedPlan!;
    final days = (plan['days'] as List?) ?? [];
    final dayName = _selectedDayIndex < days.length
        ? (days[_selectedDayIndex]['name'] ?? '第${_selectedDayIndex + 1}天')
        : '第${_selectedDayIndex + 1}天';
    final sets = int.tryParse(_setsCtrl.text) ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 动作 + 目标信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.fitness_center, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ex['name']} → ${plan['name']} · $dayName',
                  style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 模式切换
        _buildModeToggle(colors),
        const SizedBox(height: 14),
        // 组数
        _buildLabelRow(colors, '组数', '共 ${_setsCtrl.text} 组'),
        const SizedBox(height: 6),
        _buildStepperRow(colors, controller: _setsCtrl, unit: '组', step: 1, min: 1, isInt: true, onChanged: () {
          final v = int.tryParse(_setsCtrl.text) ?? 1;
          if (v >= 1) _syncSetControllers(v, null, 10, 20.0, 90);
          setState(() {});
        }),
        const SizedBox(height: 14),

        if (!_perSetMode) ...[
          _buildLabelRow(colors, '每组次数', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(colors, controller: _repsCtrl, unit: '次/组', step: 1, min: 1, isInt: true),
          const SizedBox(height: 14),
          _buildLabelRow(colors, '每组重量', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(colors, controller: _weightCtrl, unit: 'kg', step: 2.5, min: 0, isInt: false),
          const SizedBox(height: 14),
          _buildLabelRow(colors, '组间休息', '所有组相同'),
          const SizedBox(height: 6),
          _buildStepperRow(colors, controller: _restTimeCtrl, unit: '秒', step: 15, min: 0, isInt: true),
        ] else ...[
          _buildPerSetEditor(colors, sets),
        ],
      ],
    );
  }

  Widget _buildModeToggle(LiftTrackColors colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem(colors, '统一参数', Icons.layers, !_perSetMode, () {
            setState(() => _perSetMode = false);
          })),
          Expanded(child: _buildToggleItem(colors, '逐组设置', Icons.view_list, _perSetMode, () {
            setState(() => _perSetMode = true);
          })),
        ],
      ),
    );
  }

  Widget _buildToggleItem(LiftTrackColors colors, String label, IconData icon, bool active, VoidCallback onTap) {
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

  Widget _buildPerSetEditor(LiftTrackColors colors, int sets) {
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
        ...List.generate(count, (i) => _buildPerSetRow(colors, i)),
      ],
    );
  }

  Widget _buildPerSetRow(LiftTrackColors colors, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: colors.borderColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          SizedBox(width: 38, child: Text('第${index + 1}组', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
          Expanded(child: _buildMiniField(colors, _setRepsCtrls[index], TextInputType.number)),
          Expanded(child: _buildMiniField(colors, _setWeightCtrls[index], const TextInputType.numberWithOptions(decimal: true))),
          Expanded(child: _buildMiniField(colors, _setRestCtrls[index], TextInputType.number)),
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

  Widget _buildMiniField(LiftTrackColors colors, TextEditingController controller, TextInputType kbType) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.accentGlow)),
        ),
      ),
    );
  }

  Widget _buildLabelRow(LiftTrackColors colors, String label, String hint) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(hint, style: TextStyle(color: colors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildStepperRow(LiftTrackColors colors, {
    required TextEditingController controller,
    required String unit,
    required double step,
    required double min,
    required bool isInt,
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        _buildNumBtn(colors, Icons.remove, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            controller.text = '${(v - step.toInt()).clamp(min.toInt(), 9999)}';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            controller.text = _fmtDouble((v - step).clamp(min, 9999.0));
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
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.accentGlow)),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const SizedBox(width: 8),
        _buildNumBtn(colors, Icons.add, () {
          if (isInt) {
            final v = int.tryParse(controller.text) ?? 0;
            controller.text = '${v + step.toInt()}';
          } else {
            final v = double.tryParse(controller.text) ?? 0;
            controller.text = _fmtDouble(v + step);
          }
          onChanged?.call();
        }),
        const SizedBox(width: 8),
        Text(unit, style: TextStyle(color: colors.textMuted, fontSize: 14)),
      ],
    );
  }

  String _fmtDouble(double v) {
    return v == v.toInt().toDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  Widget _buildNumBtn(LiftTrackColors colors, IconData icon, VoidCallback onTap) {
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
        child: Icon(icon, size: 18, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildBottomBar(LiftTrackColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderColor.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          if (_step > 1)
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _step = 1),
                child: Text('重新选择训练日', style: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
            )
          else
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _step = 0),
                child: Text('重新选择计划', style: TextStyle(color: colors.textMuted, fontSize: 13)),
              ),
            ),
          const SizedBox(width: 10),
          if (_step == 2)
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _confirmAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('确认添加', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// Add Exercise Sheet — 添加自定义动作（专业级字段）
// ============================================================

/// 单个步骤的控制器集合，便于随步骤增减统一 dispose。
class _StepCtrl {
  final TextEditingController title = TextEditingController();
  final TextEditingController desc = TextEditingController();
  final List<TextEditingController> keyPoses = [TextEditingController()];

  void dispose() {
    title.dispose();
    desc.dispose();
    for (final c in keyPoses) {
      c.dispose();
    }
  }
}

class _AddExerciseSheet extends StatefulWidget {
  /// 保存成功后的回调（用于父级刷新列表）
  final VoidCallback onSaved;

  const _AddExerciseSheet({required this.onSaved});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _equipCtrl;
  late final TextEditingController _descCtrl;
  late final List<String> _categories;
  late final List<String> _muscleCandidates;
  String _selectedCategory = '';
  final List<String> _selectedMuscles = [];
  final List<_StepCtrl> _stepCtrls = [_StepCtrl()];
  String? _coverImagePath;

  static const int _maxSteps = 6;
  static const int _maxKeyPoses = 3;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _equipCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _categories = MockData.categories.where((c) => c != '全部').toList();
    _selectedCategory = _categories.isNotEmpty ? _categories.first : '';
    _muscleCandidates = MockData.exerciseMuscles.values
        .expand((l) => l)
        .toSet()
        .toList();
    _muscleCandidates.sort();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipCtrl.dispose();
    _descCtrl.dispose();
    for (final s in _stepCtrls) {
      s.dispose();
    }
    super.dispose();
  }

  void _toggleMuscle(String m) {
    setState(() {
      if (_selectedMuscles.contains(m)) {
        _selectedMuscles.remove(m);
      } else {
        _selectedMuscles.add(m);
      }
    });
  }

  void _addStep() {
    if (_stepCtrls.length >= _maxSteps) return;
    setState(() => _stepCtrls.add(_StepCtrl()));
  }

  void _removeStep(int index) {
    if (_stepCtrls.length <= 1) return;
    setState(() => _stepCtrls.removeAt(index).dispose());
  }

  void _addKeyPose(int stepIdx) {
    final kp = _stepCtrls[stepIdx].keyPoses;
    if (kp.length >= _maxKeyPoses) return;
    setState(() => kp.add(TextEditingController()));
  }

  void _removeKeyPose(int stepIdx, int kpIdx) {
    final kp = _stepCtrls[stepIdx].keyPoses;
    if (kp.length <= 1) return;
    setState(() => kp.removeAt(kpIdx).dispose());
  }

  Future<void> _pickCover() async {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_outlined, color: colors.textSecondary),
              title: Text('从相册选择',
                  style: TextStyle(color: colors.textPrimary, fontSize: 15)),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined,
                  color: colors.textSecondary),
              title: Text('拍照',
                  style: TextStyle(color: colors.textPrimary, fontSize: 15)),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading:
                  Icon(Icons.image_aspect_ratio, color: colors.textSecondary),
              title: Text('使用默认封面',
                  style: TextStyle(color: colors.textPrimary, fontSize: 15)),
              onTap: () => Navigator.of(ctx).pop('default'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    if (action == 'default') {
      setState(() => _coverImagePath = null);
      return;
    }
    final source = action == 'gallery'
        ? ImageSource.gallery
        : ImageSource.camera;
    final picker = ImagePicker();
    try {
      final xfile = await picker.pickImage(source: source, imageQuality: 85);
      if (xfile == null || !mounted) return;

      // 将选中的图片复制到应用文档目录，避免使用系统临时目录导致重启后失效
      final dir = await getApplicationDocumentsDirectory();
      final coverDir = Directory('${dir.path}/custom_exercise_covers');
      if (!coverDir.existsSync()) {
        coverDir.createSync(recursive: true);
      }
      final ext = xfile.path.contains('.') ? xfile.path.split('.').last : 'jpg';
      final safeExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext) ? ext : 'jpg';
      final target = '${coverDir.path}/cover_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      await File(xfile.path).copy(target);
      if (!mounted) return;
      setState(() => _coverImagePath = target);
      FitToast.success(context, '封面图片已选择');
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '选择图片失败，请检查相册权限后重试');
      }
    }
  }

  void _onSave() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入动作名称')),
      );
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入动作描述')),
      );
      return;
    }
    if (_stepCtrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个步骤')),
      );
      return;
    }
    final steps = _stepCtrls.map((s) => <String, dynamic>{
      'title': s.title.text.trim(),
      'desc': s.desc.text.trim(),
      'keyPoses': s.keyPoses
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    }).toList();
    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'category': _selectedCategory,
      'equip': _equipCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'muscles': List<String>.from(_selectedMuscles),
      'steps': steps,
    };
    if (_coverImagePath != null) data['image'] = _coverImagePath;
    Storage.addCustomExercise(data);
    widget.onSaved();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(colors),
        Divider(height: 1, color: colors.borderColor.withOpacity(0.5)),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverPicker(colors),
                const SizedBox(height: 14),
                _buildNameField(colors),
                const SizedBox(height: 14),
                _buildCategoryChips(colors),
                const SizedBox(height: 14),
                _buildEquipField(colors),
                const SizedBox(height: 14),
                _buildDescField(colors),
                const SizedBox(height: 14),
                _buildMusclesChips(colors),
                const SizedBox(height: 18),
                _buildStepsSection(colors),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: colors.borderColor.withOpacity(0.5))),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('保存',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(LiftTrackColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
      child: Row(
        children: [
          Icon(Icons.add_circle, size: 20, color: colors.accentGlow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '添加动作',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: colors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(LiftTrackColors colors, String text, {String? hint}) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(width: 6),
          Text(
            hint,
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }

  InputDecoration _fieldDecoration(LiftTrackColors colors, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
      filled: true,
      fillColor: colors.bgCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colors.accentGlow),
      ),
    );
  }

  Widget _buildCoverPicker(LiftTrackColors colors) {
    final hasCustom = _coverImagePath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '封面图', hint: '可选'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickCover,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasCustom)
                    Image.file(
                      File(_coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => DefaultExerciseCover(
                        category: _selectedCategory,
                        size: 160,
                      ),
                    )
                  else
                    DefaultExerciseCover(
                      category: _selectedCategory,
                      size: 160,
                    ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit,
                              size: 13, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            hasCustom ? '点击更换封面' : '点击选择封面',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '动作名称', hint: '必填'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: _fieldDecoration(colors, hint: '如：杠铃卧推'),
        ),
      ],
    );
  }

  Widget _buildEquipField(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '器械'),
        const SizedBox(height: 6),
        TextField(
          controller: _equipCtrl,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: _fieldDecoration(colors, hint: '如：杠铃 / 哑铃 / 自重'),
        ),
      ],
    );
  }

  Widget _buildDescField(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '动作描述', hint: '必填'),
        const SizedBox(height: 6),
        TextField(
          controller: _descCtrl,
          maxLines: 3,
          style: TextStyle(color: colors.textPrimary, fontSize: 14),
          decoration: _fieldDecoration(colors, hint: '描述动作要点与目标'),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '分类'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((c) {
            final active = c == _selectedCategory;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = c),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? colors.accentGlow.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? colors.accentGlow : colors.borderColor,
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: active ? colors.accentGlow : colors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMusclesChips(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(colors, '目标肌群', hint: '可多选'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _muscleCandidates.map((m) {
            final active = _selectedMuscles.contains(m);
            return GestureDetector(
              onTap: () => _toggleMuscle(m),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? colors.accentGlow : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? colors.accentGlow : colors.borderColor,
                  ),
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    color: active ? colors.textPrimary : colors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepsSection(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel(colors, '训练步骤', hint: '最多 $_maxSteps 步'),
            const Spacer(),
            if (_stepCtrls.length < _maxSteps)
              TextButton.icon(
                onPressed: _addStep,
                icon: Icon(Icons.add, size: 16, color: colors.accentGlow),
                label: Text('添加步骤',
                    style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._stepCtrls.asMap().entries.map((entry) {
          return _buildStepCard(colors, entry.key, entry.value);
        }),
      ],
    );
  }

  Widget _buildStepCard(LiftTrackColors colors, int idx, _StepCtrl step) {
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
          // Step header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: colors.borderColor)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: colors.accentGlow,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        color: colors.bgCard,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '步骤 ${idx + 1}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_stepCtrls.length > 1)
                  GestureDetector(
                    onTap: () => _removeStep(idx),
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 14, color: colors.warningColor),
                        const SizedBox(width: 2),
                        Text('删除步骤',
                            style: TextStyle(
                                color: colors.warningColor, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Step body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: step.title,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration:
                      _fieldDecoration(colors, hint: '步骤标题'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: step.desc,
                  maxLines: 2,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration:
                      _fieldDecoration(colors, hint: '步骤描述'),
                ),
                const SizedBox(height: 10),
                // Key poses
                Row(
                  children: [
                    Icon(Icons.center_focus_strong,
                        size: 13, color: colors.accentGlow),
                    const SizedBox(width: 4),
                    Text(
                      '关键姿势',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.accentGlow,
                      ),
                    ),
                    const Spacer(),
                    if (step.keyPoses.length < _maxKeyPoses)
                      GestureDetector(
                        onTap: () => _addKeyPose(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 13, color: colors.accentGlow),
                              const SizedBox(width: 2),
                              Text('添加',
                                  style: TextStyle(
                                      color: colors.accentGlow,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                ...step.keyPoses.asMap().entries.map((e) {
                  final kpIdx = e.key;
                  final ctrl = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colors.accentGlow,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            style: TextStyle(
                                color: colors.textPrimary, fontSize: 12),
                            decoration: _fieldDecoration(colors,
                                hint: '关键姿势 ${kpIdx + 1}'),
                          ),
                        ),
                        if (step.keyPoses.length > 1)
                          GestureDetector(
                            onTap: () => _removeKeyPose(idx, kpIdx),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.close,
                                  size: 16, color: colors.textMuted),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
