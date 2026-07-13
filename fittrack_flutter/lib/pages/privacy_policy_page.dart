import 'package:flutter/material.dart';
import '../data/legal/legal_content.dart';

/// 隐私政策页面（完整法律文本，从"设置"入口进入）
///
/// 与 onboarding 流程使用的 [_PrivacyPolicyPage]（私有，带同意/拒绝按钮）不同，
/// 本页面仅用于展示完整隐私政策文本，路由为 /privacy-full。
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late List<Widget> _sections;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _buildSections();
  }

  /// 将 markdown 内容解析为多个 Text widget，使每个标题/段落可被 find.text 精确匹配。
  void _buildSections() {
    final lines = privacyPolicyContent.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        // H1 标题：去掉 "# " 前缀
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line.substring(2),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (line.startsWith('## ')) {
        // H2 章节标题：去掉 "## " 前缀
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(3),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        // 空行：作为段落间距
        widgets.add(const SizedBox(height: 8));
      } else {
        // 普通段落：去除 ** 包裹的加粗标记
        final cleaned = line.replaceAll('**', '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              cleaned,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
        );
      }
    }

    _sections = widgets;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隐私政策')),
      body: _loaded
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _sections,
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
