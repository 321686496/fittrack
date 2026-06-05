import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ProfilePage extends StatelessWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const ProfilePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final body = MockData.bodyData;

    return Column(
      children: [
        const PageHeader(title: '我的', subtitle: '个人中心'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(colors),
                const SizedBox(height: 20),
                SectionHeader(title: '成就'),
                const SizedBox(height: 10),
                _buildAchievements(colors),
                const SizedBox(height: 20),
                SectionHeader(title: '身体数据'),
                const SizedBox(height: 10),
                _buildBodyData(colors, body),
                const SizedBox(height: 20),
                _buildMenuList(colors, context),
                const SizedBox(height: 16),
                _buildLogoutButton(colors, context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: colors.accentGlow, width: 2),
            ),
            child: Icon(Icons.person, size: 32, color: colors.accentGlow),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockData.user['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'fittrack@example.com',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textMuted, size: 22),
        ],
      ),
    );
  }

  Widget _buildAchievements(FitTrackColors colors) {
    final achievements = MockData.achievements;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: achievements.map<Widget>((a) {
        final unlocked = a['unlocked'] as bool;
        return Opacity(
          opacity: unlocked ? 1.0 : 0.4,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  a['icon'] as String,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  a['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  a['desc'] as String,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBodyData(FitTrackColors colors, Map<String, dynamic> body) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
              Text(
                '身体数据',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '更新于 ${body['lastUpdate']}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 4-column grid: height, weight, BMI, body fat
          Row(
            children: [
              _buildBodyItem(colors, '${body['height']}', 'cm', '身高'),
              _buildBodyItem(colors, '${body['weight']}', 'kg', '体重'),
              _buildBodyItem(colors, '${body['bmi']}', '', 'BMI'),
              _buildBodyItem(colors, '${body['bodyFat']}', '%', '体脂率'),
            ],
          ),
          const SizedBox(height: 12),
          DividerWidget(indent: 0),
          const SizedBox(height: 12),
          // 3-column detail: chest, waist, hip
          Row(
            children: [
              _buildBodyItem(colors, '${body['chest']}', 'cm', '胸围'),
              _buildBodyItem(colors, '${body['waist']}', 'cm', '腰围'),
              _buildBodyItem(colors, '${body['hip']}', 'cm', '臀围'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyItem(
      FitTrackColors colors, String value, String unit, String label) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(FitTrackColors colors, BuildContext ctx) {
    final menus = [
      {'icon': Icons.history, 'label': '训练记录', 'page': 'records'},
      {'icon': Icons.sports_gymnastics, 'label': '动作库', 'page': 'exercise'},
      {'icon': Icons.settings, 'label': '设置', 'page': 'settings'},
      {'icon': Icons.notifications_active_outlined, 'label': '提醒设置', 'page': ''},
      {'icon': Icons.watch_outlined, 'label': '设备连接', 'page': ''},
      {'icon': Icons.security_outlined, 'label': '隐私与安全', 'page': ''},
      {'icon': Icons.help_outline, 'label': '帮助与反馈', 'page': ''},
    ];

    return Column(
      children: menus.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MenuButton(
            icon: m['icon'] as IconData,
            label: m['label'] as String,
            onTap: () {
              final page = m['page'] as String;
              if (page.isNotEmpty) {
                onNavigate(page);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton(FitTrackColors colors, BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('已退出登录'),
              backgroundColor: colors.warningColor,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.warningColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          '退出登录',
          style: TextStyle(
            color: colors.warningColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
