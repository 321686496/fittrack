import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/legal/legal_content.dart';
import '../themes/app_themes.dart';

/// 协议同意弹窗（首次启动或协议版本升级时，在 splash 页展示）
///
/// 展示《用户协议》《隐私政策》摘要与查看入口，用户必须选择「同意并继续」
/// 或「不同意并退出」，无法点击外部关闭。
class PrivacyConsentDialog extends StatelessWidget {
  final VoidCallback onAgree;
  final VoidCallback onDecline;

  const PrivacyConsentDialog({
    super.key,
    required this.onAgree,
    required this.onDecline,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onAgree,
    required VoidCallback onDecline,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrivacyConsentDialog(onAgree: onAgree, onDecline: onDecline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Dialog(
      backgroundColor: colors.bgCard,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 标题 ──
            Container(
              alignment: Alignment.center,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.accentGlow.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.shield_outlined, size: 26, color: colors.accentGlow),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '欢迎使用 LiftTrack',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '感谢你选择 LiftTrack。在使用前，请阅读并同意以下协议。\n我们非常重视你的隐私，你的所有数据仅保存在设备本地。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            // ── 协议入口链接 ──
            _LinkTile(
              colors: colors,
              icon: Icons.article_outlined,
              title: '《用户协议》',
              onTap: () => context.push('/agreement'),
            ),
            const SizedBox(height: 10),
            _LinkTile(
              colors: colors,
              icon: Icons.description_outlined,
              title: '《隐私政策》',
              onTap: () => context.push('/privacy-full'),
            ),
            const SizedBox(height: 20),
            // ── 同意并继续 ──
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onAgree,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('同意并继续', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            // ── 不同意并退出 ──
            SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onDecline,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.textMuted.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('不同意并退出', style: TextStyle(color: colors.textMuted, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '协议版本 $privacyPolicyVersion · 更新于 2026-08-27',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted.withOpacity(0.8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// 可点击的协议条目
class _LinkTile extends StatelessWidget {
  final LiftTrackColors colors;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LinkTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.accentGlow.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colors.accentGlow),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
