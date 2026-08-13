import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 帮助与反馈页面（独立页面，替代原"帮助与反馈"弹窗）
///
/// 联系方式：上线前请将下方占位联系方式替换为真实值。
class HelpFeedbackPage extends StatelessWidget {
  const HelpFeedbackPage({super.key});

  /// 官方联系方式（上线前替换为真实信息）
  static const List<Map<String, String>> kContactChannels = [
    {'type': 'qq', 'icon': '群聊', 'label': 'QQ 群', 'value': '123456789', 'hint': '复制群号后到 QQ 搜索加入'},
    {'type': 'wechat_group', 'icon': '群聊', 'label': '微信群', 'value': '添加客服微信号后邀请进群', 'hint': '扫描二维码或添加客服进群'},
    {'type': 'wechat', 'icon': '微信', 'label': '客服微信', 'value': 'LiftTrack_Support', 'hint': '添加时备注“LiftTrack 用户”'},
    {'type': 'email', 'icon': '邮件', 'label': '邮箱', 'value': 'support@lifttrack.cn', 'hint': '反馈问题请附上设备型号与版本'},
  ];

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
                  // ── 联系我们 ──
                  const SectionHeader(title: '联系我们'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: kContactChannels.map((c) {
                        return _buildContactTile(context, colors, c);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildContactTile(BuildContext context, LiftTrackColors colors, Map<String, String> c) {
    final type = c['type'];
    final IconData icon;
    if (type == 'email') {
      icon = Icons.email_outlined;
    } else if (type == 'wechat' || type == 'wechat_group') {
      icon = Icons.chat_bubble_outline;
    } else {
      icon = Icons.groups_outlined;
    }
    return InkWell(
      onTap: () => _copyContact(context, c),
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
                  Text(c['label']!, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(c['value']!, style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(c['hint']!, style: TextStyle(color: colors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 16, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _copyContact(BuildContext context, Map<String, String> c) async {
    await Clipboard.setData(ClipboardData(text: c['value']!));
    if (context.mounted) {
      FitToast.success(context, '${c['label']} 已复制');
    }
  }
}
