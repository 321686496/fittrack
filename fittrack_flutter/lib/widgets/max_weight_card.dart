// lib/widgets/max_weight_card.dart
// MaxWeightCard：展示全局最大重量 + 趣味对比 + "查看详情 →" 入口。
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../services/max_weight_service.dart';
import '../data/weight_comparisons.dart';
import 'common_widgets.dart';

class MaxWeightCard extends StatelessWidget {
  final VoidCallback? onTap;

  const MaxWeightCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    final globalMax = MaxWeightService.instance.getGlobalMax();

    if (globalMax == null) {
      // 空状态
      return CardWidget(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: ft.textMuted, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '开始训练记录你的最大重量',
                  style: TextStyle(color: ft.textMuted, fontSize: 14),
                ),
              ),
              Icon(Icons.chevron_right, color: ft.textMuted),
            ],
          ),
        ),
      );
    }

    final comparison = WeightComparison.forWeight(globalMax.weight);

    return CardWidget(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Icon(Icons.fitness_center, color: ft.accentGlow, size: 22),
                const SizedBox(width: 8),
                Text(
                  '举起最大重量',
                  style: TextStyle(
                    color: ft.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '查看详情 →',
                  style: TextStyle(color: ft.accentGlow, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 大数字
            Center(
              child: Text(
                '${globalMax.weight.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: ft.accentGlow,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 趣味对比
            Center(
              child: Text(
                '${comparison.emoji} 相当于${comparison.label}',
                style: TextStyle(color: ft.textSecondary, fontSize: 14),
              ),
            ),
            const SizedBox(height: 12),
            // 最近一次
            Center(
              child: Text(
                '最近一次：${globalMax.exerciseName} · ${_formatDate(globalMax.date)}',
                style: TextStyle(color: ft.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays <= 1) return '今天';
    if (diff.inDays <= 7) return '${diff.inDays}天前';
    return '${d.month}/${d.day}';
  }
}
