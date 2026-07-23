import 'dart:convert';
import 'package:crypto/crypto.dart';

/// v1 训练计划分享码（UGC）—— 编码/解码服务
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E4
/// 设计要点：
/// - 分享码格式：FITT-XXXXXX（6位，与邀请码 FIT-INV- 区分）
/// - JSON 压缩 + Base32 编码
/// - 容量 ≤200 字符
/// - 含计划名称 + 动作列表 + 组数/重量/次数
/// - 作者署名（用户自定义昵称，再分享时保留）
/// - 导入内容校验（单次训练量超阈值弹警告）

/// 分享码验证结果
enum ShareCodeResult {
  success,
  invalidFormat,
  invalidSignature,
  payloadTooLarge,
  decodeError,
}

/// 导入警告类型
enum ImportWarning {
  none, // 无警告
  excessiveVolume, // 单次训练量超阈值（>50组）
  excessiveFrequency, // 每周频率超阈值
}

/// 分享码导入结果
class ShareCodeImportResult {
  final ShareCodeResult result;
  final ImportWarning warning;
  final Map<String, dynamic>? planData;

  const ShareCodeImportResult({
    required this.result,
    this.warning = ImportWarning.none,
    this.planData,
  });
}

class ShareCodeService {
  static final ShareCodeService instance = ShareCodeService._();
  ShareCodeService._();

  /// 分享码密钥（与邀请码、兑换码完全隔离）
  static const String _shareCodeSecret = 'fitTrack_sharecode_secret_v1_2026';

  /// 分享码格式：FITT-XXXXXX（6位大写字母数字）
  static final RegExp _pattern = RegExp(r'^FITT-([A-Z0-9]{6})$');

  /// Base32 字母表（RFC 4648，去除易混淆字符）
  static const String _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// 单次训练量阈值（组数）
  static const int _maxSetsPerSession = 50;

  /// 每周频率阈值（次/周）
  static const int _maxFrequencyPerWeek = 7;

  /// 计划摘要数据 → 分享码
  ///
  /// 输入：{
  ///   'name': '三分化增肌计划',
  ///   'type': '三分化',
  ///   'frequency': '6天/周',
  ///   'difficulty': '进阶',
  ///   'days': [...],
  ///   'author': '钢铁小子'  // 可选
  /// }
  ///
  /// 输出：FITT-XXXXXX
  ///
  /// 算法：
  /// 1. JSON 序列化 + UTF-8 编码
  /// 2. SHA-256 哈希得到 32 字节
  /// 3. 取前 5 字节（40 bit）= 8 个 Base32 字符
  /// 4. 但分享码限制 6 位，所以取前 3.75 字节 → 实际取 4 字节前 30 bit
  /// 5. 末位加 2 位 HMAC 签名验证
  ///
  /// 由于 6 位 Base32 仅能编码 30 bit（约 10 亿种），无法完整携带计划内容。
  /// 实际方案：分享码作为"短链 ID"，计划内容通过 Deeplink 或剪贴板传输。
  ///
  /// 此处实现简化方案：
  /// - 6 位 = 4 位内容哈希（用于识别）+ 2 位 HMAC 签名
  /// - 计划完整 JSON 通过剪贴板复制传输
  /// - 6 位码仅用于快速匹配和验证
  String generateCode(Map<String, dynamic> planData) {
    final json = jsonEncode(planData);
    final bytes = utf8.encode(json);

    // 计算内容哈希（前4位）
    final contentDigest = sha256.convert(bytes);
    final codeChars = <String>[];
    for (int i = 0; i < 4; i++) {
      codeChars.add(_alphabet[contentDigest.bytes[i] % _alphabet.length]);
    }
    final contentPart = codeChars.join();

    // 计算签名（后2位）
    final sigHmac = Hmac(sha256, utf8.encode(_shareCodeSecret));
    final sigDigest = sigHmac.convert(utf8.encode(contentPart));
    final sigChars = <String>[];
    for (int i = 0; i < 2; i++) {
      sigChars.add(_alphabet[sigDigest.bytes[i] % _alphabet.length]);
    }
    final sigPart = sigChars.join();

    return 'FITT-$contentPart$sigPart';
  }

  /// 生成完整分享内容（计划 JSON + 分享码）
  ///
  /// 实际使用场景：
  /// - 复制到剪贴板："FITT-XXXXXX|<base64-json>"
  /// - 通过社交平台分享
  /// - 接收方粘贴后解析
  String generateShareableString(Map<String, dynamic> planData) {
    final code = generateCode(planData);
    final json = jsonEncode(planData);
    final base64 = base64Url.encode(utf8.encode(json));
    return '$code|$base64';
  }

  /// 验证分享码格式与签名
  bool _verifySignature(String code) {
    final match = _pattern.firstMatch(code);
    if (match == null) return false;
    final payload = match.group(1)!;
    if (payload.length != 6) return false;

    final contentPart = payload.substring(0, 4);
    final providedSig = payload.substring(4, 6);

    final sigHmac = Hmac(sha256, utf8.encode(_shareCodeSecret));
    final sigDigest = sigHmac.convert(utf8.encode(contentPart));
    final expectedSig = <String>[];
    for (int i = 0; i < 2; i++) {
      expectedSig.add(_alphabet[sigDigest.bytes[i] % _alphabet.length]);
    }
    return expectedSig.join() == providedSig;
  }

  /// 从分享字符串解析计划数据
  ///
  /// 输入格式：FITT-XXXXXX|<base64-json>
  /// 或仅 FITT-XXXXXX（仅验证码，不含计划内容）
  ShareCodeImportResult importFromString(String input) {
    final trimmed = input.trim();

    // 检查是否包含完整计划数据
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      if (parts.length != 2) {
        return const ShareCodeImportResult(result: ShareCodeResult.invalidFormat);
      }
      final code = parts[0].toUpperCase();
      final base64Data = parts[1];

      if (!_pattern.hasMatch(code)) {
        return const ShareCodeImportResult(result: ShareCodeResult.invalidFormat);
      }
      if (!_verifySignature(code)) {
        return const ShareCodeImportResult(result: ShareCodeResult.invalidSignature);
      }

      try {
        final jsonBytes = base64Url.decode(base64Data);
        final jsonStr = utf8.decode(jsonBytes);
        final rawPlanData = jsonDecode(jsonStr) as Map<String, dynamic>;
        final planData = deepNormalizePlan(rawPlanData);
        normalizeWeightFieldsPublic(planData);
        final warning = _validatePlan(planData);
        return ShareCodeImportResult(
          result: ShareCodeResult.success,
          warning: warning,
          planData: planData,
        );
      } catch (_) {
        return const ShareCodeImportResult(result: ShareCodeResult.decodeError);
      }
    }

    // 仅 6 位码：无法获取计划内容（单机版限制）
    // 联网版可通过分享码查询服务器获取计划
    final code = trimmed.toUpperCase();
    if (!_pattern.hasMatch(code)) {
      return const ShareCodeImportResult(result: ShareCodeResult.invalidFormat);
    }
    if (!_verifySignature(code)) {
      return const ShareCodeImportResult(result: ShareCodeResult.invalidSignature);
    }
    return const ShareCodeImportResult(result: ShareCodeResult.success);
  }

  /// 导入内容校验
  ///
  /// 检查项：
  /// - 单次训练量超阈值（>50组）→ excessiveVolume
  /// - 每周频率超阈值（>7次/周）→ excessiveFrequency
  ImportWarning _validatePlan(Map<String, dynamic> planData) {
    final days = planData['days'] as List?;
    if (days == null) return ImportWarning.none;

    int maxSetsInDay = 0;
    for (final day in days) {
      final exercises = (day as Map)['exercises'] as List?;
      if (exercises == null) continue;
      int daySets = 0;
      for (final ex in exercises) {
        daySets += ((ex as Map)['sets'] as int?) ?? 0;
      }
      if (daySets > maxSetsInDay) maxSetsInDay = daySets;
    }

    if (maxSetsInDay > _maxSetsPerSession) {
      return ImportWarning.excessiveVolume;
    }

    final frequencyStr = planData['frequency'] as String? ?? '';
    final freqMatch = RegExp(r'(\d+)').firstMatch(frequencyStr);
    if (freqMatch != null) {
      final freq = int.parse(freqMatch.group(1)!);
      if (freq > _maxFrequencyPerWeek) {
        return ImportWarning.excessiveFrequency;
      }
    }

    return ImportWarning.none;
  }

  /// 添加作者署名到计划数据
  Map<String, dynamic> attachAuthorSignature(
      Map<String, dynamic> planData, String authorName) {
    return {
      ...planData,
      'author': authorName,
      'sharedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// 检查计划是否含作者署名
  String? getAuthor(Map<String, dynamic> planData) {
    final author = planData['author'];
    return author is String && author.isNotEmpty ? author : null;
  }

  /// 6位码手动输入校验（不含计划内容）
  ///
  /// 返回 true 表示格式与签名均正确
  bool validateCode(String code) {
    final normalized = code.toUpperCase().trim();
    if (!_pattern.hasMatch(normalized)) return false;
    return _verifySignature(normalized);
  }

  /// 深拷贝并归一化计划数据
  ///
  /// 修复 JSON 反序列化后的类型问题：
  /// - Map → Map<String, dynamic>（递归）
  /// - List → List（递归归一化每个元素）
  static Map<String, dynamic> deepNormalizePlan(Map<String, dynamic> input) {
    final result = <String, dynamic>{};
    for (final entry in input.entries) {
      result[entry.key] = _normalizeValue(entry.value);
    }
    return result;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in value.entries) {
        if (entry.key is String) {
          normalized[entry.key as String] = _normalizeValue(entry.value);
        }
      }
      return normalized;
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }

  /// 归一化计划中的 weight 字段为 double
  static void normalizeWeightFieldsPublic(Map<String, dynamic> planData) {
    final days = planData['days'] as List?;
    if (days == null) return;
    for (final day in days) {
      if (day is! Map) continue;
      final exercises = day['exercises'] as List?;
      if (exercises == null) continue;
      for (final ex in exercises) {
        if (ex is! Map) continue;
        final w = ex['weight'];
        if (w is int) {
          ex['weight'] = w.toDouble();
        }
        final setConfig = ex['setConfig'] as List?;
        if (setConfig != null) {
          for (final cfg in setConfig) {
            if (cfg is! Map) continue;
            final cw = cfg['weight'];
            if (cw is int) {
              cfg['weight'] = cw.toDouble();
            }
          }
        }
      }
    }
  }
}
