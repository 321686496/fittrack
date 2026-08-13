import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../router.dart' as app_router;
import '../widgets/common_widgets.dart';

class DataPrivacyPage extends StatefulWidget {
  const DataPrivacyPage({super.key});
  @override
  State<DataPrivacyPage> createState() => _DataPrivacyPageState();
}

class _DataPrivacyPageState extends State<DataPrivacyPage> {
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    final s = Storage.getSettings();
    _pushEnabled = s['smartPushEnabled'] ?? true;
  }

  Future<void> _togglePush(bool v) async {
    setState(() => _pushEnabled = v);
    final s = Storage.getSettings();
    s['smartPushEnabled'] = v;
    Storage.saveSettings(s);
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '确认清除',
      content: '此操作将删除所有训练记录、计划、身体数据。无法恢复。是否继续？',
      confirmText: '继续',
      cancelText: '取消',
      confirmColor: Colors.red,
      icon: Icons.warning_amber_rounded,
    );
    if (confirmed != true) return;
    await _showSecondConfirmation();
  }

  Future<void> _showSecondConfirmation() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('最终确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请输入"删除"二字以确认：'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              inputFormatters: [LengthLimitingTextInputFormatter(2)],
              decoration: const InputDecoration(hintText: '删除'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text == '删除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('永久清除'),
          ),
        ],
      ),
    );
    if (result != true) {
      // 输入不是"删除"时明确提示，而不是静默退出
      if (mounted && result == false) {
        FitToast.error(context, '请输入"删除"两个字以确认清除');
      }
      return;
    }
    await Storage.clearAll();
    if (mounted) {
      FitToast.success(context, '全部数据已清除');
      app_router.onThemeChanged?.call(Storage.getSettings()['theme'] ?? 'vitality-sport');
      context.go('/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据与隐私')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('通知'),
          SwitchListTile(
            title: const Text('智能推送训练提醒'),
            subtitle: const Text('基于训练日历智能调度，7 天内最多 2 次'),
            value: _pushEnabled,
            onChanged: _togglePush,
          ),
          const Divider(),
          _section('数据管理'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('导出全部数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('清除全部数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('不可恢复，请谨慎操作'),
            onTap: _showClearDataDialog,
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
      );

  Future<void> _exportData() async {
    // Defer to existing export logic in settings_page.dart
    // If not accessible, prompt user to use Settings → Export
    if (mounted) {
      FitToast.info(context, '请前往"设置 → 数据导出"完成导出');
    }
  }
}
