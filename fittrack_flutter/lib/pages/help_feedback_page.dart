import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 帮助与反馈页面（独立页面，替代原"帮助与反馈"弹窗）
///
/// 联系方式统一维护在 lib/data/contact_info.dart
class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => Navigator.of(context).pop(),
            title: '帮助与反馈',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 联系我们（显眼入口）──────────────────────
                  CardWidget(
                    onTap: () => context.push('/contact'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.headset_mic_outlined, color: colors.accentGlow, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '联系我们',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'QQ 群 · 微信群 · 客服微信 · 邮箱',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: colors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── 使用帮助 ──
                  const SectionHeader(title: '使用帮助'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildHelpStep(colors, '1', '创建计划', '在"计划"页面点击右下角 + 号，首次使用会弹出创建引导'),
                          _buildHelpStep(colors, '2', '开始训练', '选择计划后点击"开始训练"，按组间休息节奏完成训练'),
                          _buildHelpStep(colors, '3', '休息提醒', '休息倒计时结束后会振动并弹出通知提醒'),
                          _buildHelpStep(colors, '4', '自定义设置', '在"设置"中调整默认休息时间、组数、次数与重量'),
                          _buildHelpStep(colors, '5', '分享计划', '在"设置 → 计划分享"生成分享码/二维码，好友扫码或粘贴即可导入'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── 常见问题 ──
                  const SectionHeader(title: '常见问题'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: [
                        _buildFaqItem(colors, '休息提醒未收到？', '请检查系统设置中的通知权限是否开启，并允许横幅通知与锁屏通知。'),
                        _buildFaqItem(colors, '后台休息提醒不响？', '请允许应用后台运行，Android 部分机型需在系统设置中关闭电池优化。'),
                        _buildFaqItem(colors, '数据会丢失吗？', '数据保存在设备本地，卸载应用会清除数据。建议定期在"设置 → 导出数据"备份。'),
                        _buildFaqItem(colors, '如何导入好友的计划？', '在"设置 → 计划分享"粘贴分享串，或点击"扫码导入"扫描二维码。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.infoColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: colors.infoColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '欢迎加入官方社群，第一时间获取更新动态与训练干货；如有问题或建议，也欢迎通过以上方式反馈给我们！',
                            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
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

  Widget _buildHelpStep(LiftTrackColors colors, String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.accentGlow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(LiftTrackColors colors, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
