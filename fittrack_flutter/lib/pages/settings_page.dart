import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class SettingsPage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;
  final void Function(String themeId) onThemeChanged;

  const SettingsPage({
    super.key,
    required this.onNavigate,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _currentTheme;
  late TextEditingController _restTimeController;

  @override
  void initState() {
    super.initState();
    final settings = Storage.getSettings();
    _currentTheme = settings['theme'] as String? ?? 'iron-forge';
    _restTimeController = TextEditingController(
      text: '${settings['defaultRestTime'] ?? 90}',
    );
  }

  @override
  void dispose() {
    _restTimeController.dispose();
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

  void _saveRestTime() {
    final val = int.tryParse(_restTimeController.text);
    if (val != null && val > 0) {
      final settings = Storage.getSettings();
      settings['defaultRestTime'] = val;
      settings['restTime'] = val;
      Storage.saveSettings(settings);
      _showToast('默认休息时间已更新为 ${val}秒');
    } else {
      _showToast('请输入有效时间', color: Colors.red);
    }
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

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(context).extension<FitTrackColors>()!;
        return AlertDialog(
          backgroundColor: colors.bgCard,
          title: const Text('确认清除', style: TextStyle(color: Colors.white)),
          content: const Text(
            '此操作将清除所有训练数据和计划，不可恢复。确定继续？',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('取消', style: TextStyle(color: colors.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Storage.clearAll();
                Navigator.pop(ctx);
                _showToast('数据已清除');
              },
              child: const Text('确认', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Column(
      children: [
        PageHeader(
          onBack: () => widget.onNavigate('profile'),
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
                          color: isActive ? colors.accentGlow : Colors.white,
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
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 20, color: colors.accentGlow),
              const SizedBox(width: 8),
              const Text(
                '默认休息时间',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _restTimeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '秒',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: colors.bgElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                  onSubmitted: (_) => _saveRestTime(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _saveRestTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.accentGlow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(FitTrackColors colors) {
    final menus = [
      {'icon': Icons.alarm_outlined, 'label': '训练提醒'},
      {'icon': Icons.dark_mode_outlined, 'label': '深色模式'},
      {'icon': Icons.upload_file_outlined, 'label': '导出数据', 'action': 'export'},
      {'icon': Icons.download_outlined, 'label': '导入数据', 'action': 'import'},
      {'icon': Icons.delete_outline, 'label': '清除数据', 'action': 'clear'},
      {'icon': Icons.privacy_tip_outlined, 'label': '隐私设置'},
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
              if (action == 'export') {
                _exportData();
              } else if (action == 'import') {
                _importData();
              } else if (action == 'clear') {
                _clearData();
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
