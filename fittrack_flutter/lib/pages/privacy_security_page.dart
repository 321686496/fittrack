import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

import '../l10n/i18n.dart';
/// 隐私与安全页面（独立页面，替代原"隐私设置/隐私与安全"弹窗）
class PrivacySecurityPage extends StatelessWidget {
  PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => Navigator.of(context).pop(),
            title: tr(context, '隐私与安全'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 隐私承诺 ──
                  CardWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 22, color: colors.successColor),
                            SizedBox(width: 8),
                            // 英文标题更长，用 Expanded 占满剩余宽度并允许换行
                            Expanded(
                              child: Text(
                                tr(context, 'LiftTrack 尊重您的隐私'),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildPrivacyItem(colors, Icons.lock_outline, tr(context, '本地存储'), tr(context, '所有数据仅存储在您的设备本地，不会上传至任何服务器')),
                        SizedBox(height: 8),
                        _buildPrivacyItem(colors, Icons.person_outline, tr(context, '不收集个人信息'), tr(context, '不收集姓名、手机号、通讯录等个人敏感信息')),
                        SizedBox(height: 8),
                        _buildPrivacyItem(colors, Icons.notifications_outlined, tr(context, '通知权限'), tr(context, '通知权限仅用于训练提醒，不会用于其他用途')),
                        SizedBox(height: 8),
                        _buildPrivacyItem(colors, Icons.vibration, tr(context, '振动权限'), tr(context, '振动权限仅用于训练结束时提醒')),
                        SizedBox(height: 8),
                        _buildPrivacyItem(colors, Icons.photo_library_outlined, tr(context, '相册权限'), tr(context, '仅在您主动选择图片（如自定义动作封面）时使用')),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // ── 数据管理 ──
                  CardWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: tr(context, '数据管理')),
                        SizedBox(height: 4),
                        _buildMenuTile(colors, Icons.manage_accounts_outlined, tr(context, '数据与隐私'), tr(context, '导出、清除全部本地数据'), () {
                          context.push('/data-privacy');
                        }),
                        DividerWidget(indent: 44),
                        _buildMenuTile(colors, Icons.description_outlined, tr(context, '隐私政策'), tr(context, '查看完整隐私政策文本'), () {
                          context.push('/privacy-full');
                        }),
                        DividerWidget(indent: 44),
                        _buildMenuTile(colors, Icons.article_outlined, tr(context, '用户协议'), tr(context, '查看完整用户协议文本'), () {
                          context.push('/agreement');
                        }),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.infoColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: colors.infoColor),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr(context, '您可以随时在"数据与隐私"中导出或清除全部数据。清除后数据不可恢复，请谨慎操作。'),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(LiftTrackColors colors, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.accentGlow),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text(desc, style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(LiftTrackColors colors, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.accentGlow),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
