import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';

class CelebrationDialog {
  static Future<void> show(BuildContext context, {
    required int totalWeight,
    required int totalSets,
    required int duration,
    required String recordId,
    required int earnedPoints,
  }) async {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final streak = _calcStreak();
    final messages = _getEmotionalMessages(streak, totalWeight);
    final message = messages[DateTime.now().millisecond % messages.length];

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 庆祝图标
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentGlow, colors.accentGlow.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text('训练完成！', style: TextStyle(
                color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 8),
              Text(message, style: TextStyle(
                color: colors.textSecondary, fontSize: 14, height: 1.4,
              ), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // 训练数据摘要
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat(colors, '${totalWeight}kg', '总重量'),
                  _stat(colors, '$totalSets', '总组数'),
                  _stat(colors, '${duration}min', '时长'),
                  if (earnedPoints > 0)
                    _stat(colors, '+$earnedPoints', '本次积分',
                          icon: Icons.stars, iconColor: colors.accentGlow),
                ],
              ),
              const SizedBox(height: 24),
              // 主按钮：记录心得
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/note/edit/record_$recordId');
                  },
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('记录今日心得', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 次按钮：返回首页
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('返回首页', style: TextStyle(color: colors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _stat(LiftTrackColors colors, String value, String label,
      {IconData? icon, Color? iconColor}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? colors.accentGlow),
              const SizedBox(width: 2),
            ],
            Text(value, style: TextStyle(
              color: iconColor ?? colors.textPrimary,
              fontSize: 16, fontWeight: FontWeight.bold,
            )),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: colors.textSecondary, fontSize: 11,
        )),
      ],
    );
  }

  static int _calcStreak() {
    final records = Storage.getRecords();
    if (records.isEmpty) return 0;
    final dates = <String>{};
    for (final r in records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
    }
    var streak = 0;
    var checkDate = DateTime.now();
    while (dates.contains('${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static List<String> _getEmotionalMessages(int streak, int totalWeight) {
    if (streak >= 7) {
      return [
        '连续训练第$streak天，你已经超越了90%的用户！',
        '坚持就是力量！连续$streak天，你正在成为更好的自己。',
        '$streak天不间断，这就是坚持的力量！',
      ];
    }
    if (totalWeight > 1000) {
      return [
        '今日总重量${totalWeight}kg，你的肌肉在欢呼！',
        '每一次举起，都是对自我的超越。继续加油！',
        '今天的你，比昨天更强了一点。',
      ];
    }
    return [
      '完成训练只是开始，坚持才是答案。',
      '今天的汗水，是明天的收获。',
      '每一次训练，都让你离目标更近一步。',
    ];
  }
}
