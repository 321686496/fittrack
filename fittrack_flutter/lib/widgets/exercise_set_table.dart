import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

/// 逐组配置表格：展示动作逐组设置的次数/重量/休息
///
/// 供训练日编辑器（add_plan_page / plan_page）与计划详情页共用，
/// 保证「逐组设置」模式下各页面展示全部组数据而非仅第一组。
class ExerciseSetTable extends StatelessWidget {
  final List setConfig;

  const ExerciseSetTable({super.key, required this.setConfig});

  static String formatWeight(dynamic w) {
    if (w == null) return '-';
    final d = (w is num) ? w.toDouble() : double.tryParse('$w') ?? 0;
    return d == d.toInt().toDouble() ? '${d.toInt()}' : '$d';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: colors.borderColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('组', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text('次数', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('重量', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('休息', style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ...setConfig.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value as Map;
            final isLast = idx == setConfig.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: isLast ? BorderSide.none : BorderSide(color: colors.borderColor.withOpacity(0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text('第${idx + 1}组', style: TextStyle(color: colors.textSecondary, fontSize: 11))),
                  Expanded(flex: 3, child: Text('${s['reps'] ?? '-'}', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text('${formatWeight(s['weight'])}kg', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.center)),
                  Expanded(flex: 3, child: Text('${s['restTime'] ?? 90}秒', style: TextStyle(color: colors.textPrimary, fontSize: 11), textAlign: TextAlign.right)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
