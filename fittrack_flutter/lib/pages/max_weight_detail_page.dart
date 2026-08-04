// lib/pages/max_weight_detail_page.dart
// 最大重量详情页：PageHeader + 总览卡 + 按部位分组的 Top 5 动作列表。
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/weight_comparisons.dart';
import '../services/max_weight_service.dart';
import '../widgets/page_header.dart';

class MaxWeightDetailPage extends StatelessWidget {
  const MaxWeightDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    final globalMax = MaxWeightService.instance.getGlobalMax();
    final muscleGroups = MaxWeightService.instance.getTopByMuscleGroup();

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '最大重量纪录',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: globalMax == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: ft.textMuted),
                        const SizedBox(height: 16),
                        Text('暂无最大重量记录',
                            style: TextStyle(color: ft.textMuted, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('开始训练并记录你的重量',
                            style: TextStyle(color: ft.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGlobalCard(globalMax, ft),
                      const SizedBox(height: 24),
                      ...MaxWeightService.kMuscleGroups
                          .where((g) =>
                              muscleGroups.containsKey(g) &&
                              muscleGroups[g]!.isNotEmpty)
                          .map((g) => _buildGroupSection(g, muscleGroups[g]!, ft)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalCard(MaxWeightRecord record, LiftTrackColors ft) {
    final comparison = WeightComparison.forWeight(record.weight);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ft.accentGlow.withOpacity(0.12), ft.bgCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: ft.warningColor, size: 18),
              const SizedBox(width: 6),
              Text(
                '总纪录',
                style: TextStyle(
                  fontSize: 14,
                  color: ft.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${record.weight.toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: ft.accentGlow,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${comparison.emoji} 相当于${comparison.label}',
            style: TextStyle(fontSize: 14, color: ft.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            '${record.exerciseName} · ${record.date.year}/${record.date.month}/${record.date.day}',
            style: TextStyle(fontSize: 12, color: ft.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(
      String group, List<MaxWeightRecord> records, LiftTrackColors ft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '$group Top ${records.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ft.textPrimary,
            ),
          ),
        ),
        ...records.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: ft.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ft.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.exerciseName,
                          style: TextStyle(
                            color: ft.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.date.month}/${r.date.day}',
                          style: TextStyle(
                            color: ft.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${r.weight.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      color: ft.accentGlow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
