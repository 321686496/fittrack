import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/services/points_service.dart';
import 'package:fittrack_flutter/services/invitation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Storage.addRecord/getRecords 依赖 SQLite，测试环境需初始化 ffi databaseFactory
  // （与 achievement_service_test.dart 等项目测试保持一致）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

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
    // 清空 SQLite 记录与内存缓存，保证 FIT-ACT 测试间记录隔离
    await Storage.clearAll();
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
      const inviterDeviceId = 'inviter_device_seed_123';
      const inviteeDeviceId = 'invitee_device_seed_456';
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

      ReferralRecordOutcome? lastOutcome;
      for (final code in codes) {
        lastOutcome = await InvitationService.instance.recordReferralActivation(code);
      }
      expect(lastOutcome!.success, true);
      expect(lastOutcome.milestone, ReferralMilestone.fiveActivations);
      expect(lastOutcome.pointsEarned, 600);
      expect(lastOutcome.totalReferrals, 5);

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

  group('激活识别码 FIT-ACT', () {
    void insertValidTraining({int minutes = 30, int sets = 10}) {
      Storage.addRecord({
        'name': '测试训练',
        'date': DateTime.now().millisecondsSinceEpoch,
        'duration': minutes,
        'pureDuration': minutes * 60,
        'totalWeight': 100,
        'totalSets': sets,
        'exerciseCount': 1,
        'muscles': [],
        'setRecords': <String, List<Map<String, dynamic>>>{},
        'restLog': <Map<String, dynamic>>[],
        'planId': 'p1',
        'planName': '测试训练',
      });
    }

    test('生成识别码可往返解码，数据一致且达标', () {
      useDeviceId('invitee_receipt_seed_1');
      final s = Storage.getSettings();
      s['invitationActivatedAt'] =
          DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
      Storage.saveSettings(s);
      insertValidTraining(minutes: 30, sets: 10);
      insertValidTraining(minutes: 45, sets: 8);

      final code = InvitationService.instance.generateActivationReceipt();
      expect(code.startsWith('FIT-ACT-'), true);
      // FIT-ACT-（8字符） + 17位 Base32 payload = 25
      expect(code.length, 25);

      final v = InvitationService.instance.validateActivationReceipt(code);
      expect(v.result, ReceiptResult.validReached);
      expect(v.trainingCount, 2);
      expect(v.totalDurationMin, 75);
      expect(v.daysSinceActivation, 3);
    });

    test('无有效训练时识别码未达标', () {
      useDeviceId('invitee_receipt_seed_2');
      // 插入 totalSets=0 的无效记录（跨天未完成场景）
      Storage.addRecord({
        'name': '未完成',
        'date': DateTime.now().millisecondsSinceEpoch,
        'duration': 10,
        'pureDuration': 600,
        'totalWeight': 0,
        'totalSets': 0,
        'exerciseCount': 0,
        'muscles': [],
        'setRecords': <String, List<Map<String, dynamic>>>{},
        'restLog': <Map<String, dynamic>>[],
        'planId': 'p1',
        'planName': '未完成',
      });

      final code = InvitationService.instance.generateActivationReceipt();
      final v = InvitationService.instance.validateActivationReceipt(code);
      expect(v.result, ReceiptResult.validNotReached);
      expect(v.trainingCount, 0);
    });

    test('篡改识别码任意数据位导致签名校验失败', () {
      useDeviceId('invitee_receipt_seed_3');
      insertValidTraining(minutes: 30, sets: 10);
      final code = InvitationService.instance.generateActivationReceipt();

      // 翻转明文第 1 个字符（身份段），验证数据位篡改同样被 HMAC 拦截
      final payload = code.replaceFirst('FIT-ACT-', '');
      final tampered = 'FIT-ACT-${payload.substring(0, 1) == 'A' ? 'B' : 'A'}'
          '${payload.substring(1)}';
      final v = InvitationService.instance.validateActivationReceipt(tampered);
      expect(v.result, ReceiptResult.invalidSignature);
    });

    test('非法格式返回 invalidFormat', () {
      final v = InvitationService.instance
          .validateActivationReceipt('FIT-INV-ABCDEF');
      expect(v.result, ReceiptResult.invalidFormat);
      final v2 = InvitationService.instance.validateActivationReceipt('FIT-ACT-1');
      expect(v2.result, ReceiptResult.invalidFormat);
    });
  });

  group('识别码入账闭环', () {
    void insertValidTraining() {
      Storage.addRecord({
        'name': '测试训练',
        'date': DateTime.now().millisecondsSinceEpoch,
        'duration': 30,
        'pureDuration': 1800,
        'totalWeight': 100,
        'totalSets': 10,
        'exerciseCount': 1,
        'muscles': [],
        'setRecords': <String, List<Map<String, dynamic>>>{},
        'restLog': <Map<String, dynamic>>[],
        'planId': 'p1',
        'planName': '测试训练',
      });
    }

    test('达标识别码入账并发放首次里程碑', () async {
      // 被邀请人（有训练）
      useDeviceId('invitee_loop_seed_1');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      // 邀请人
      useDeviceId('inviter_loop_main');
      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, true);
      expect(outcome.milestone, ReferralMilestone.firstActivation);
      expect(outcome.pointsEarned, 100);
      expect(outcome.totalReferrals, 1);
      expect(PointsService.instance.points, 100);

      final myList = (Storage.getSettings()['myReferralCodes'] as List).cast<String>();
      expect(myList, contains(receipt));
    });

    test('未达标识别码不入账', () async {
      useDeviceId('invitee_loop_seed_2');
      final receipt = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main2');
      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, false);
      expect(outcome.totalReferrals, 0);
      expect(PointsService.instance.points, 0);
      // Storage.getSettings() 会合并 defaults（含 myReferralCodes: []），
      // 未入账时表现为空列表而非 null
      expect(Storage.getSettings()['myReferralCodes'], isEmpty);
    });

    test('输入自己的识别码不入账（防自邀）', () async {
      useDeviceId('inviter_loop_main3');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      final outcome =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(outcome.success, false);
      // Storage.getSettings() 会合并 defaults（含 myReferralCodes: []），
      // 未入账时表现为空列表而非 null
      expect(Storage.getSettings()['myReferralCodes'], isEmpty);
    });

    test('同一识别码重复入账被去重', () async {
      useDeviceId('invitee_loop_seed_3');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main4');
      final first =
          await InvitationService.instance.recordReferralActivation(receipt);
      final second =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(first.success, true);
      expect(second.success, false);
      expect(second.totalReferrals, 1); // 失败分支携带当前累计值
      expect(PointsService.instance.points, 100); // 只发一次
      expect(
        (Storage.getSettings()['myReferralCodes'] as List).length,
        1,
      );
    });

    test('同一设备卸载重装后识别码被设备维度去重', () async {
      // 模拟持久设备身份：persistentDeviceId 跨重装稳定；deviceId 重装后变化
      void usePersistent(String persistent, String device) {
        final s = Storage.getSettings();
        s['persistentDeviceId'] = persistent;
        s['deviceId'] = device;
        Storage.saveSettings(s);
      }

      // 被邀请人：同一台设备第一安装
      usePersistent('P-reinstallable-device-1', 'device_1st_install');
      insertValidTraining();
      final receipt1 = InvitationService.instance.generateActivationReceipt();

      // 邀请人入账第一次成功
      usePersistent('P-inviter', 'inviter_install');
      final first =
          await InvitationService.instance.recordReferralActivation(receipt1);
      expect(first.success, true);
      expect(first.totalReferrals, 1);
      expect(PointsService.instance.points, 100);

      // 卸载重装：deviceId 变化，但持久身份不变 → 同一设备再来一次
      usePersistent('P-reinstallable-device-1', 'device_2nd_install');
      insertValidTraining();
      final receipt2 = InvitationService.instance.generateActivationReceipt();
      expect(receipt2, isNot(receipt1)); // 码字符串已变

      usePersistent('P-inviter', 'inviter_install');
      final second =
          await InvitationService.instance.recordReferralActivation(receipt2);
      expect(second.success, false); // 设备维度去重拦截
      expect(second.totalReferrals, 1); // 仍只有 1 人
      expect(PointsService.instance.points, 100); // 不重复发积分
      expect((Storage.getSettings()['myReferralDeviceIds'] as List).length, 1);
      expect((Storage.getSettings()['myReferralCodes'] as List).length, 1);
    });

    test('第 2 次入账非里程碑档位：成功但 0 积分', () async {
      // 两个不同被邀请人的达标识别码
      useDeviceId('invitee_loop_seed_4');
      insertValidTraining();
      final receipt1 = InvitationService.instance.generateActivationReceipt();
      useDeviceId('invitee_loop_seed_5');
      insertValidTraining();
      final receipt2 = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main5');
      final first =
          await InvitationService.instance.recordReferralActivation(receipt1);
      expect(first.success, true);
      expect(first.pointsEarned, 100); // 第 1 人命中首档
      expect(first.totalReferrals, 1);

      final second =
          await InvitationService.instance.recordReferralActivation(receipt2);
      expect(second.success, true);
      expect(second.totalReferrals, 2);
      expect(second.pointsEarned, 0); // 第 2 人非里程碑档位
      expect(second.milestone, isNull);
      expect(PointsService.instance.points, 100); // 总积分不变
    });
  });

  group('互绑拦截（双守卫）', () {
    void insertValidTraining() {
      Storage.addRecord({
        'name': '测试训练',
        'date': DateTime.now().millisecondsSinceEpoch,
        'duration': 30,
        'pureDuration': 1800,
        'totalWeight': 100,
        'totalSets': 10,
        'exerciseCount': 1,
        'muscles': [],
        'setRecords': <String, List<Map<String, dynamic>>>{},
        'restLog': <Map<String, dynamic>>[],
        'planId': 'p1',
        'planName': '测试训练',
      });
    }

    test('守卫1（激活时）：A 已绑定 B，B 反向邀请 A 被拒', () async {
      // 第一步：A 邀请 B 并成功入账（A 的绑定列表记录 B 的设备身份）
      useDeviceId('invitee_mutual_b');
      insertValidTraining();
      final receiptB = InvitationService.instance.generateActivationReceipt();
      useDeviceId('inviter_mutual_a');
      final bound =
          await InvitationService.instance.recordReferralActivation(receiptB);
      expect(bound.success, true);
      expect((Storage.getSettings()['myReferralDeviceIds'] as List).length, 1);

      // 第二步：B 生成自己的邀请码，A 尝试激活 → 守卫1 拦截（互绑）
      useDeviceId('invitee_mutual_b');
      final bCode = InvitationService.instance.generateInvitationCode();
      useDeviceId('inviter_mutual_a');
      final result =
          await InvitationService.instance.activateInvitationCode(bCode);
      expect(result, InvitationResult.mutualInvite);
      // 未写入激活记录：B 无法借此拿到 50 积分（默认值为空串）
      expect(Storage.getSettings()['activatedInvitationCode'], isEmpty);
    });

    test('守卫2（录入时）：B 已邀请 A，A 再录入 B 的识别码被拒', () async {
      // 第一步：B 邀请 A（A 激活 B 的码），A 记录 B 为"邀请过我的人"
      useDeviceId('inviter_mutual_b');
      final bCode = InvitationService.instance.generateInvitationCode();
      useDeviceId('invitee_mutual_a');
      final activated =
          await InvitationService.instance.activateInvitationCode(bCode);
      expect(activated, InvitationResult.success);

      // 第二步：B 生成达标识别码，A 尝试录入 → 守卫2 拦截（互绑）
      useDeviceId('inviter_mutual_b');
      insertValidTraining();
      final receiptB = InvitationService.instance.generateActivationReceipt();
      useDeviceId('invitee_mutual_a');
      final outcome =
          await InvitationService.instance.recordReferralActivation(receiptB);
      expect(outcome.success, false);
      expect(outcome.totalReferrals, 0);
      // getSettings 合并 defaults：myReferralCodes 默认 []，myReferralDeviceIds 无默认值
      expect(Storage.getSettings()['myReferralCodes'], isEmpty);
      expect(Storage.getSettings()['myReferralDeviceIds'] ?? [], isEmpty);
    });

    test('非互绑的陌生人首次绑定不受影响', () async {
      // 无任何互绑历史时，正常邀请链路保持可用（防误杀回归）
      useDeviceId('invitee_mutual_c');
      insertValidTraining();
      final receiptC = InvitationService.instance.generateActivationReceipt();
      useDeviceId('inviter_mutual_d');
      final outcome =
          await InvitationService.instance.recordReferralActivation(receiptC);
      expect(outcome.success, true);
      expect(outcome.totalReferrals, 1);
      expect(PointsService.instance.points, 100);
    });
  });
}
