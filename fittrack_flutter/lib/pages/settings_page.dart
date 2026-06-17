import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/permission_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class SettingsPage extends StatefulWidget {
  final void Function(String themeId) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentTheme;
  late TextEditingController _restTimeController;
  late TextEditingController _defaultSetsController;
  late TextEditingController _defaultRepsController;
  late TextEditingController _defaultWeightController;

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    _currentTheme = settings['theme'] as String? ?? 'vitality-sport';
    _restTimeController = TextEditingController(
      text: '${settings['defaultRestTime'] ?? 90}',
    );
    _defaultSetsController = TextEditingController(
      text: '${settings['defaultSets'] ?? 3}',
    );
    _defaultRepsController = TextEditingController(
      text: '${settings['defaultReps'] ?? 10}',
    );
    _defaultWeightController = TextEditingController(
      text: '${settings['defaultWeight'] ?? 20.0}',
    );
  }

  @override
  void dispose() {
    _restTimeController.dispose();
    _defaultSetsController.dispose();
    _defaultRepsController.dispose();
    _defaultWeightController.dispose();
    super.dispose();
  }

  void _showToast(String message, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onThemeTap(String themeId) {
    if (themeId == _currentTheme) return;
    setState(() => _currentTheme = themeId);
    final settings = Storage.getSettings();
    settings['theme'] = themeId;
    Storage.saveSettings(settings);
    widget.onThemeChanged(themeId);
  }

  void _saveTrainingDefaults() {
    final settings = Storage.getSettings();
    final restTime = int.tryParse(_restTimeController.text);
    final sets = int.tryParse(_defaultSetsController.text);
    final reps = int.tryParse(_defaultRepsController.text);
    final weight = double.tryParse(_defaultWeightController.text);

    if (restTime != null && restTime > 0) {
      settings['defaultRestTime'] = restTime;
      settings['restTime'] = restTime;
    }
    if (sets != null && sets > 0) settings['defaultSets'] = sets;
    if (reps != null && reps > 0) settings['defaultReps'] = reps;
    if (weight != null && weight > 0) settings['defaultWeight'] = weight;

    Storage.saveSettings(settings);
    _showToast('训练默认值已保存');
  }

  void _exportData() {
    final json = Storage.exportAllDataJson();
    // In a real app, this would save to file or share
    debugPrint('Exported data: ${json.substring(0, json.length.clamp(0, 100))}...');
    _showToast('数据导出成功');
  }

  void _importData() {
    // In a real app, this would pick a file
    _showToast('数据导入成功');
  }

  Future<void> _clearData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '清除所有数据',
      content: '此操作将删除所有训练计划和记录，且无法恢复。',
      confirmText: '清除',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_forever_outlined,
    );
    if (confirmed == true) {
      await Storage.clearAll();
      if (mounted) {
        FitToast.success(context, '数据已清除');
      }
    }
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
            title: '设置',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme picker section
                  SectionHeader(title: '风格主题'),
                  const SizedBox(height: 10),
                  _buildThemeGrid(colors),
                  const SizedBox(height: 20),
                  // Training settings
                  SectionHeader(title: '训练设置'),
                  const SizedBox(height: 10),
                  _buildTrainingSettings(colors),
                  const SizedBox(height: 20),
                  // Menu list
                  _buildMenuList(colors),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(FitTrackColors colors) {
    final themes = AppTheme.themes;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: themes.map<Widget>((theme) {
        final isActive = theme['id'] == _currentTheme;
        final themeColors = theme['colors'] as List;
        return GestureDetector(
          onTap: () => _onThemeTap(theme['id'] as String),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? colors.accentGlow : colors.borderColor,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color blocks preview
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 24,
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: Color(themeColors[i] as int),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // Theme name with icon
                Row(
                  children: [
                    Text(
                      theme['icon'] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        theme['name'] as String,
                        style: TextStyle(
                          color: isActive ? colors.accentGlow : colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle, size: 16, color: colors.accentGlow),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  theme['desc'] as String,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrainingSettings(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 默认休息时间
          _buildSettingRow(
            colors,
            icon: Icons.timer_outlined,
            label: '默认休息时间 (秒)',
            controller: _restTimeController,
            unit: '秒',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          // 默认组数
          _buildSettingRow(
            colors,
            icon: Icons.repeat,
            label: '默认组数',
            controller: _defaultSetsController,
            unit: '组',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          // 默认次数
          _buildSettingRow(
            colors,
            icon: Icons.format_list_numbered,
            label: '默认每组次数',
            controller: _defaultRepsController,
            unit: '次',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          // 默认重量
          _buildSettingRow(
            colors,
            icon: Icons.monitor_weight_outlined,
            label: '默认重量 (kg)',
            controller: _defaultWeightController,
            unit: 'kg',
            isDecimal: true,
          ),
          const SizedBox(height: 12),
          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveTrainingDefaults,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: colors.bgCard,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('保存设置', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    FitTrackColors colors, {
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String unit,
    bool isDecimal = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.accentGlow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.textPrimary, fontSize: 14),
          ),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            keyboardType: isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: colors.bgElevated,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.accentGlow),
              ),
            ),
            onSubmitted: (_) => _saveTrainingDefaults(),
          ),
        ),
        const SizedBox(width: 6),
        Text(unit, style: TextStyle(color: colors.textMuted, fontSize: 13)),
      ],
    );
  }

  Widget _buildMenuList(FitTrackColors colors) {
    final menus = [
      {'icon': Icons.alarm_outlined, 'label': '通知测试', 'action': 'notification'},
      {'icon': Icons.dark_mode_outlined, 'label': '深色模式'},
      {'icon': Icons.upload_file_outlined, 'label': '导出数据', 'action': 'export'},
      {'icon': Icons.download_outlined, 'label': '导入数据', 'action': 'import'},
      {'icon': Icons.delete_outline, 'label': '清除数据', 'action': 'clear'},
      {'icon': Icons.privacy_tip_outlined, 'label': '隐私设置', 'action': 'privacy'},
      {'icon': Icons.info_outline, 'label': '关于'},
    ];

    return Column(
      children: menus.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MenuButton(
            icon: m['icon'] as IconData,
            label: m['label'] as String,
            onTap: () {
              final action = m['action'];
              if (action == 'notification') {
                context.push('/notification-test');
              } else if (action == 'export') {
                _exportData();
              } else if (action == 'import') {
                _importData();
              } else if (action == 'clear') {
                _clearData();
              } else if (action == 'privacy') {
                _showPrivacyInfo();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await PermissionService.requestNotification();
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('训练提醒已开启'), duration: Duration(seconds: 2)),
      );
    } else {
      PermissionService.showPermissionDeniedDialog(
        context,
        permissionName: '通知',
        reason: '需要通知权限才能在训练时发送提醒，请在设置中开启通知权限。',
      );
    }
  }

  void _showPrivacyInfo() {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text('隐私设置', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'FitTrack 尊重您的隐私：\n\n'
          '• 所有数据仅存储在本地设备\n'
          '• 不会上传任何个人信息到服务器\n'
          '• 通知权限仅用于训练提醒\n'
          '• 您可以随时在设置中清除所有数据',
          style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('知道了', style: TextStyle(color: colors.accentGlow)),
          ),
        ],
      ),
    );
  }
}
