// lib/pages/max_weight_detail_page.dart
// 最大重量详情页：PageHeader + 总览卡 + 按部位分组的里程碑 + Top 5 动作列表。
// 无记录时展示全部里程碑概览，引导用户了解各部位目标。
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
    final maxByGroup = MaxWeightService.instance.getMaxByMuscleGroup();

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
                ? _buildMilestoneOverview(ft)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGlobalCard(globalMax, ft),
                      const SizedBox(height: 24),
                      // 里程碑总览
                      _buildMilestoneSummarySection(maxByGroup, ft),
                      const SizedBox(height: 24),
                      // 各部位 Top 5
                      ...MaxWeightService.kMuscleGroups
                          .where((g) =>
                              muscleGroups.containsKey(g) &&
                              muscleGroups[g]!.isNotEmpty)
                          .map((g) => _buildGroupSection(
                              g, muscleGroups[g]!, ft)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── 无记录时的里程碑概览页 ──────────────────────────────────────
  Widget _buildMilestoneOverview(LiftTrackColors ft) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 引导头部
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ft.accentGlow.withOpacity(0.08), ft.bgCard],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ft.borderColor),
          ),
          child: Column(
            children: [
              Icon(Icons.emoji_events, color: ft.warningColor, size: 40),
              const SizedBox(height: 12),
              Text(
                '最大重量里程碑',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ft.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '挑战以下重量目标，逐一解锁里程碑\n开始训练，记录你的每一次突破',
                textAlign: TextAlign.center,
                style: TextStyle(color: ft.textSecondary, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 各部位里程碑
        ...MaxWeightService.kMuscleGroups.map((g) => _buildMilestoneSection(g, null, ft)),
      ],
    );
  }

  // ── 有记录时的里程碑总览 ──────────────────────────────────────
  Widget _buildMilestoneSummarySection(
      Map<String, double> maxByGroup, LiftTrackColors ft) {
    int totalAchieved = 0;
    int totalMilestones = 0;
    for (final g in MaxWeightService.kMuscleGroups) {
      final milestones = MaxWeightService.kMuscleGroupMilestones[g] ?? [];
      totalMilestones += milestones.length;
      final max = maxByGroup[g];
      if (max != null) {
        totalAchieved += milestones.where((m) => max >= m).length;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: ft.accentGlow, size: 20),
              const SizedBox(width: 8),
              Text(
                '里程碑进度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ft.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$totalAchieved / $totalMilestones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ft.accentGlow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalMilestones > 0 ? totalAchieved / totalMilestones : 0,
              backgroundColor: ft.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(ft.accentGlow),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          // 各部位里程碑速览
          ...MaxWeightService.kMuscleGroups.map((g) {
            final max = maxByGroup[g];
            return _buildMilestoneSection(g, max, ft);
          }),
        ],
      ),
    );
  }

  // ── 单个部位的里程碑展示（有无记录通用） ──────────────────────
  Widget _buildMilestoneSection(
      String group, double? currentMax, LiftTrackColors ft) {
    final milestones = MaxWeightService.kMuscleGroupMilestones[group] ?? [];
    final achievedCount = currentMax != null
        ? milestones.where((m) => currentMax >= m).length
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 部位标题行
          Row(
            children: [
              Text(
                group,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ft.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (currentMax != null)
                Text(
                  '当前 ${currentMax.toStringAsFixed(1)} kg',
                  style: TextStyle(fontSize: 12, color: ft.accentGlow),
                )
              else
                Text(
                  '尚未记录',
                  style: TextStyle(fontSize: 12, color: ft.textMuted),
                ),
              const Spacer(),
              if (milestones.isNotEmpty)
                Text(
                  '$achievedCount/${milestones.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: achievedCount > 0 ? ft.accentGlow : ft.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 里程碑徽章列表
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: milestones.map((m) {
              final achieved = currentMax != null && currentMax >= m;
              final isNext = !achieved &&
                  currentMax != null &&
                  milestones.where((mm) => currentMax < mm).isNotEmpty &&
                  m == milestones.firstWhere((mm) => currentMax < mm,
                      orElse: () => m);
              return _buildMilestoneChip(m, achieved, isNext, ft);
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 里程碑徽章 ──────────────────────────────────────────────
  Widget _buildMilestoneChip(
      double weight, bool achieved, bool isNext, LiftTrackColors ft) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (achieved) {
      bgColor = ft.accentGlow.withOpacity(0.15);
      borderColor = ft.accentGlow.withOpacity(0.4);
      textColor = ft.accentGlow;
      icon = Icons.check_circle;
    } else if (isNext) {
      bgColor = ft.warningColor.withOpacity(0.1);
      borderColor = ft.warningColor.withOpacity(0.5);
      textColor = ft.warningColor;
      icon = Icons.flag;
    } else {
      bgColor = ft.bgCard;
      borderColor = ft.borderColor;
      textColor = ft.textMuted;
      icon = Icons.lock_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '${weight.toStringAsFixed(weight == weight.roundToDouble() ? 0 : 1)} kg',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
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
