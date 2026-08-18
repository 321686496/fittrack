import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';
import '../utils/platform_utils.dart';
import 'common_widgets.dart';

class RatingPromptSheet {
  static const Duration _cooldown = Duration(days: 30);

  // 各应用市场中的应用标识（上架后保持与各市场后台一致）
  static const String _androidPackage = 'com.lt.lifttrack';
  static const String _ohosBundleName = 'com.fp.fitplan';
  // App Store 中的 Apple ID（App Store Connect 后台可查，上架后填写）
  static const String _iosAppStoreId = '';

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

  /// 构造跳转应用市场详情页的 URI。
  /// - Android：market:// 打开默认应用市场（华为/小米/OPPO/vivo/应用宝/Google Play 等）
  /// - OHOS：store:// 打开华为 AppGallery（url_launcher_ohos 的 appdetail 拉取方式）
  /// - iOS：itms-apps:// 打开 App Store 评分页
  /// 平台判定结果由调用方显式传入，便于在无真实设备环境下单测。
  /// iOS 未填写 Apple ID 时返回 null（不发起无效跳转）。
  static String? storeUriFor({required bool ohos, required bool ios}) {
    if (ohos) {
      return 'store://appgallery.huawei.com/app/detail?id=$_ohosBundleName';
    }
    if (ios) {
      if (_iosAppStoreId.isEmpty) return null;
      return 'itms-apps://itunes.apple.com/app/id$_iosAppStoreId?action=write-review';
    }
    return 'market://details?id=$_androidPackage';
  }

  /// 跳转到对应应用市场的 App 详情页，让用户去评分。
  /// 若市场链接无法打开（如未安装市场客户端），降级用浏览器打开网页版详情页。
  static Future<void> _openStore(BuildContext context) async {
    Navigator.pop(context);

    final uri = storeUriFor(ohos: isOhos, ios: isIos);
    if (uri == null) return;

    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched) {
      // 兜底：无市场客户端时打开网页版详情页
      if (isOhos) return; // AppGallery 无通用网页详情页，放弃
      final fallback = isIos
          ? 'https://apps.apple.com/app/id$_iosAppStoreId?action=write-review'
          : 'https://play.google.com/store/apps/details?id=$_androidPackage';
      try {
        await launchUrl(
          Uri.parse(fallback),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // 已尽力打开，失败时忽略（如离线设备）
      }
    }
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
