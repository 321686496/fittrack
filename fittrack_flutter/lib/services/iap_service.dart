import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/storage.dart';

class IapService {
  static final IapService instance = IapService._();
  IapService._();

  static const String _proProductId = 'fittrack_pro_lifetime';
  static const Set<String> _proProductIds = {_proProductId};

  ValueNotifier<bool> get isPremium => Storage.isPremiumNotifier;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // OHOS and others: rely on redeem code path
      return;
    }
    final iap = InAppPurchase.instance;
    final available = await iap.isAvailable();
    if (!available) return;
    _sub = iap.purchaseStream.listen(_onPurchase);
    // Note: queryPastPurchases() was removed in in_app_purchase 3.0+.
    // The purchaseStream auto-delivers restored purchases when the
    // listener is attached.
  }

  Future<bool> purchasePro() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Use redeem code path on OHOS
    }
    final iap = InAppPurchase.instance;
    final resp = await iap.queryProductDetails(_proProductIds);
    if (resp.productDetails.isEmpty) return false;
    final product = resp.productDetails.first;
    final param = PurchaseParam(productDetails: product);
    return iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await InAppPurchase.instance.restorePurchases();
  }

  Future<void> markPremiumLocally(String source) async {
    await Storage.setPremium(true, source: source);
  }

  void _onPurchase(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.productID == _proProductId &&
          p.status == PurchaseStatus.purchased) {
        markPremiumLocally('iap');
        if (p.pendingCompletePurchase) {
          InAppPurchase.instance.completePurchase(p);
        }
      }
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
