import 'package:flutter/material.dart';
import '../widgets/simulated_ad_page.dart';
import 'points_service.dart';
import '../router.dart';
import '../data/storage.dart';

enum AdPosition { rewarded, nativeBanner, splash }
enum AdResult { success, notAvailable, userDismissed, error }

abstract class AdService {
  /// 开发者控制：是否启用广告功能（发布时设为 true，开发时可设为 false）
  static const bool adsEnabled = false;

  static final AdService instance = SimulatedAdService();

  bool shouldShowRewarded();
  Future<AdResult> showRewardedVideo();
  Widget getNativeBannerWidget();
  Future<void> maybeShowSplashAd();
  Future<void> disableAds();
}

class SimulatedAdService implements AdService {
  @override
  bool shouldShowRewarded() {
    if (!AdService.adsEnabled) return false;
    if (Storage.isPremiumNotifier.value) return false; // Pro 用户不看广告
    return true;
  }

  @override
  Future<AdResult> showRewardedVideo() async {
    if (!AdService.adsEnabled) return AdResult.notAvailable;
    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx == null) return AdResult.error;
    final result = await Navigator.of(navCtx).push<bool>(
      MaterialPageRoute(
        builder: (_) => SimulatedAdPage(onComplete: () {
          Navigator.of(navCtx).pop(true);
        }),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      await PointsService.instance.recordAdWatched();
      return AdResult.success;
    }
    return AdResult.userDismissed;
  }

  @override
  Widget getNativeBannerWidget() {
    if (!AdService.adsEnabled) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  @override
  Future<void> maybeShowSplashAd() async {}

  @override
  Future<void> disableAds() async {}
}
