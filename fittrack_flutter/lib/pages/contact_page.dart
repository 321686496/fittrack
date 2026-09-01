import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_info.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 联系我们页面（独立详情页，展示群二维码与群号等联系方式）
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => Navigator.of(context).pop(),
            title: '联系我们',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 顶部说明 ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.accentGlow.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.headset_mic_outlined, size: 22, color: colors.accentGlow),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '有问题？欢迎随时联系我们',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '如果你在使用过程中遇到任何问题、觉得有不好用或存在漏洞的地方，可以通过以下方式联系开发者，也可以直接发送邮件到邮箱反馈问题，我们会积极听取并采纳你的意见，把产品做得更好。',
                                style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '如果你觉得用得还不错，也欢迎加入官方社群，与爱训练的朋友们一起讨论交流、自律打卡～',
                                style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── 群聊（含二维码与群号） ──
                  ...kContactChannels
                      .where((c) => c.type == 'qq_group' || c.type == 'wechat_group')
                      .map((c) => _buildGroupCard(context, colors, c)),
                  const SizedBox(height: 16),
                  // ── 一对一联系方式 ──
                  CardWidget(
                    child: Column(
                      children: kContactChannels
                          .where((c) => c.type == 'wechat' || c.type == 'email')
                          .map((c) => _buildContactTile(context, colors, c))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '客服在线时间：每天 9:00 - 22:00',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 群卡片：二维码 + 群号 + 复制按钮
  Widget _buildGroupCard(
    BuildContext context,
    LiftTrackColors colors,
    ContactChannel c,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  c.type == 'qq_group' ? Icons.groups_outlined : Icons.chat_outlined,
                  size: 20,
                  color: colors.accentGlow,
                ),
                const SizedBox(width: 8),
                Text(
                  c.label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 二维码（本地二维码图片优先，缺失时按群号/链接生成）
                Container(
                  width: 128,
                  height: 128,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Image.asset(
                    'assets/images/contact/${c.type}_qr.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => QrImageView(
                      data: c.qrData ?? c.value,
                      version: QrVersions.auto,
                      size: 112,
                      gapless: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '群号：${c.value}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.hint,
                        style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _copyValue(context, c),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制群号'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accentGlow,
                          side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context,
    LiftTrackColors colors,
    ContactChannel c,
  ) {
    final isEmail = c.type == 'email';
    final IconData icon =
        isEmail ? Icons.email_outlined : Icons.chat_bubble_outline;
    return InkWell(
      onTap: () => isEmail ? _sendEmail(context, c) : _copyValue(context, c),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: colors.accentGlow),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.label,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(c.value,
                      style:
                          TextStyle(color: colors.accentGlow, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(c.hint,
                      style:
                          TextStyle(color: colors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isEmail ? Icons.send_outlined : Icons.copy_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, ContactChannel c) async {
    final uri = Uri(
      scheme: 'mailto',
      path: c.value,
      queryParameters: {'subject': 'LiftTrack 反馈'},
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        FitToast.info(context, '未找到邮件应用，请复制邮箱：${c.value}');
      }
    } catch (_) {
      if (context.mounted) {
        FitToast.info(context, '未找到邮件应用，请复制邮箱：${c.value}');
      }
    }
  }

  Future<void> _copyValue(BuildContext context, ContactChannel c) async {
    await Clipboard.setData(ClipboardData(text: c.value));
    if (context.mounted) {
      FitToast.success(context, '${c.label}已复制');
    }
  }
}
