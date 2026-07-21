// lib/pages/plan_library_category_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/system_plan_library.dart';
import '../services/plan_unlock_service.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';

class PlanLibraryCategoryPage extends StatefulWidget {
  final String goal;
  const PlanLibraryCategoryPage({super.key, required this.goal});

  @override
  State<PlanLibraryCategoryPage> createState() =>
      _PlanLibraryCategoryPageState();
}

class _PlanLibraryCategoryPageState extends State<PlanLibraryCategoryPage> {
  String? _selectedDifficulty; // null = 全部
  final Set<String> _selectedTypes = {}; // 空集合 = 全部

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final allPlans = SystemPlanLibrary.instance.getByGoal(widget.goal);
    final filtered = allPlans.where((p) {
      if (_selectedDifficulty != null && p.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(p.trainingType)) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: kGoalLabelsZh[widget.goal] ?? widget.goal,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 难度筛选
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: _buildDifficultyChips(ft),
                  ),
                ),
                // 训练类型筛选
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildTrainingTypeChips(ft),
                  ),
                ),
                // 计划列表
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index.isOdd) {
                          return const SizedBox(height: 12);
                        }
                        return _PlanListCard(plan: filtered[index ~/ 2]);
                      },
                      childCount:
                          filtered.isEmpty ? 0 : filtered.length * 2 - 1,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChips(FitTrackColors ft) {
    final options = [null, ...kPlanDifficulties];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((d) {
        final selected = _selectedDifficulty == d;
        final label = d == null ? '全部难度' : kDifficultyLabelsZh[d];
        return ChoiceChip(
          label: Text(label!),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedDifficulty = selected ? null : d;
            });
          },
          selectedColor: ft.purpleColor,
          labelStyle: TextStyle(
            color: selected ? Colors.white : ft.textSecondary,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrainingTypeChips(FitTrackColors ft) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kPlanTrainingTypes.map((t) {
        final selected = _selectedTypes.contains(t);
        return FilterChip(
          label: Text(kTrainingTypeLabelsZh[t]!),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedTypes.add(t);
              } else {
                _selectedTypes.remove(t);
              }
            });
          },
          selectedColor: ft.infoColor,
          labelStyle: TextStyle(
            color: selected ? Colors.white : ft.textSecondary,
          ),
        );
      }).toList(),
    );
  }
}

class _PlanListCard extends StatelessWidget {
  final SystemPlan plan;
  const _PlanListCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    final isUnlocked = plan.isPremium &&
        PlanUnlockService.instance.isPlanUnlocked(plan.id);

    return GestureDetector(
      onTap: () => context.push('/plan-library/detail/${plan.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ft.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ft.borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧封面
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: plan.coverColors
                      .map((c) => Color(int.parse(c.substring(1), radix: 16) |
                          0xFF000000))
                      .toList(),
                ),
              ),
              child: Center(
                child: Text(
                  plan.coverEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            color: ft.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (plan.isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ft.warningColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '精品',
                            style: TextStyle(
                              color: ft.warningColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${kDifficultyLabelsZh[plan.difficulty]} · '
                    '${kTrainingTypeLabelsZh[plan.trainingType]} · '
                    '每周${plan.recommendedFrequency}练 · '
                    '${plan.totalWeeks}周',
                    style: TextStyle(color: ft.textSecondary, fontSize: 13),
                  ),
                  if (plan.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: plan.tags
                          .map((t) => Text(
                                '#$t',
                                style: TextStyle(
                                  color: ft.textMuted,
                                  fontSize: 12,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            // 右侧价格
            if (plan.isPremium)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isUnlocked)
                    Text(
                      '已解锁',
                      style: TextStyle(
                        color: ft.successColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    Text(
                      '${plan.pointsCost}',
                      style: TextStyle(
                        color: ft.warningColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '积分',
                      style: TextStyle(color: ft.textMuted, fontSize: 11),
                    ),
                  ],
                ],
              )
            else
              Text(
                '免费',
                style: TextStyle(
                  color: ft.successColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
