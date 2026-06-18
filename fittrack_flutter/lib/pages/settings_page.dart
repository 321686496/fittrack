import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
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
    FitToast.success(context, '训练默认值已保存');
  }

  Future<void> _exportData() async {
    try {
      final json = Storage.exportAllDataJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        FitToast.success(context, '数据已复制到剪贴板');
      }
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '导出失败');
      }
    }
  }

  Future<void> _importData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '导入数据',
      content: '请确保已将数据 JSON 复制到剪贴板。导入将覆盖当前所有数据，是否继续？',
      confirmText: '导入',
      confirmColor: Colors.blue,
      icon: Icons.download_outlined,
    );
    if (confirmed != true) return;

    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipData?.text == null || clipData!.text!.isEmpty) {
        if (mounted) FitToast.error(context, '剪贴板为空');
        return;
      }
      final data = jsonDecode(clipData.text!) as Map<String, dynamic>;
      final success = await Storage.importDataAsync(data);
      if (mounted) {
        if (success) {
          FitToast.success(context, '数据导入成功');
        } else {
          FitToast.error(context, '数据格式不正确');
        }
      }
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '导入失败：数据格式错误');
      }
    }
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

  void _showAbout() {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Row(
          children: [
            Icon(Icons.fitness_center, color: colors.accentGlow, size: 28),
            const SizedBox(width: 10),
            Text('FitTrack', style: TextStyle(color: colors.textPrimary, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本 1.0.0',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '一款简洁高效的健身训练助手，帮助你：\n\n'
              '• 制定个性化训练计划\n'
              '• 记录每次训练数据\n'
              '• 追踪身体数据变化\n'
              '• 统计训练成就\n\n'
              '所有数据仅保存在本地设备，不会上传至任何服务器。',
              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
            ),
          ],
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

  void _showPrivacyInfo() {
    InfoDialog.show(
      context,
      title: '隐私设置',
      content:
        'FitTrack 尊重您的隐私：\n\n'
        '• 所有数据仅存储在本地设备\n'
        '• 不会上传任何个人信息到服务器\n'
        '• 通知权限仅用于训练提醒\n'
        '• 振动权限仅用于休息结束提醒\n'
        '• 您可以随时在此清除所有数据',
      icon: Icons.privacy_tip_outlined,
    );
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
                  SectionHeader(title: '风格主题'),
                  const SizedBox(height: 10),
                  _buildThemeGrid(colors),
                  const SizedBox(height: 20),
                  SectionHeader(title: '训练设置'),
                  const SizedBox(height: 10),
                  _buildTrainingSettings(colors),
                  const SizedBox(height: 20),
                  SectionHeader(title: '数据管理'),
                  const SizedBox(height: 10),
                  _buildDataMenu(colors),
                  const SizedBox(height: 20),
                  SectionHeader(title: '其他'),
                  const SizedBox(height: 10),
                  _buildOtherMenu(colors),
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
          _buildSettingRow(
            colors,
            icon: Icons.timer_outlined,
            label: '默认休息时间 (秒)',
            controller: _restTimeController,
            unit: '秒',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          _buildSettingRow(
            colors,
            icon: Icons.repeat,
            label: '默认组数',
            controller: _defaultSetsController,
            unit: '组',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          _buildSettingRow(
            colors,
            icon: Icons.format_list_numbered,
            label: '默认每组次数',
            controller: _defaultRepsController,
            unit: '次',
          ),
          DividerWidget(indent: 0),
          const SizedBox(height: 8),
          _buildSettingRow(
            colors,
            icon: Icons.monitor_weight_outlined,
            label: '默认重量 (kg)',
            controller: _defaultWeightController,
            unit: 'kg',
            isDecimal: true,
          ),
          const SizedBox(height: 12),
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

  Widget _buildDataMenu(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        children: [
          _buildMenuTile(colors, Icons.upload_file_outlined, '导出数据', '复制所有数据到剪贴板', _exportData),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.download_outlined, '导入数据', '从剪贴板粘贴数据', _importData),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.delete_outline, '清除数据', '删除所有训练计划和记录', _clearData, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildOtherMenu(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        children: [
          _buildMenuTile(colors, Icons.alarm_outlined, '训练提醒', '设置休息提醒与通知', () {
            context.push('/reminder-settings');
          }),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.privacy_tip_outlined, '隐私设置', '查看隐私与权限说明', _showPrivacyInfo),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.info_outline, '关于 FitTrack', '版本 1.0.0', _showAbout),
        ],
      ),
    );
  }

  Widget _buildMenuTile(FitTrackColors colors, IconData icon, String title, String subtitle, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color ?? colors.accentGlow),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color ?? colors.textPrimary,
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
}
