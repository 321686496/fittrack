import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../widgets/simulated_ad_page.dart';
import 'points_service.dart';
import '../router.dart';

enum AdPosition { rewarded, nativeBanner, splash }
enum AdResult { success, notAvailable, userDismissed, error }

abstract class AdService {
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
    if (Storage.getSettings()['adsEnabled'] != true) return false;
    return true;
  }

  @override
  Future<AdResult> showRewardedVideo() async {
    if (Storage.getSettings()['adsEnabled'] != true) return AdResult.notAvailable;
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
    if (Storage.getSettings()['adsEnabled'] != true) return const SizedBox.shrink();
    return const SizedBox.shrink();
  }

  @override
  Future<void> maybeShowSplashAd() async {}

  @override
  Future<void> disableAds() async {}
}
