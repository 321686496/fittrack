import 'package:flutter/material.dart';
import '../data/storage.dart';

enum AdPosition { rewarded, nativeBanner, splash }
enum AdResult { success, notAvailable, userDismissed, error }

abstract class AdService {
  static final AdService instance = _NoOpAdService();

  bool shouldShowRewarded();
  Future<AdResult> showRewardedVideo();
  Widget getNativeBannerWidget();
  Future<void> maybeShowSplashAd();
  Future<void> disableAds();
}

class _NoOpAdService implements AdService {
  @override
  bool shouldShowRewarded() {
    if (Storage.isPremiumNotifier.value) return false;
    return true; // Would show in production, but showRewardedVideo returns notAvailable
  }

  @override
  Future<AdResult> showRewardedVideo() async {
    if (Storage.isPremiumNotifier.value) return AdResult.notAvailable;
    // No SDK integrated in Phase 2.0
    return AdResult.notAvailable;
  }

  @override
  Widget getNativeBannerWidget() {
    if (Storage.isPremiumNotifier.value) return const SizedBox.shrink();
    return const SizedBox.shrink(); // No-op: returns empty widget
  }

  @override
  Future<void> maybeShowSplashAd() async {
    if (Storage.isPremiumNotifier.value) return;
    // No-op in Phase 2.0
  }

  @override
  Future<void> disableAds() async {
    // Already gated by isPremiumNotifier; no further action needed
  }
}
