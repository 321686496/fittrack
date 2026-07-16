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
/// 激励分层（V1-08-03 ~ V1-08-08）：
/// | 被邀请人行为 | 邀请人获得 | 被邀请人获得 |
/// |---|---|---|
/// | 激活（输入邀请码+首次训练） | 解锁3个进阶动作教学 + "引路人"徽章 | 7天高级统计全开放体验 |
/// | 7日留存 | 解锁1个专题教学包 | — |
/// | 累计邀请3人激活 | 永久免广告看训练报告 + "布道者"徽章 | — |
/// | 累计邀请5人激活 | 解锁高手教学专题 + 专属虚拟对手皮肤 | — |
/// | 累计邀请10人激活 | "燃力大使"永久称号 | — |
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

class InvitationService {
  static final InvitationService instance = InvitationService._();
  InvitationService._();

  /// 邀请码独立密钥（与 RedeemService._secrets 完全隔离）
  /// Phase 2 本地架构可接受硬编码，Phase 3 服务器下发时移除
  static const String _invitationSecret = 'fitTrack_invitation_secret_v1_2026';

  /// 邀请码格式：FIT-INV-XXXXXX（6位大写字母数字）
  static final RegExp _pattern = RegExp(r'^FIT-INV-([A-Z0-9]{6})$');

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
    // 被邀请人激励：7天高级统计全开放体验
    settings['advancedStatsTrialUntil'] =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    Storage.saveSettings(settings);

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
  /// 单机版限制：无法自动感知被邀请人激活。
  /// 实际使用场景：
  /// - 邀请人主动输入被邀请人激活的码（反向验证）
  /// - 或联网版通过服务器推送
  ///
  /// 返回是否触发新的里程碑。
  Future<ReferralMilestone?> recordReferralActivation(String inviteeCode) async {
    if (!_verifySignature(inviteeCode)) return null;
    final settings = Storage.getSettings();
    final myList = (settings['myReferralCodes'] as List?)?.cast<String>() ?? [];
    if (myList.contains(inviteeCode)) return null;
    myList.add(inviteeCode);
    settings['myReferralCodes'] = myList;
    Storage.saveSettings(settings);

    // v1 积分体系：邀请奖励改为积分
    await PointsService.instance.addPoints(PointsService.invitePoints, 'invite');

    final count = myList.length;
    if (count >= 1) _unlockBadge('referral_first');
    if (count >= 3) _unlockBadge('referral_three');
    if (count >= 5) _unlockBadge('referral_five');
    if (count >= 10) _unlockBadge('referral_ten');

    return _currentMilestone(count);
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

  /// 被邀请人7天高级统计体验是否仍有效
  bool isAdvancedStatsTrialActive() {
    final settings = Storage.getSettings();
    final until = settings['advancedStatsTrialUntil'] as int?;
    if (until == null) return false;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  /// v1 全免费策略下，高级统计始终开放；
  /// 此方法保留供 v2 启用 Pro 时使用。
  bool isAdvancedStatsAvailable() {
    // v1: 全免费开放（依据 01_迭代方案.md §2.4）
    return true;
  }
}
