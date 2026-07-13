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

  /// 检查权限并在未授权时弹出提示（供其他页面调用）
  static Future<bool> checkPermissionWithPrompt(BuildContext context, String permissionName) async {
    // 简化实现：总是返回 true，权限检查由原生侧处理
    // 此方法预留，后续可在其他页面调用
    return true;
  }
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentTheme;
  late TextEditingController _restTimeController;
  late TextEditingController _defaultSetsController;
  late TextEditingController _defaultRepsController;
  late TextEditingController _defaultWeightController;

  // 权限状态
  bool _hasNotificationPermission = false;
  bool _hasVibratePermission = false;
  bool _hasBackgroundPermission = false;

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
    _checkPermissions();
  }

  @override
  void dispose() {
    _restTimeController.dispose();
    _defaultSetsController.dispose();
    _defaultRepsController.dispose();
    _defaultWeightController.dispose();
    super.dispose();
  }

  /// 当前主题的元数据（图标、名称、配色）
  Map<String, dynamic> get _currentThemeMeta {
    return AppTheme.themes.firstWhere(
      (t) => t['id'] == _currentTheme,
      orElse: () => AppTheme.themes.first,
    );
  }

  String _getCurrentThemeIcon() => _currentThemeMeta['icon'] as String;
  String _getCurrentThemeName() => _currentThemeMeta['name'] as String;
  List<Color> _getCurrentThemeColors() {
    return (_currentThemeMeta['colors'] as List)
        .map((c) => Color(c as int))
        .toList();
  }

  /// 跳转到主题设置页，返回后刷新当前主题
  Future<void> _openThemeSettings() async {
    await context.push('/theme-settings', extra: _currentTheme);
    if (mounted) {
      setState(() {
        _currentTheme =
            Storage.getSettings()['theme'] as String? ?? 'vitality-sport';
      });
    }
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

  // ============================================================
  // 权限管理相关
  // ============================================================

  static const _permissionChannel = MethodChannel('com.example.fittrack_flutter/permission');

  /// 检查权限状态
  Future<void> _checkPermissions() async {
    try {
      final result = await _permissionChannel.invokeMethod('checkPermissions');
      if (result != null) {
        setState(() {
          _hasNotificationPermission = result['notification'] ?? false;
          _hasVibratePermission = result['vibrate'] ?? false;
          _hasBackgroundPermission = result['background'] ?? false;
        });
      }
    } catch (e) {
      // 如果 channel 不可用，默认为已授权（避免初次使用时困扰用户）
      setState(() {
        _hasNotificationPermission = true;
        _hasVibratePermission = true;
        _hasBackgroundPermission = true;
      });
    }
  }

  /// 跳转到应用设置
  Future<void> _openAppSettings() async {
    // 显示提示弹窗，引导用户去系统设置开启权限
    final confirmed = await ConfirmDialog.show(
      context,
      title: '前往应用设置',
      content: '即将跳转到系统应用管理页面，请在应用信息中手动开启对应权限。',
      confirmText: '去设置',
      icon: Icons.settings,
    );
    if (confirmed == true) {
      try {
        // 尝试通过 MethodChannel 跳转到系统设置
        await _permissionChannel.invokeMethod('openAppSettings');
      } catch (e) {
        // 如果 channel 不可用，显示提示
        if (mounted) {
          FitToast.warning(context, '请前往系统设置 > 应用 > FitTrack 开启权限');
        }
      }
      // 返回后重新检查权限状态
      _checkPermissions();
    }
  }

  /// 构建权限管理区块
  Widget _buildPermissionMenu(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: '权限管理'),
          const SizedBox(height: 12),
          _buildPermissionItem(colors, Icons.notifications_outlined, '通知权限', '用于训练提醒和休息结束通知', _hasNotificationPermission),
          DividerWidget(),
          _buildPermissionItem(colors, Icons.vibration, '震动权限', '休息结束时震动提醒', _hasVibratePermission),
          DividerWidget(),
          _buildPermissionItem(colors, Icons.schedule, '后台运行', '保证后台计时和提醒正常工作', _hasBackgroundPermission),
        ],
      ),
    );
  }

  /// 构建单个权限项
  Widget _buildPermissionItem(FitTrackColors colors, IconData icon, String title, String desc, bool granted) {
    return InkWell(
      onTap: () => _openAppSettings(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: granted ? colors.successColor : colors.warningColor),
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
            // 权限状态标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: granted ? colors.successColor.withOpacity(0.12) : colors.warningColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                granted ? '已开启' : '未开启',
                style: TextStyle(
                  color: granted ? colors.successColor : colors.warningColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
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
                  _buildThemeEntry(colors),
                  const SizedBox(height: 20),
                  SectionHeader(title: '训练设置'),
                  const SizedBox(height: 10),
                  _buildTrainingSettings(colors),
                  const SizedBox(height: 20),
                  SectionHeader(title: '数据管理'),
                  const SizedBox(height: 10),
                  _buildDataMenu(colors),
                  const SizedBox(height: 20),
                  _buildPermissionMenu(colors),
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

  Widget _buildThemeEntry(FitTrackColors colors) {
    return CardWidget(
      child: InkWell(
        onTap: _openThemeSettings,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Text(
                _getCurrentThemeIcon(),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '风格主题',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCurrentThemeName(),
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 当前主题色块预览
              Row(
                children: _getCurrentThemeColors()
                    .map((c) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
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
          _buildMenuTile(colors, Icons.description_outlined, '隐私政策', '查看完整隐私政策文本', () {
            context.push('/privacy-full');
          }),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.description_outlined, '用户协议', '查看完整用户协议文本', () {
            context.push('/agreement');
          }),
          DividerWidget(indent: 44),
          _buildMenuTile(colors, Icons.shield_outlined, '数据与隐私', '管理数据授权与清除全部数据', () {
            context.push('/data-privacy');
          }),
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
