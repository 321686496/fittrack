import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../services/invitation_service.dart';
import '../services/clipboard_invite_service.dart';
import 'common_widgets.dart';

/// v1 一键裂变 —— 邀请码激活横幅
///
/// 依据：docs/versions/v1-获客留存版/03_开发目标.md 任务4a-4.3/4.4
///
/// 展示时机：应用启动检测到剪贴板含邀请码且用户未激活
/// 展示内容："发现邀请码 FIT-INV-XXXXXX，是否激活？"
/// 操作：
/// - 激活：1次点击完成激活（对比原方案：输入码+点击=多步）
/// - 忽略：本次会话不再提示
class InviteActivationBanner extends StatefulWidget {
  final String inviteCode;
  final VoidCallback onDismissed;

  const InviteActivationBanner({
    super.key,
    required this.inviteCode,
    required this.onDismissed,
  });

  @override
  State<InviteActivationBanner> createState() => _InviteActivationBannerState();
}

class _InviteActivationBannerState extends State<InviteActivationBanner> {
  bool _activating = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Material(
      color: colors.accentGlow,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.card_giftcard, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '发现邀请码',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.inviteCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // 忽略
              TextButton(
                onPressed: _dismiss,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('忽略', style: TextStyle(fontSize: 13)),
              ),
              // 激活
              ElevatedButton(
                onPressed: _activating ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colors.accentGlow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
                child: _activating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black54),
                      )
                    : const Text('激活',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    ClipboardInviteService.instance.dismiss(widget.inviteCode);
    widget.onDismissed();
  }

  Future<void> _activate() async {
    setState(() => _activating = true);

    final result = await InvitationService.instance
        .activateInvitationCode(widget.inviteCode);

    if (!mounted) return;

    setState(() => _activating = false);

    String msg;
    bool success = false;
    switch (result) {
      case InvitationResult.success:
        msg = '激活成功！已获得7天高级统计全开放体验';
        success = true;
        break;
      case InvitationResult.invalidFormat:
        msg = '邀请码格式错误';
        break;
      case InvitationResult.invalidSignature:
        msg = '邀请码无效';
        break;
      case InvitationResult.selfInvite:
        msg = '不能输入自己的邀请码';
        break;
      case InvitationResult.alreadyActivated:
        msg = '已激活过邀请码';
        break;
    }

    if (success) {
      // 清除剪贴板，避免下次再提示
      await ClipboardInviteService.instance.clearClipboard();
    }

    if (!mounted) return;

    if (success) {
      FitToast.success(context, msg);
    } else {
      FitToast.error(context, msg);
    }

    widget.onDismissed();
  }
}
