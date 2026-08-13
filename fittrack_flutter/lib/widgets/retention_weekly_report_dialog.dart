import 'package:flutter/material.dart';
import '../services/retention_chain_service.dart';
import '../themes/app_themes.dart';

/// v1 新手7天留存链 —— Day7 首份周报弹窗
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md V1-04-04
/// 验收标准：本地计算本周训练天数/总重量/连续打卡 + "你已经用LiftTrack一周了"
///
/// 设计风格：Morandi 色调，信息层级从重到轻，双列卡片网格
class RetentionWeeklyReportDialog extends StatelessWidget {
  final RetentionWeeklyReport report;
  final VoidCallback? onDismiss;

  const RetentionWeeklyReportDialog({
    super.key,
    required this.report,
    this.onDismiss,
  });

  static Future<void> show(BuildContext context, RetentionWeeklyReport report) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RetentionWeeklyReportDialog(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Dialog(
      backgroundColor: colors.bgSecondary,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(colors),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(colors),
                    const SizedBox(height: 4),
                    _buildSubtitle(colors),
                    const SizedBox(height: 18),
                    _buildStatsGrid(colors),
                    const SizedBox(height: 16),
                    _buildWeightAnalogy(colors),
                    if (report.trainedMuscles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildMuscleChips(colors),
                    ],
                    const SizedBox(height: 18),
                    _buildStreakBanner(colors),
                    const SizedBox(height: 20),
                    _buildActions(colors, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 顶部装饰区 ─────────────────────────────────────────────

  Widget _buildHeader(LiftTrackColors colors) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accentGlow.withOpacity(0.85),
            colors.accentGlow.withOpacity(0.55),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            top: 14,
            child: Icon(Icons.emoji_events,
                size: 72, color: Colors.white.withOpacity(0.18)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 14, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text(
                      'LiftTrack · 7日周报',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '你已经用 LiftTrack 一周了',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 标题区 ─────────────────────────────────────────────────

  Widget _buildTitle(LiftTrackColors colors) {
    return Text(
      '本周战绩汇总',
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildSubtitle(LiftTrackColors colors) {
    final d = report.firstTrainingDate;
    final dateStr = '${d.month}月${d.day}日加入';
    return Text(
      '自$dateStr起，你的训练档案已建立',
      style: TextStyle(
        color: colors.textMuted,
        fontSize: 12,
      ),
    );
  }

  // ── 数据网格（双列布局） ───────────────────────────────────

  Widget _buildStatsGrid(LiftTrackColors colors) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            colors,
            icon: Icons.event_available,
            label: '训练天数',
            value: '${report.trainingDays}',
            unit: '天',
            highlight: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            colors,
            icon: Icons.fitness_center,
            label: '总重量',
            value: '${report.totalWeight}',
            unit: 'kg',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    LiftTrackColors colors, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    bool highlight = false,
  }) {
    final bg = highlight
        ? colors.accentGlow.withOpacity(0.08)
        : colors.bgCard.withOpacity(0.6);
    final valueColor = highlight ? colors.accentGlow : colors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? colors.accentGlow.withOpacity(0.25)
              : colors.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.accentGlow),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: valueColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 趣味类比 ───────────────────────────────────────────────

  Widget _buildWeightAnalogy(LiftTrackColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.accentGlow.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              size: 16, color: colors.accentGlow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${report.weightAnalogy} · 累计训练 ${report.durationText}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 训练肌群标签 ───────────────────────────────────────────

  Widget _buildMuscleChips(LiftTrackColors colors) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final m in report.trainedMuscles.take(6))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              m,
              style: TextStyle(
                color: colors.accentGlow,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ── 连续打卡横幅 ───────────────────────────────────────────

  Widget _buildStreakBanner(LiftTrackColors colors) {
    if (report.streak <= 0) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accentGlow.withOpacity(0.12),
            colors.accentGlow.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              size: 20, color: colors.accentGlow),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已连续打卡 ${report.streak} 天，保持节奏!',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 操作按钮 ───────────────────────────────────────────────

  Widget _buildActions(LiftTrackColors colors, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('稍后再看'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentGlow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 0,
            ),
            child: const Text(
              '继续加油',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
