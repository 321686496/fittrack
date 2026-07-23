import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

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
    var list = MockData.exercises;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: _selectedExercise != null
          ? _buildDetailView(colors)
          : _buildListView(colors),
    );
  }

  Widget _buildListView(FitTrackColors colors) {
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
          height: 44,
          margin: const EdgeInsets.only(top: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            Container(
                              height: 90,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: colors.bgElevated,
                                image: ex['image'] != null
                                    ? DecorationImage(
                                        image: AssetImage(
                                            ex['image'] as String),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
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

  Widget _buildDetailView(FitTrackColors colors) {
    final ex = _selectedExercise!;
    final exId = ex['id'] as String;
    final description =
        MockData.exerciseDescriptions[exId] ?? '暂无描述';
    final muscles = MockData.exerciseMuscles[exId] ?? [];
    final steps = MockData.exerciseSteps[exId] ?? [];

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
                if (ex['image'] != null)
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: colors.bgElevated,
                      image: DecorationImage(
                        image: AssetImage(ex['image'] as String),
                        fit: BoxFit.cover,
                      ),
                    ),
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
                // Add to plan button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPlanPicker(ex),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('添加到计划'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentGlow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(FitTrackColors colors, int stepNum, Map<String, dynamic> step) {
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
              height: 140,
              decoration: BoxDecoration(
                color: colors.bgElevated,
                image: DecorationImage(
                  image: NetworkImage(step['image'] as String),
                  fit: BoxFit.cover,
                ),
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
    final colors = Theme.of(context).extension<FitTrackColors>()!;

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

  Widget _buildHeader(FitTrackColors colors) {
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
                          color: active ? Colors.black : colors.textMuted,
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
  Widget _buildPlanList(FitTrackColors colors) {
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
  Widget _buildDayList(FitTrackColors colors) {
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
  Widget _buildConfigView(FitTrackColors colors) {
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

  Widget _buildPerSetEditor(FitTrackColors colors, int sets) {
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

  Widget _buildPerSetRow(FitTrackColors colors, int index) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.borderColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.borderColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: colors.accentGlow)),
        ),
      ),
    );
  }

  Widget _buildLabelRow(FitTrackColors colors, String label, String hint) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(hint, style: TextStyle(color: colors.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildStepperRow(FitTrackColors colors, {
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

  Widget _buildNumBtn(FitTrackColors colors, IconData icon, VoidCallback onTap) {
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

  Widget _buildBottomBar(FitTrackColors colors) {
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
                  foregroundColor: Colors.black,
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
