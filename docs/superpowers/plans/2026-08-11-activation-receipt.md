# 激活识别码（FIT-ACT）验证闭环 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现被邀请人「激活识别码」（含使用数据、HMAC 签名）的生成/校验，修复邀请人侧里程碑激励永远无法触发的闭环断点。

**Architecture:** 在 `InvitationService` 内新增定长 Base32 紧凑码编解码（17 位明文+签名），`recordReferralActivation` 增加识别码分支（防自邀→达标判定→去重→入账），邀请页新增双端 UI（被邀请人生成凭证 / 邀请人记录成果）。

**Tech Stack:** Flutter 3.7.12 / Dart 2.19.6，crypto 包（HMAC-SHA256），shared_preferences。

## Global Constraints

- Dart SDK 约束：`>=2.19.6 <3.0.0` —— **禁止使用 Dart 3 特性**（records、switch 表达式、pattern matching、enhanced enums）
- 不新增任何 pub 依赖（crypto 已有）
- HMAC 密钥 Phase 2 本地硬编码可接受（Phase 3 服务器下发时移除）
- 识别码前缀 `FIT-ACT-`，与 `FIT-INV-`（邀请码）、`FITT-`（分享码）、兑换码互不冲突
- Base32 字母表复用 `23456789ABCDEFGHJKLMNPQRSTUVWXYZ`（去除 0/O/1/I）
- 一用户一码（`activatedInvitationCode`）、一码多人（`myReferralCodes`）约束不变
- UI 遵循现有 `CardWidget` / `FitToast` / 主题色，不新增自定义颜色

---

### Task 1: 识别码编解码核心（服务层）

**Files:**
- Modify: `fittrack_flutter/lib/services/invitation_service.dart`
- Test: `fittrack_flutter/test/invitation_service_test.dart`

**Interfaces:**
- Consumes: `Storage.getRecords()` → `List<Map<String, dynamic>>`（记录含 `totalSets`、`duration` 字段）；`Storage.getSettings()` / `Storage.saveSettings()`；`_computeMyIdentity()`（现有私有方法）
- Produces:
  - `enum ReceiptResult { validReached, validNotReached, invalidFormat, invalidSignature }`
  - `class ReceiptValidationResult { final ReceiptResult result; final String identity; final int trainingCount; final int totalDurationMin; final int daysSinceActivation; }`
  - `String generateActivationReceipt()` —— 被邀请人生成识别码（动态快照）
  - `ReceiptValidationResult validateActivationReceipt(String code)` —— 校验+解密+达标判定

- [ ] **Step 1: 写失败测试**

在 `test/invitation_service_test.dart` 的 `main()` 中新增 group（放在 `邀请奖励积分化` group 之后，`}` 结束前）：

```dart
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
      expect(code.length, 24);

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

      // 翻转明文第 14 个字符（签名区第 1 个）
      final payload = code.replaceFirst('FIT-ACT-', '');
      final tampered = 'FIT-ACT-${payload.substring(0, 13)}'
          '${payload.substring(13, 14) == 'A' ? 'B' : 'A'}'
          '${payload.substring(14)}';
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
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/invitation_service_test.dart`
Expected: FAIL —— `ReceiptResult` / `generateActivationReceipt` / `validateActivationReceipt` 未定义（编译错误）

- [ ] **Step 3: 实现编解码核心**

在 `lib/services/invitation_service.dart` 中：

a) 文件顶部 `import 'dart:convert';`、`import 'package:crypto/crypto.dart';`、`import '../data/storage.dart';`、`import 'points_service.dart';` 已存在，无需改动。

b) 在 `enum ReferralMilestone` 之后新增类型：

```dart
/// 激活识别码校验结果
enum ReceiptResult {
  validReached, // 校验通过且达标（有效训练次数 ≥ 1）
  validNotReached, // 校验通过但未达标（次数 = 0）
  invalidFormat,
  invalidSignature,
}

/// 激活识别码校验返回值
class ReceiptValidationResult {
  final ReceiptResult result;
  final String identity; // 识别码内身份哈希（4位），用于防自邀比对
  final int trainingCount; // 有效训练次数
  final int totalDurationMin; // 训练总时长（分钟）
  final int daysSinceActivation; // 自激活起天数

  const ReceiptValidationResult({
    required this.result,
    this.identity = '',
    this.trainingCount = 0,
    this.totalDurationMin = 0,
    this.daysSinceActivation = 0,
  });
}
```

c) 在 `_invitationSecret` 常量旁新增：

```dart
  /// 激活识别码独立密钥（与邀请码/兑换码/分享码完全隔离）
  /// Phase 2 本地架构可接受硬编码，Phase 3 服务器下发时移除
  static const String _receiptSecret = 'fitTrack_receipt_secret_v1_2026';

  /// 激活识别码格式：FIT-ACT-XXXXXXXXXX-XXXXXXX（17位）
  static final RegExp _receiptPattern = RegExp(r'^FIT-ACT-([A-Z0-9]{17})$');
```

d) 在 `_computeMyIdentity()` 方法后新增以下方法与工具函数（放在 `getActivatedCode()` 之前）：

```dart
  /// 生成激活识别码（被邀请人侧，动态快照）
  ///
  /// 结构：FIT-ACT- + 17位 Base32
  /// - 明文 13 位：身份哈希 4 + 有效训练次数 3 + 总时长分钟 4 + 激活天数 2
  /// - 签名 4 位：HMAC-SHA256(明文) 前 4 字节 mod 32
  String generateActivationReceipt() {
    final identity = _computeMyIdentity();
    if (identity.isEmpty) {
      throw StateError('deviceId not initialized; call Storage.init() first');
    }

    final stats = _effectiveTrainingStats();
    final count = stats['count']!.clamp(0, 32767);
    final totalDuration = stats['totalDurationMin']!.clamp(0, 1048575);
    final days = _daysSinceActivation().clamp(0, 1023);

    // 明文段：身份 4 组 + 次数 3 组 + 时长 4 组 + 天数 2 组 = 13 组
    final groups = <int>[];
    for (final ch in identity.split('')) {
      groups.add(_alphabet.indexOf(ch));
    }
    groups.addAll(_intToBase32Groups(count, 15));
    groups.addAll(_intToBase32Groups(totalDuration, 20));
    groups.addAll(_intToBase32Groups(days, 10));

    final plain = groups.map((g) => _alphabet[g]).join();
    final sig = _receiptSignature(plain);
    return 'FIT-ACT-$plain$sig';
  }

  /// 校验激活识别码（邀请人侧）：格式 → 签名 → 解密 → 达标判定
  ReceiptValidationResult validateActivationReceipt(String code) {
    final normalized = code.toUpperCase().trim();
    final match = _receiptPattern.firstMatch(normalized);
    if (match == null) {
      return const ReceiptValidationResult(result: ReceiptResult.invalidFormat);
    }
    final payload = match.group(1)!;
    if (!payload.split('').every((c) => _alphabet.contains(c))) {
      return const ReceiptValidationResult(result: ReceiptResult.invalidFormat);
    }

    final plain = payload.substring(0, 13);
    final providedSig = payload.substring(13, 17);
    if (_receiptSignature(plain) != providedSig) {
      return const ReceiptValidationResult(result: ReceiptResult.invalidSignature);
    }

    final groups = plain.split('').map(_alphabet.indexOf).toList();
    final identity = plain.substring(0, 4);
    final count = _base32GroupsToInt(groups.sublist(4, 7), 15);
    final totalDuration = _base32GroupsToInt(groups.sublist(7, 11), 20);
    final days = _base32GroupsToInt(groups.sublist(11, 13), 10);

    return ReceiptValidationResult(
      result: count >= 1
          ? ReceiptResult.validReached
          : ReceiptResult.validNotReached,
      identity: identity,
      trainingCount: count,
      totalDurationMin: totalDuration,
      daysSinceActivation: days,
    );
  }

  /// 有效训练统计：totalSets > 0 的记录数 + duration 求和（分钟）
  Map<String, int> _effectiveTrainingStats() {
    final records = Storage.getRecords();
    int count = 0;
    int total = 0;
    for (final r in records) {
      final sets = (r['totalSets'] as num?)?.toInt() ?? 0;
      if (sets > 0) {
        count++;
        total += (r['duration'] as num?)?.toInt() ?? 0;
      }
    }
    return {'count': count, 'totalDurationMin': total};
  }

  /// 自激活起的天数（未激活返回 0）
  int _daysSinceActivation() {
    final activatedAt = Storage.getSettings()['invitationActivatedAt'] as int?;
    if (activatedAt == null) return 0;
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(activatedAt));
    return diff.inDays.clamp(0, 1023);
  }

  /// 数字 → 定长 5bit 组（大端序，末组不足 5bit 低位补 0）
  List<int> _intToBase32Groups(int value, int bitWidth) {
    final bits = <int>[];
    for (int i = bitWidth - 1; i >= 0; i--) {
      bits.add((value >> i) & 1);
    }
    final groups = <int>[];
    for (int i = 0; i < bits.length; i += 5) {
      int g = 0;
      for (int j = 0; j < 5; j++) {
        g = (g << 1) | ((i + j < bits.length) ? bits[i + j] : 0);
      }
      groups.add(g);
    }
    return groups;
  }

  /// 5bit 组 → 整数（只消费前 bitWidth 位）
  int _base32GroupsToInt(List<int> groups, int bitWidth) {
    int value = 0;
    int consumed = 0;
    for (final g in groups) {
      for (int b = 4; b >= 0; b--) {
        if (consumed >= bitWidth) break;
        value = (value << 1) | ((g >> b) & 1);
        consumed++;
      }
    }
    return value;
  }

  /// 识别码签名：HMAC-SHA256(明文) 前 4 字节 mod 32
  String _receiptSignature(String plain) {
    final hmac = Hmac(sha256, utf8.encode(_receiptSecret));
    final digest = hmac.convert(utf8.encode(plain));
    final chars = <String>[];
    for (int i = 0; i < 4; i++) {
      chars.add(_alphabet[digest.bytes[i] % _alphabet.length]);
    }
    return chars.join();
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/invitation_service_test.dart`
Expected: PASS（新增 4 个识别码测试全绿，原有 3 个邀请测试不受影响）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/services/invitation_service.dart fittrack_flutter/test/invitation_service_test.dart
git commit -m "feat(invite): 激活识别码 FIT-ACT 编解码与校验（含使用数据+HMAC签名）"
```

---

### Task 2: recordReferralActivation 识别码入账（闭环）

**Files:**
- Modify: `fittrack_flutter/lib/services/invitation_service.dart`（`recordReferralActivation`，约 L187-L222）
- Test: `fittrack_flutter/test/invitation_service_test.dart`

**Interfaces:**
- Consumes: `validateActivationReceipt()`（Task 1）、`_computeMyIdentity()`、`PointsService.instance.addPoints(int, String)`、`_unlockBadge(String)`、`_unlockOpponentSkin()`、`_currentMilestone(int)`
- Produces: `Future<ReferralMilestone?> recordReferralActivation(String inviteeCode)` —— 识别码分支：仅 `validReached` 且非自邀且未去重时入账；`FIT-INV-` 纯签名路径行为不变

- [ ] **Step 1: 写失败测试**

在 `邀请奖励积分化` group 内新增（或新 group）：

```dart
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
      final milestone =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(milestone, ReferralMilestone.firstActivation);
      expect(PointsService.instance.points, 100);

      final myList = (Storage.getSettings()['myReferralCodes'] as List).cast<String>();
      expect(myList, contains(receipt));
    });

    test('未达标识别码不入账', () async {
      useDeviceId('invitee_loop_seed_2');
      final receipt = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main2');
      final milestone =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(milestone, isNull);
      expect(PointsService.instance.points, 0);
      expect(Storage.getSettings()['myReferralCodes'], isNull);
    });

    test('输入自己的识别码不入账（防自邀）', () async {
      useDeviceId('inviter_loop_main3');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      final milestone =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(milestone, isNull);
      expect(Storage.getSettings()['myReferralCodes'], isNull);
    });

    test('同一识别码重复入账被去重', () async {
      useDeviceId('invitee_loop_seed_3');
      insertValidTraining();
      final receipt = InvitationService.instance.generateActivationReceipt();

      useDeviceId('inviter_loop_main4');
      await InvitationService.instance.recordReferralActivation(receipt);
      final second =
          await InvitationService.instance.recordReferralActivation(receipt);
      expect(second, isNull);
      expect(PointsService.instance.points, 100); // 只发一次
      expect(
        (Storage.getSettings()['myReferralCodes'] as List).length,
        1,
      );
    });
  });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/invitation_service_test.dart`
Expected: FAIL —— 达标识别码返回 null、未达标/自邀/去重场景行为不符合预期

- [ ] **Step 3: 重构 recordReferralActivation**

将 `lib/services/invitation_service.dart` 中现有 `recordReferralActivation` 方法（L187-L222）整体替换为：

```dart
  /// 记录一次"被邀请人激活"事件（邀请人视角，本地层面）
  ///
  /// 入参支持两种格式：
  /// - `FIT-INV-` 邀请码：纯 HMAC 签名验证（历史路径）
  /// - `FIT-ACT-` 激活识别码：解密使用数据 → 达标判定（有效训练 ≥ 1）
  ///   → 防自邀（身份哈希 ≠ 当前用户）→ 去重 → 入账
  ///
  /// 返回是否触发新的里程碑。
  Future<ReferralMilestone?> recordReferralActivation(String inviteeCode) async {
    final code = inviteeCode.trim().toUpperCase();
    if (code.startsWith('FIT-ACT-')) {
      return _recordByReceipt(code);
    }
    if (!_verifySignature(code)) return null;
    return _grantMilestone(code);
  }

  /// 识别码分支：达标 + 防自邀 + 去重后才入账
  Future<ReferralMilestone?> _recordByReceipt(String code) async {
    final validation = validateActivationReceipt(code);
    if (validation.result != ReceiptResult.validReached) return null;
    // 防自邀：识别码身份 = 当前用户身份
    if (validation.identity.isNotEmpty &&
        validation.identity == _computeMyIdentity()) {
      return null;
    }
    return _grantMilestone(code);
  }

  /// 公共入账：写入 myReferralCodes（去重）+ 里程碑积分/徽章/皮肤发放
  Future<ReferralMilestone?> _grantMilestone(String code) async {
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    if (myList.contains(code)) return null;
    myList.add(code);
    settings['myReferralCodes'] = myList;
    Storage.saveSettings(settings);

    final count = myList.length;
    // 按里程碑发放积分（每达成新档位发放对应积分，不累加同档位）
    // 1 人 → +100, 3 人 → +300, 5 人 → +600, 10 人 → +1200
    int reward = 0;
    if (count == 1) {
      reward = 100;
    } else if (count == 3) {
      reward = 300;
    } else if (count == 5) {
      reward = 600;
    } else if (count == 10) {
      reward = 1200;
    }
    if (reward > 0) {
      await PointsService.instance.addPoints(reward, 'invite_milestone_$count');
    }

    if (count >= 1) _unlockBadge('referral_first');
    if (count >= 3) _unlockBadge('referral_three');
    if (count >= 5) {
      _unlockBadge('referral_five');
      _unlockOpponentSkin(); // 累计5人解锁限定皮肤
    }
    if (count >= 10) _unlockBadge('referral_ten');

    return _currentMilestone(count);
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/invitation_service_test.dart`
Expected: PASS（Task 1 的 4 个 + 原有 3 个 + 新增 4 个识别码入账测试全绿）

- [ ] **Step 5: 提交**

```bash
git add fittrack_flutter/lib/services/invitation_service.dart fittrack_flutter/test/invitation_service_test.dart
git commit -m "feat(invite): recordReferralActivation 支持激活识别码入账（达标+防自邀+去重）"
```

---

### Task 3: 邀请页双端 UI

**Files:**
- Modify: `fittrack_flutter/lib/pages/invitation_page.dart`

**Interfaces:**
- Consumes: `InvitationService.instance.generateActivationReceipt()`、`validateActivationReceipt(String)`、`recordReferralActivation(String)`、`getActivatedCode()`、`getReferralProgress()`；`FitToast`（common_widgets.dart）；`LiftTrackColors`（app_themes.dart）；`Clipboard`（flutter/services.dart，已 import）
- Produces: 邀请页两个新 UI 区块 —— 被邀请人「我的激活凭证」生成入口 + 邀请人「记录邀请成果」校验入账区

- [ ] **Step 1: 新增「记录邀请成果」区块（邀请人侧）**

在 `_InvitationPageState` 中新增字段与逻辑：

a) 在 `_activateController` 声明处旁新增：

```dart
  final _receiptController = TextEditingController();
  bool _verifying = false;
  bool _recording = false;
  ReceiptValidationResult? _receiptValidation;
```

b) 在 `dispose()` 中释放：

```dart
    _receiptController.dispose();
```

c) 在 `build()` 的 Column children 中，`_buildActivateCard(colors)` 之后插入：

```dart
                  const SizedBox(height: 16),
                  _buildRecordReceiptCard(colors),
```

d) 在 `_buildActivateCard` 方法之前新增 `_buildRecordReceiptCard` 与相关方法：

```dart
  // ── 记录邀请成果（邀请人输入被邀请人识别码） ──────────────────────────

  Widget _buildRecordReceiptCard(LiftTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '记录邀请成果',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '好友激活你的邀请码后，输入好友出示的 FIT-ACT 识别码，'
            '可验证其训练数据并确认成果',
            style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _receiptController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
            ],
            decoration: InputDecoration(
              hintText: 'FIT-ACT-XXXXXXXXXX-XXXXXXX',
              hintStyle: TextStyle(color: colors.textMuted, letterSpacing: 1),
              filled: true,
              fillColor: colors.bgSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _verifying ? null : _verifyReceipt,
              icon: _verifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(_verifying ? '校验中...' : '校验识别码'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.accentGlow,
                side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          if (_receiptValidation != null) ...[
            const SizedBox(height: 12),
            _buildReceiptResultCard(colors),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptResultCard(LiftTrackColors colors) {
    final v = _receiptValidation!;
    final valid = v.result == ReceiptResult.validReached;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (valid ? colors.successColor : colors.warningColor)
            .withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (valid ? colors.successColor : colors.warningColor)
              .withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                valid ? Icons.check_circle : Icons.info_outline,
                color: valid ? colors.successColor : colors.warningColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  valid ? '该好友已完成首次训练，可记录成果' : '好友尚未完成首次训练',
                  style: TextStyle(
                    color: valid ? colors.successColor : colors.warningColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '有效训练 ${v.trainingCount} 次 · 总时长 ${v.totalDurationMin} 分钟'
            ' · 已激活 ${v.daysSinceActivation} 天',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          if (valid) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _recording ? null : _recordReceipt,
                icon: _recording
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.card_giftcard, size: 18),
                label: Text(_recording ? '记录中...' : '确认记录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _verifyReceipt() async {
    final code = _receiptController.text.trim().toUpperCase();
    if (code.isEmpty) {
      FitToast.info(context, '请输入识别码');
      return;
    }
    setState(() => _verifying = true);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final v = InvitationService.instance.validateActivationReceipt(code);
    setState(() {
      _verifying = false;
      _receiptValidation = v;
    });
    if (v.result == ReceiptResult.invalidFormat) {
      FitToast.error(context, '识别码格式错误');
    } else if (v.result == ReceiptResult.invalidSignature) {
      FitToast.error(context, '识别码无效');
    }
  }

  Future<void> _recordReceipt() async {
    final code = _receiptController.text.trim().toUpperCase();
    setState(() => _recording = true);
    final milestone =
        await InvitationService.instance.recordReferralActivation(code);
    setState(() => _recording = false);
    if (!mounted) return;

    if (milestone != null) {
      FitToast.success(context, '记录成功！积分奖励已到账');
      _receiptController.clear();
      setState(() => _receiptValidation = null);
      _loadData();
    } else {
      FitToast.error(context, '记录失败：识别码无效、未达标或已记录过');
    }
  }
```

- [ ] **Step 2: 激活成功后新增「我的激活凭证」生成入口（被邀请人侧）**

在 `_buildActivateCard` 的 `activatedCode != null` 分支内，`Text('7天高级统计体验...')` 之后新增：

```dart
            const SizedBox(height: 8),
            _buildActivationReceiptEntry(colors, activatedCode),
```

并新增方法（放在 `_buildActivateCard` 方法之后）：

```dart
  // ── 我的激活凭证（被邀请人生成识别码） ──────────────────────────────

  Widget _buildActivationReceiptEntry(
      LiftTrackColors colors, String activatedCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '我的激活凭证',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '生成识别码发给邀请你的好友，好友输入后双方得奖励。'
            '识别码含你的训练数据并加密签名，请放心展示',
            style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showReceiptDialog(colors),
              icon: const Icon(Icons.qr_code_2, size: 18),
              label: const Text('生成我的激活凭证'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(LiftTrackColors colors) {
    final code = InvitationService.instance.generateActivationReceipt();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('我的激活凭证', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.accentGlow,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '将此码发给邀请你的好友。好友在「记录邀请成果」中输入确认后，'
              '双方均可获得奖励。每次生成均反映你最新的训练数据。',
              style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.of(dialogContext).pop();
              FitToast.success(context, '识别码已复制');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('复制识别码'),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 3: 静态检查**

Run: `flutter analyze`
Expected: `No issues found!`（若提示 `_receiptValidation` 未使用等，属正常警告需确认已全部接线）

- [ ] **Step 4: 运行全部邀请测试**

Run: `flutter test test/invitation_service_test.dart`
Expected: PASS（服务层 11 个测试全绿）

- [ ] **Step 5: 手动验证清单**（在 Android 模拟器 `emulator-5558` 或 OHOS 设备上）

1. 邀请页「输入邀请码」激活成功 → 出现「我的激活凭证」入口
2. 点击「生成我的激活凭证」→ 弹窗展示 24 位识别码 → 复制成功
3. 已有 ≥1 次有效训练时，识别码校验结果为「已完成首次训练，可记录成果」
4. 点击「确认记录」→ 提示「记录成功」，进度概览「已邀请人数」+1
5. 再次输入同一识别码 → 提示「记录失败：已记录过」
6. 篡改识别码末位 → 提示「识别码无效」
7. 无训练记录的新用户识别码 → 提示「好友尚未完成首次训练」

- [ ] **Step 6: 提交**

```bash
git add fittrack_flutter/lib/pages/invitation_page.dart
git commit -m "feat(invite): 邀请页新增激活凭证生成与记录邀请成果入口"
```

---

## 自审记录

- **Spec 覆盖**：§3 识别码格式（Task 1）、§4 有效训练统计与达标判定（Task 1/2）、§5 双端交互流程（Task 1/3）、§6 接口变更（Task 1/2）、§7 防自邀/去重（Task 2）、§8 UI（Task 3）、§9 测试（Task 1/2）。§10 范围边界（deeplink 丢码）不在本计划内，符合 spec。
- **类型一致性**：`ReceiptValidationResult.identity` 供 Task 2 防自邀比对；`generateActivationReceipt` / `validateActivationReceipt` 签名在 Task 1 定义、Task 2/3 使用；`recordReferralActivation` 保持原签名，调用方兼容。
- **Dart 2.19 兼容**：全程无 records/switch 表达式/pattern matching；`clamp` 返回 `num`，赋给 `int` 字段处已在生成方法内通过 `.clamp()` 后直接使用（`_intToBase32Groups` 入参为 `int`，Dart 2.19 下 `int.clamp` 返回 `num` 需注意——生成方法中 `count` 等已声明为 `final` 并传给 `_intToBase32Groups(count, 15)`，若 analyze 报类型错误，改为 `count.toInt()` 即可，见下方注释）。

> 注：Dart 2.19 中 `int.clamp` 静态类型为 `num`。若 `flutter analyze` 在 `groups.addAll(_intToBase32Groups(count, 15))` 处报 `num` 无法传给 `int` 参数，将三处改为：
> `final count = stats['count']!.clamp(0, 32767).toInt();`（其余两处同理）。
