import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/points_service.dart';
import 'package:fittrack_flutter/services/invitation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // PointsService.addPoints 触发 SoundService（创建 AudioPlayer 使用 MethodChannel），
  // mock audioplayers 通道避免 MissingPluginException
  TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async => null,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // Storage._store is static and not cleared between tests (see rating_prompt_test.dart).
    // 重置 settings 至默认值以保证测试隔离
    Storage.saveSettings(<String, dynamic>{});
    await Storage.init();
  });

  // Storage.getSettings() 每次返回新 Map，必须 saveSettings 才能持久化 deviceId 切换
  void useDeviceId(String id) {
    final s = Storage.getSettings();
    s['deviceId'] = id;
    Storage.saveSettings(s);
  }

  group('邀请奖励积分化', () {
    test('被邀请人激活应获得 50 积分', () async {
      // 模拟一个合法的邀请码（邀请人身份 ≠ 当前用户身份）
      // 通过 service 自身方法生成一个不同的邀请码
      final inviterDeviceId = 'inviter_device_seed_123';
      final inviteeDeviceId = 'invitee_device_seed_456';
      // 模拟 inviter 的邀请码：先生成，再用 invitee 身份激活
      // 由于 generateInvitationCode 依赖 deviceId，先设置 inviter 的
      useDeviceId(inviterDeviceId);
      final code = InvitationService.instance.generateInvitationCode();

      // 切到 invitee 身份
      useDeviceId(inviteeDeviceId);
      final result = await InvitationService.instance.activateInvitationCode(code);

      expect(result, InvitationResult.success);
      expect(PointsService.instance.points, 50);
    });

    test('累计邀请 5 人应解锁限定皮肤 skin_ambassador', () async {
      useDeviceId('inviter_main');

      // 模拟 5 个不同的被邀请激活码（需通过 _verifySignature 校验）
      // 此处直接调用 recordReferralActivation 5 次（不同 code）
      // 由于生成邀请码依赖 deviceId，分别用 5 个不同 deviceId 生成 5 个 code
      final codes = <String>[];
      for (int i = 0; i < 5; i++) {
        useDeviceId('invitee_$i');
        codes.add(InvitationService.instance.generateInvitationCode());
      }
      // 切回邀请人
      useDeviceId('inviter_main');

      ReferralMilestone? lastMilestone;
      for (final code in codes) {
        lastMilestone = await InvitationService.instance.recordReferralActivation(code);
      }
      expect(lastMilestone, ReferralMilestone.fiveActivations);

      final s = Storage.getSettings();
      expect(s['unlockedOpponentSkin'], true);
      // unlockedFeatures 应包含 good_skin_ambassador
      final raw = s['unlockedFeatures'] as String;
      expect(raw.contains('good_skin_ambassador'), true);
    });

    test('邀请人累计积分应为 100+300+600=1000（前3档）', () async {
      // 邀请 5 人：1人=100, 3人=+300=400, 5人=+600=1000
      useDeviceId('inviter_main2');

      for (int i = 0; i < 5; i++) {
        useDeviceId('invitee_v2_$i');
        final code = InvitationService.instance.generateInvitationCode();
        useDeviceId('inviter_main2');
        await InvitationService.instance.recordReferralActivation(code);
      }

      // 累计：100(1人) + 300(3人) + 600(5人) = 1000
      expect(PointsService.instance.points, 1000);
    });
  });
}
