import 'package:flutter/material.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';

import '../l10n/i18n.dart';
class OnboardingCoach extends StatefulWidget {
  /// 选择部位并确认时回调，参数为所选部位
  final ValueChanged<String> onComplete;
  final VoidCallback onSkip;
  OnboardingCoach({
    required this.onComplete,
    required this.onSkip,
    super.key,
  });
  @override
  State<OnboardingCoach> createState() => _OnboardingCoachState();
}

class _OnboardingCoachState extends State<OnboardingCoach> {
  String? _selectedPart;

  /// 身体部位选项：**与语言无关的数据键**（会通过 onComplete 写入用户设置），
  /// 因此保持中文字面量，展示处再用 `tr(context, ...)` 翻译。
  static const List<String> _parts = ['胸', '背', '腿', '肩', '手臂', '核心'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<LiftTrackColors>();
    // 使用主题可读文本色，避免浅色背景下出现白色文字看不清
    final textPrimary = colors?.textPrimary ?? theme.colorScheme.onSurface;
    final textSecondary = colors?.textSecondary ?? theme.colorScheme.onSurfaceVariant;
    final cardColor = colors?.bgCard ?? theme.colorScheme.surface;

    return Center(
      child: Material(
        color: cardColor,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: BoxConstraints(maxWidth: 420),
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, '今天练什么部位？'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
              ),
              SizedBox(height: 8),
              Text(
                tr(context, '选择想练的部位，为你自动搜索合适的训练计划'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: _parts.map((p) {
                  final selected = _selectedPart == p;
                  return ChoiceChip(
                    label: Text(tr(context, p)),
                    selected: selected,
                    // 显式指定两种状态颜色，避免浅色背景下文字看不清
                    backgroundColor:
                        colors?.bgCard ?? theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: selected ? theme.colorScheme.onPrimary : textPrimary,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: selected
                          ? theme.colorScheme.primary
                          : (colors?.borderColor ?? Colors.black12),
                    ),
                    onSelected: (_) => setState(() => _selectedPart = p),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(tr(context, '跳过'), style: TextStyle(color: textSecondary)),
                  ),
                  SizedBox(width: 12),
                  // 英文 'Search Training Plans' 比中文长，用 Flexible 让按钮
                  // 按需收缩换行，避免窄屏溢出
                  Flexible(
                    child: FilledButton(
                      onPressed: _selectedPart == null ? null : _confirm,
                      child: Text(tr(context, '搜索训练计划'),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirm() {
    final part = _selectedPart;
    if (part == null) return;
    final settings = Storage.getSettings();
    settings['onboardingV2Done'] = true;
    Storage.saveSettings(settings);
    widget.onComplete(part);
  }
}