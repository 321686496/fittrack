import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/redeem_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  test('rejects malformed format', () async {
    final result = await RedeemService.instance.verifyAndRedeem('INVALID');
    expect(result, RedeemResult.invalidFormat);
  });

  test('rejects known invalid signature', () async {
    final result =
        await RedeemService.instance.verifyAndRedeem('FITT-AAAA-BBBB-CCCC');
    expect(result, RedeemResult.invalidSignature);
  });

  test('accepts a valid generated code', () async {
    // Generate a known-good code using the same secret
    final code = RedeemService.instance.generateTestCode();
    final result = await RedeemService.instance.verifyAndRedeem(code);
    expect(result, RedeemResult.success);
    // Second redemption should fail (already redeemed)
    final second = await RedeemService.instance.verifyAndRedeem(code);
    expect(second, RedeemResult.alreadyRedeemed);
  });
}
