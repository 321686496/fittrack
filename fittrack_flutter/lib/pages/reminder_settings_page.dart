import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/rest_notification_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

/// 训练提醒设置页面
class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  bool _restNotificationEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;
  int _defaultRestTime = 90;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = Storage.getSettings();
    setState(() {
      _restNotificationEnabled = settings['restNotificationEnabled'] as bool? ?? true;
      _vibrationEnabled = settings['vibrationEnabled'] as bool? ?? true;
      _soundEnabled = settings['soundEnabled'] as bool? ?? true;
      _defaultRestTime = settings['defaultRestTime'] as int? ?? 90;
    });
  }

  void _saveSetting(String key, dynamic value) {
    final settings = Storage.getSettings();
    settings[key] = value;
    Storage.saveSettings(settings);
  }

  Future<void> _testNotification() async {
    await RestNotificationService.instance.showRestEndNotification(
      exerciseName: '测试动作',
    );
    if (mounted) {
      FitToast.success(context, '测试通知已发送，请查看通知栏');
    }
  }

  Future<void> _testVibration() async {
    await RestNotificationService.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '训练提醒',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: '休息提醒'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          colors,
                          icon: Icons.notifications_active_outlined,
                          title: '休息结束通知',
                          subtitle: '组间休息倒计时结束时发送通知',
                          value: _restNotificationEnabled,
                          onChanged: (v) {
                            setState(() => _restNotificationEnabled = v);
                            _saveSetting('restNotificationEnabled', v);
                          },
                        ),
                        DividerWidget(indent: 44),
                        _buildSwitchTile(
                          colors,
                          icon: Icons.vibration,
                          title: '振动提醒',
                          subtitle: '训练结束时振动提醒',
                          value: _vibrationEnabled,
                          onChanged: (v) {
                            setState(() => _vibrationEnabled = v);
                            _saveSetting('vibrationEnabled', v);
                          },
                        ),
                        DividerWidget(indent: 44),
                        _buildSwitchTile(
                          colors,
                          icon: Icons.volume_up_outlined,
                          title: '提示音',
                          subtitle: '休息结束时播放提示音',
                          value: _soundEnabled,
                          onChanged: (v) {
                            setState(() => _soundEnabled = v);
                            _saveSetting('soundEnabled', v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: '默认休息时间'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, size: 22, color: colors.accentGlow),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '组间休息时间',
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '每个动作组间的默认休息秒数',
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.accentGlow.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_defaultRestTime 秒',
                                  style: TextStyle(
                                    color: colors.accentGlow,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _defaultRestTime.toDouble(),
                          min: 15,
                          max: 300,
                          divisions: 57,
                          activeColor: colors.accentGlow,
                          inactiveColor: colors.accentGlow.withOpacity(0.2),
                          onChanged: (v) {
                            setState(() => _defaultRestTime = v.round());
                          },
                          onChangeEnd: (v) {
                            _saveSetting('defaultRestTime', v.round());
                            _saveSetting('restTime', v.round());
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('15秒', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                              Text('300秒', style: TextStyle(color: colors.textMuted, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(title: '测试'),
                  const SizedBox(height: 10),
                  CardWidget(
                    child: Column(
                      children: [
                        _buildActionTile(
                          colors,
                          icon: Icons.notifications_outlined,
                          title: '发送测试通知',
                          subtitle: '验证通知功能是否正常',
                          onTap: _testNotification,
                        ),
                        DividerWidget(indent: 44),
                        _buildActionTile(
                          colors,
                          icon: Icons.vibration,
                          title: '测试振动',
                          subtitle: '验证振动功能是否正常',
                          onTap: _testVibration,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTipCard(colors),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    FitTrackColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.accentGlow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colors.accentGlow,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    FitTrackColors colors, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(FitTrackColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.accentGlow.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.accentGlow.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.accentGlow),
              const SizedBox(width: 8),
              Text(
                '提示',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 应用在前台时，休息结束会立即通知\n'
            '• 训练完成时会振动提醒（可在上方开关控制）\n'
            '• 应用在后台时，切回应用后会立即提醒\n'
            '• 后台代理提醒权限正在申请中，后续版本将支持后台通知',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
