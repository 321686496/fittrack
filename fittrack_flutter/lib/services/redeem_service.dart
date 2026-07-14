import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../data/storage.dart';

enum RedeemResult {
  success,
  invalidFormat,
  invalidSignature,
  alreadyRedeemed,
}

class RedeemService {
  static final RedeemService instance = RedeemService._();
  RedeemService._();

  static const List<String> _secrets = [
    'fitTrack_secret_v1_2025',
    'fitTrack_secret_v2_2026',
  ];

  static final RegExp _pattern =
      RegExp(r'^FITT-([A-Z0-9]{4})-([A-Z0-9]{4})-([A-Z0-9]{4})$');

  Future<RedeemResult> verifyAndRedeem(String code) async {
    if (!_pattern.hasMatch(code)) return RedeemResult.invalidFormat;
    if (_isAlreadyRedeemed(code)) return RedeemResult.alreadyRedeemed;
    if (!_verifySignature(code)) return RedeemResult.invalidSignature;

    // Mark redeemed + unlock Pro (via Storage.setPremium, defined in Task 4)
    final list = getRedeemedCodes();
    list.add(code);
    final s = Storage.getSettings();
    s['redeemedCodes'] = list;
    await Storage.saveSettings(s);
    await Storage.setPremium(true, source: 'redeem_code');
    return RedeemResult.success;
  }

  bool _isAlreadyRedeemed(String code) {
    return getRedeemedCodes().contains(code);
  }

  List<String> getRedeemedCodes() {
    final s = Storage.getSettings();
    final list = s['redeemedCodes'];
    if (list is List) return list.cast<String>();
    return <String>[];
  }

  bool _verifySignature(String code) {
    // FITT-XXXX-XXXX-XXXX — last 4 chars are HMAC signature
    final content = code.substring(5, 14); // "XXXX-XXXX" (positions 5-13)
    final providedSig = code.substring(15); // last 4 chars
    for (final secret in _secrets) {
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(utf8.encode(content));
      final expected = digest.toString().substring(0, 4).toUpperCase();
      if (expected == providedSig) return true;
    }
    return false;
  }

  /// Generates a test code using the first secret — used by unit tests.
  /// Not exposed to production UI.
  String generateTestCode() {
    final rng = DateTime.now().millisecondsSinceEpoch;
    final randomPart = (rng.toRadixString(36).toUpperCase().padLeft(8, '0'))
        .substring(0, 8);
    final content = '${randomPart.substring(0, 4)}-${randomPart.substring(4)}';
    final hmac = Hmac(sha256, utf8.encode(_secrets.first));
    final digest = hmac.convert(utf8.encode(content));
    final sig = digest.toString().substring(0, 4).toUpperCase();
    return 'FITT-${content.substring(0, 4)}-${content.substring(5)}-$sig';
  }
}
