import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';
import 'common_widgets.dart';

class RatingPromptSheet {
  static const Duration _cooldown = Duration(days: 30);

  static bool shouldShow() {
    final settings = Storage.getSettings();
    if (settings['ratingPromptNeverAsk'] == true) return false;
    final lastShown = settings['ratingPromptLastShown'] as int? ?? 0;
    final since = DateTime.now().millisecondsSinceEpoch - lastShown;
    if (since < _cooldown.inMilliseconds) return false;
    final stats = Storage.getStats();
    final totalTrainings = stats['totalTrainings'] as int? ?? 0;
    return totalTrainings >= 2;
  }

  static Future<void> maybeShow(BuildContext context) async {
    if (!shouldShow()) return;
    final settings = Storage.getSettings();
    settings['ratingPromptLastShown'] =
        DateTime.now().millisecondsSinceEpoch;
    Storage.saveSettings(settings);
    final total = (Storage.getStats()['totalTrainings'] as int?) ?? 0;

    if (!context.mounted) return;
    await FitBottomSheet.show(
      context: context,
      builder: (ctx) => _RatingSheet(
        totalTrainings: total,
        onRate: () => _openStore(ctx),
        onLater: () => Navigator.pop(ctx),
        onNeverAsk: () async {
          Navigator.pop(ctx);
          final s = Storage.getSettings();
          s['ratingPromptNeverAsk'] = true;
          Storage.saveSettings(s);
        },
      ),
    );
  }

  static void _openStore(BuildContext context) {
    Navigator.pop(context);
    // Phase 2: no url_launcher dependency
    // Real implementation in Phase 3: use url_launcher to open market://details?id=...
  }
}

class _RatingSheet extends StatelessWidget {
  final int totalTrainings;
  final VoidCallback onRate;
  final VoidCallback onLater;
  final VoidCallback onNeverAsk;

  const _RatingSheet({
    required this.totalTrainings,
    required this.onRate,
    required this.onLater,
    required this.onNeverAsk,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final total = totalTrainings;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 64),
          const SizedBox(height: 16),
          Text(
            '你已经用 LiftTrack 完成了 $total 次训练！',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '给个好评让更多独立开发者坚持下去吧',
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star),
              label: const Text('去评分'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onLater, child: const Text('稍后再说')),
          TextButton(
            onPressed: onNeverAsk,
            child: Text(
              '不再提醒',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
