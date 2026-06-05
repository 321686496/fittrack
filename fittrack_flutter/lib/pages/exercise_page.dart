import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ExercisePage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const ExercisePage({super.key, required this.onNavigate});

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
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final plans = Storage.getPlans()
        .where((p) => p['status'] == 'active')
        .toList();

    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('暂无进行中的计划'),
          backgroundColor: colors.warningColor,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '添加到计划',
                  style: TextStyle(
                    color: colors.accentGlow,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '选择一个计划，将「${exercise['name']}」添加到第一天',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...plans.map((plan) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        _addExerciseToPlan(plan, exercise);
                        Navigator.pop(ctx);
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
                            Icon(Icons.assignment,
                                size: 20, color: colors.accentGlow),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                plan['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(Icons.add_circle_outline,
                                size: 20, color: colors.accentGlow),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addExerciseToPlan(
      Map<String, dynamic> plan, Map<String, dynamic> exercise) {
    final days = List<Map<String, dynamic>>.from(
      (plan['days'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    if (days.isNotEmpty) {
      final firstDayExercises = List<Map<String, dynamic>>.from(
        (days[0]['exercises'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      firstDayExercises.add({
        'id': exercise['id'],
        'name': exercise['name'],
        'sets': 3,
        'reps': '10-12',
        'restTime': 90,
      });
      days[0]['exercises'] = firstDayExercises;
    }
    Storage.updatePlan(plan['id'] as String, {'days': days});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加「${exercise['name']}」到「${plan['name']}」'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    if (_selectedExercise != null) {
      return _buildDetailView(colors);
    }
    return _buildListView(colors);
  }

  Widget _buildListView(FitTrackColors colors) {
    final filtered = _filteredExercises;

    return Column(
      children: [
        const PageHeader(title: '动作库', subtitle: '浏览所有训练动作'),
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
            style: const TextStyle(color: Colors.white, fontSize: 14),
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
                    childAspectRatio: 1.1,
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    colors.accentGlow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _categoryIcon(ex['category'] as String),
                                size: 24,
                                color: colors.accentGlow,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ex['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
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
                const SizedBox(height: 20),
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
}
