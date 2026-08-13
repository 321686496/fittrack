import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 关于页面（独立页面，替代原"关于"弹窗）
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => Navigator.of(context).pop(),
            title: '关于 LiftTrack',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 应用信息卡片 ──
                  CardWidget(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 72,
                              height: 72,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.fitness_center,
                                size: 56,
                                color: colors.accentGlow,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'LiftTrack（燃力）',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '版本 1.0.0',
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '一款简洁高效的健身训练助手，帮助你制定个性化训练计划、记录每次训练数据、追踪身体数据变化、统计训练成就。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── 功能亮点 ──
                  CardWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: '核心功能'),
                        const SizedBox(height: 4),
                        _buildFeature(colors, Icons.edit_calendar_outlined, '个性化训练计划', '支持自定义与系统模板计划'),
                        const DividerWidget(indent: 40),
                        _buildFeature(colors, Icons.play_circle_outline, '训练执行与记录', '组间休息倒计时、实时记录'),
                        const DividerWidget(indent: 40),
                        _buildFeature(colors, Icons.query_stats, '统计与进度追踪', '周度统计、肌肉分布、身体数据趋势'),
                        const DividerWidget(indent: 40),
                        _buildFeature(colors, Icons.school_outlined, '教学课程与动作库', '系统化课程与海量动作教学'),
                        const DividerWidget(indent: 40),
                        _buildFeature(colors, Icons.privacy_tip_outlined, '本地数据存储', '所有数据仅保存在设备本地'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── 法律文档入口 ──
                  CardWidget(
                    child: Column(
                      children: [
                        _buildMenuTile(colors, Icons.description_outlined, '隐私政策', () {
                          context.push('/privacy-full');
                        }),
                        const DividerWidget(indent: 44),
                        _buildMenuTile(colors, Icons.article_outlined, '用户协议', () {
                          context.push('/agreement');
                        }),
                        const DividerWidget(indent: 44),
                        _buildMenuTile(colors, Icons.help_outline, '帮助与反馈', () {
                          context.push('/help-feedback');
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      '© 2026 LiftTrack',
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

  Widget _buildFeature(LiftTrackColors colors, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colors.accentGlow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: colors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(LiftTrackColors colors, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: colors.accentGlow),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
