import 'package:flutter/services.dart';
import 'invitation_service.dart';

/// v1 一键裂变 —— 剪贴板邀请码检测服务
///
/// 依据：docs/versions/v1-获客留存版/03_开发目标.md 任务4a-4.3
///
/// 工作流程：
/// 1. 应用启动时读取剪贴板
/// 2. 正则匹配 FIT-INV-[A-Z0-9]{6} 或 fittrack://invite?code=FIT-INV-XXXXXX
/// 3. 如果匹配且用户未激活过邀请码，返回邀请码供 UI 提示
/// 4. 用户激活或忽略后，清除剪贴板检测标记（避免重复提示）
class ClipboardInviteService {
  static final ClipboardInviteService instance = ClipboardInviteService._();
  ClipboardInviteService._();

  /// 邀请码正则（6位字母数字，与 InvitationService._pattern 一致）
  static final RegExp _inviteCodePattern =
      RegExp(r'FIT-INV-([A-Z0-9]{6})');

  /// deeplink 正则：fittrack://invite?code=FIT-INV-XXXXXX
  static final RegExp _deeplinkPattern =
      RegExp(r'fittrack://invite\?code=(FIT-INV-[A-Z0-9]{6})');

  /// 已忽略的邀请码（本次会话内不重复提示）
  String? _dismissedCode;

  /// 检测剪贴板中的邀请码
  ///
  /// 返回值：
  /// - 非 null：检测到邀请码，UI 应显示激活提示
  /// - null：未检测到或已忽略或已激活
  Future<String?> detectInviteCode() async {
    // 已激活过邀请码则不再提示
    final activatedCode = InvitationService.instance.getActivatedCode();
    if (activatedCode != null) return null;

    // 读取剪贴板
    String? clipboardText;
    try {
      final data = await Clipboard.getData('text/plain');
      clipboardText = data?.text;
    } catch (_) {
      return null;
    }

    if (clipboardText == null || clipboardText.isEmpty) return null;

    // 先尝试 deeplink 格式
    final deeplinkMatch = _deeplinkPattern.firstMatch(clipboardText);
    if (deeplinkMatch != null) {
      final code = deeplinkMatch.group(1)!;
      if (code == _dismissedCode) return null;
      return code;
    }

    // 再尝试纯邀请码格式
    final codeMatch = _inviteCodePattern.firstMatch(clipboardText);
    if (codeMatch != null) {
      final code = codeMatch.group(0)!;
      if (code == _dismissedCode) return null;
      return code;
    }

    return null;
  }

  /// 标记邀请码为已忽略（本次会话不再提示）
  void dismiss(String code) {
    _dismissedCode = code;
  }

  /// 清除剪贴板中的邀请码（激活成功后调用）
  Future<void> clearClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}
  }
}
