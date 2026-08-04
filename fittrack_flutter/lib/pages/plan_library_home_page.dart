// lib/pages/plan_library_home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/system_plan_library.dart';
import '../themes/app_themes.dart';
import '../widgets/page_header.dart';

class PlanLibraryHomePage extends StatelessWidget {
  const PlanLibraryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '系统训练计划库',
            subtitle: '选择你的训练目标',
            onBack: () => Navigator.of(context).pop(),
            onSearchTap: () => context.push('/plan-search'),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '选择你的训练目标',
                      style: TextStyle(
                        color: ft.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final goal = kPlanGoals[index];
                        return _GoalCard(goal: goal);
                      },
                      childCount: kPlanGoals.length,
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
}

class _GoalCard extends StatelessWidget {
  final String goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final plans = SystemPlanLibrary.instance.getByGoal(goal);
    final premiumCount = plans.where((p) => p.isPremium).length;
    final label = kGoalLabelsZh[goal] ?? goal;
    final emoji = _goalEmoji(goal);
    final colors = _goalColors(goal);

    return GestureDetector(
      onTap: () => context.push('/plan-library/$goal'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12,
              top: 12,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${plans.length}个计划',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '含 $premiumCount 个精品',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalEmoji(String goal) {
    switch (goal) {
      case 'bulk':
        return '💪';
      case 'cut':
        return '🔥';
      case 'shape':
        return '🧘';
      case 'keep':
        return '❤️';
      case 'strength':
        return '⚡';
      default:
        return '🏋️';
    }
  }

  List<Color> _goalColors(String goal) {
    switch (goal) {
      case 'bulk':
        return [const Color(0xFFE89B9B), const Color(0xFFC47070)];
      case 'cut':
        return [const Color(0xFFE8B97A), const Color(0xFFC4914D)];
      case 'shape':
        return [const Color(0xFFB5C5E0), const Color(0xFF8FA3C7)];
      case 'keep':
        return [const Color(0xFFA8D5BA), const Color(0xFF7AB593)];
      case 'strength':
        return [const Color(0xFFC5B0D8), const Color(0xFF9C82B8)];
      default:
        return [const Color(0xFFB0B0B0), const Color(0xFF808080)];
    }
  }
}
