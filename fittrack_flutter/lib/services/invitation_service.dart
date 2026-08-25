import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../data/storage.dart';
import 'points_service.dart';

/// v1 教学裂变体系 —— 邀请码服务
///
/// 设计要点（依据 docs/versions/v1-获客留存版/01_迭代方案.md §2.3）：
/// - 邀请码格式：FIT-INV-XXXXXX（6位字母数字，独立前缀，与兑换码 FITT- 区分）
/// - HMAC-SHA256 本地验证，独立密钥（与 redeem_service.dart 密钥完全隔离）
/// - 防自邀：邀请人ID ≠ 被邀请人ID（本地层面通过 deviceId 比对）
/// - 一码一绑：激活后不可更改
/// - 单机版无法防多设备刷量，接受损耗（联网版用设备指纹根治）
///
/// 激励分层（v1.3 积分化重构）：
/// | 累计邀请人数 | 邀请人获得 | 被邀请人获得 |
/// |---|---|---|
/// | 1 人 | 100 积分 + "引路人"徽章 | 50 积分 |
/// | 3 人 | 300 积分 + "布道者"徽章 | 50 积分 |
/// | 5 人 | 600 积分 + "传道者"徽章 + 限定对手皮肤 skin_ambassador | 50 积分 |
/// | 10 人 | 1200 积分 + "LiftTrack 大使"称号 | 50 积分 |
enum InvitationResult {
  success,
  invalidFormat,
  invalidSignature,
  selfInvite, // 邀请人=被邀请人（防自邀）
  alreadyActivated, // 一码一绑：已激活过
}

/// 裂变里程碑
enum ReferralMilestone {
  firstActivation, // 首次激活（1人）
  threeActivations, // 累计3人
  fiveActivations, // 累计5人
  tenActivations, // 累计10人
}

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

class InvitationService {
  static final InvitationService instance = InvitationService._();
  InvitationService._();

  /// 邀请码独立密钥（与 RedeemService._secrets 完全隔离）
  /// Phase 2 本地架构可接受硬编码，Phase 3 服务器下发时移除
  static const String _invitationSecret = 'fitTrack_invitation_secret_v1_2026';

  /// 邀请码格式：FIT-INV-XXXXXX（6位大写字母数字）
  static final RegExp _pattern = RegExp(r'^FIT-INV-([A-Z0-9]{6})$');

  /// 激活识别码独立密钥（与邀请码/兑换码/分享码完全隔离）
  /// Phase 2 本地架构可接受硬编码，Phase 3 服务器下发时移除
  static const String _receiptSecret = 'fitTrack_receipt_secret_v1_2026';

  /// 激活识别码格式：FIT-ACT-XXXXXXXXXX-XXXXXXX（17位）
  static final RegExp _receiptPattern = RegExp(r'^FIT-ACT-([A-Z0-9]{17})$');

  /// Base32 字母表（去除易混淆字符 0/O/1/I）
  static const String _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// 生成本用户的专属邀请码（确定性：同一 deviceId 生成同一邀请码）
  ///
  /// 设计：6位 = 4位 deviceId 哈希前缀 + 2位 HMAC 签名
  /// - 前4位：HMAC-SHA256(deviceId + secret) 取前4位，Base32 编码
  /// - 后2位：HMAC-SHA256(前4位 + secret) 取前2位，作为签名
  String generateInvitationCode() {
    final deviceId = _getDeviceId();
    if (deviceId.isEmpty) {
      throw StateError('deviceId not initialized; call Storage.init() first');
    }

    // 计算邀请人身份哈希（前4位）
    final identityHmac = Hmac(sha256, utf8.encode(_invitationSecret));
    final identityDigest = identityHmac.convert(utf8.encode(deviceId));
    final identityBytes = identityDigest.bytes;

    // 取前4字节，每字节 mod 32 映射到 Base32 字母
    final codeUnits = <String>[];
    for (int i = 0; i < 4; i++) {
      codeUnits.add(_alphabet[identityBytes[i] % _alphabet.length]);
    }
    final identityPart = codeUnits.join();

    // 计算签名（后2位）：基于身份部分 + 密钥
    final sigHmac = Hmac(sha256, utf8.encode(_invitationSecret));
    final sigDigest = sigHmac.convert(utf8.encode(identityPart));
    final sigChars = <String>[];
    for (int i = 0; i < 2; i++) {
      sigChars.add(_alphabet[sigDigest.bytes[i] % _alphabet.length]);
    }
    final sigPart = sigChars.join();

    return 'FIT-INV-$identityPart$sigPart';
  }

  /// 验证邀请码格式与签名
  bool _verifySignature(String code) {
    final match = _pattern.firstMatch(code);
    if (match == null) return false;
    final payload = match.group(1)!;
    if (payload.length != 6) return false;

    final identityPart = payload.substring(0, 4);
    final providedSig = payload.substring(4, 6);

    // 重算签名
    final sigHmac = Hmac(sha256, utf8.encode(_invitationSecret));
    final sigDigest = sigHmac.convert(utf8.encode(identityPart));
    final expectedSig = <String>[];
    for (int i = 0; i < 2; i++) {
      expectedSig.add(_alphabet[sigDigest.bytes[i] % _alphabet.length]);
    }
    return expectedSig.join() == providedSig;
  }

  /// 激活邀请码（被邀请人调用）
  ///
  /// 流程：
  /// 1. 格式校验
  /// 2. 签名校验（HMAC）
  /// 3. 防自邀：比对邀请人身份哈希与当前用户 deviceId 哈希
  /// 4. 一码一绑：检查是否已激活过
  /// 5. 写入激活记录，触发邀请人激励（本地层面仅记录，跨设备需联网）
  Future<InvitationResult> activateInvitationCode(String code) async {
    final normalized = code.toUpperCase().trim();
    if (!_pattern.hasMatch(normalized)) {
      return InvitationResult.invalidFormat;
    }
    if (!_verifySignature(normalized)) {
      return InvitationResult.invalidSignature;
    }

    // 防自邀：提取邀请人身份部分，与当前用户身份部分比对
    final inviterIdentity = normalized.substring(8, 12); // FIT-INV- 后4位
    final myIdentity = _computeMyIdentity();
    if (inviterIdentity == myIdentity) {
      return InvitationResult.selfInvite;
    }

    // 一码一绑：检查是否已激活过任何邀请码
    final settings = Storage.getSettings();
    final activatedCode = settings['activatedInvitationCode'] as String?;
    if (activatedCode != null && activatedCode.isNotEmpty) {
      return InvitationResult.alreadyActivated;
    }

    // 写入激活记录
    settings['activatedInvitationCode'] = normalized;
    settings['invitationActivatedAt'] = DateTime.now().millisecondsSinceEpoch;
    settings['inviterIdentity'] = inviterIdentity;
    Storage.saveSettings(settings);

    // 被邀请人激励：50 积分（替代旧的 7 天高级统计体验）
    await PointsService.instance.addPoints(50, 'invited');

    return InvitationResult.success;
  }

  /// 计算当前用户的身份哈希前缀（4位）
  String _computeMyIdentity() {
    final deviceId = _getDeviceId();
    if (deviceId.isEmpty) return '';
    final hmac = Hmac(sha256, utf8.encode(_invitationSecret));
    final digest = hmac.convert(utf8.encode(deviceId));
    final chars = <String>[];
    for (int i = 0; i < 4; i++) {
      chars.add(_alphabet[digest.bytes[i] % _alphabet.length]);
    }
    return chars.join();
  }

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
    final count = stats['count']!.clamp(0, 32767).toInt();
    final totalDuration = stats['totalDurationMin']!.clamp(0, 1048575).toInt();
    final days = _daysSinceActivation().clamp(0, 1023).toInt();

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
    return diff.inDays.clamp(0, 1023).toInt();
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

  String _getDeviceId() {
    final settings = Storage.getSettings();
    return settings['deviceId'] as String? ?? '';
  }

  // ============================================================
  // 裂变激励查询 / 解锁
  // ============================================================

  /// 获取当前用户已激活的邀请码（被邀请人视角）
  String? getActivatedCode() {
    final settings = Storage.getSettings();
    final code = settings['activatedInvitationCode'] as String?;
    return (code != null && code.isNotEmpty) ? code : null;
  }

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
    // 通知数据变更：邀请进度已变化（非里程碑档位无积分入账，
    // 不会走 PointsService.addPoints 的通知路径，必须在此显式通知）
    Storage.dataChanged.value = !Storage.dataChanged.value;

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

  /// 累计邀请 5 人时解锁限定对手皮肤 skin_ambassador
  void _unlockOpponentSkin() {
    final settings = Storage.getSettings();
    // 写入 unlockedOpponentSkin 标记（兼容旧字段）
    settings['unlockedOpponentSkin'] = true;
    // 写入 unlockedFeatures：good_skin_ambassador
    final raw = settings['unlockedFeatures'] as String? ?? '[]';
    final list = (jsonDecode(raw) as List).cast<String>();
    if (!list.contains('good_skin_ambassador')) {
      list.add('good_skin_ambassador');
      settings['unlockedFeatures'] = jsonEncode(list);
    }
    Storage.saveSettings(settings);
  }

  void _unlockBadge(String badgeId) {
    final settings = Storage.getSettings();
    final List<dynamic> badges = settings['unlockedReferralBadges'] ?? [];
    if (!badges.contains(badgeId)) {
      badges.add(badgeId);
      settings['unlockedReferralBadges'] = badges;
      Storage.saveSettings(settings);
    }
  }

  /// 查询当前裂变进度
  Map<String, dynamic> getReferralProgress() {
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    return {
      'totalReferrals': myList.length,
      'totalPoints': PointsService.instance.points,
      'nextMilestone': _nextMilestone(myList.length),
      'unlockedBadges': settings['unlockedReferralBadges'] ?? <String>[],
      'isAmbassador': (settings['unlockedReferralBadges'] as List?)?.contains('referral_ten') ?? false,
      'adFreeReport': settings['adFreeReportUnlocked'] == true,
    };
  }

  int _nextMilestone(int current) {
    if (current < 1) return 1;
    if (current < 3) return 3;
    if (current < 5) return 5;
    if (current < 10) return 10;
    return 10; // 已达最高
  }

  ReferralMilestone? _currentMilestone(int count) {
    if (count >= 10) return ReferralMilestone.tenActivations;
    if (count >= 5) return ReferralMilestone.fiveActivations;
    if (count >= 3) return ReferralMilestone.threeActivations;
    if (count >= 1) return ReferralMilestone.firstActivation;
    return null;
  }

  /// 7日留存激励：被邀请人激活后7天有训练记录，邀请人解锁1个专题教学包
  ///
  /// 单机版限制：邀请人无法自动感知被邀请人留存。
  /// 联网版通过服务器事件推送触发。
  Future<void> maybeUnlockRetentionReward() async {
    final settings = Storage.getSettings();
    final activatedAt = settings['invitationActivatedAt'] as int?;
    if (activatedAt == null) return;

    final activatedTime = DateTime.fromMillisecondsSinceEpoch(activatedAt);
    final daysSinceActivation =
        DateTime.now().difference(activatedTime).inDays;
    if (daysSinceActivation < 7) return;
    if (settings['retentionRewardUnlocked'] == true) return;

    // 标记留存奖励已解锁（被邀请人侧）
    settings['retentionRewardUnlocked'] = true;
    Storage.saveSettings(settings);
  }

  /// v1 全免费策略下，高级统计始终开放；
  /// 此方法保留供 v2 启用 Pro 时使用。
  bool isAdvancedStatsAvailable() {
    // v1: 全免费开放（依据 01_迭代方案.md §2.4）
    return true;
  }
}
