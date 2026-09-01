import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../router.dart';
import '../themes/app_themes.dart';
import 'common_widgets.dart';

/// 首次训练体验反馈弹窗。
///
/// 在用户完成第一次训练、返回首页后弹出，询问训练使用感受；
/// 告知用户如果有觉得不好用或存在漏洞的地方，可点击按钮提交反馈，
/// 我们会积极听取用户意见把产品做得更好。
class FirstTrainingFeedbackSheet {
  FirstTrainingFeedbackSheet._();

  static const String _flagKey = 'firstFeedbackShown';

  /// 是否应显示：尚未展示过且至少完成了一次训练。
  static bool shouldShow() {
    final settings = Storage.getSettings();
    if (settings[_flagKey] == true) return false;
    final totalTrainings = (Storage.getStats()['totalTrainings'] as int?) ?? 0;
    return totalTrainings >= 1;
  }

  /// 在首页展示弹窗。
  static Future<void> maybeShow({BuildContext? context}) async {
    if (!shouldShow()) return;
    // 标记为已展示，避免每次回到首页都重复弹出
    final settings = Storage.getSettings();
    settings[_flagKey] = true;
    Storage.saveSettings(settings);

    final ctx = context ?? rootNavigatorKey.currentContext;
    if (ctx == null) return;
    if (!ctx.mounted) return;

    // 用 push 而非 go：/contact 是 Shell 的兄弟路由，go 会把首页从栈中移除，
    // 导致返回时出现白屏。push 会将联系页压入栈顶，返回时回到首页。
    final wantsFeedback = await FitBottomSheet.show<bool>(
      context: ctx,
      builder: (sheetCtx) => _FirstTrainingFeedbackSheet(
        onFeedback: () => Navigator.pop(sheetCtx, true),
      ),
    );
    if (wantsFeedback == true && ctx.mounted) {
      ctx.push('/contact');
    }
  }
}

class _FirstTrainingFeedbackSheet extends StatelessWidget {
  final VoidCallback onFeedback;

  const _FirstTrainingFeedbackSheet({required this.onFeedback});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center, color: colors.accentGlow, size: 56),
          const SizedBox(height: 16),
          Text(
            '第一次训练完成，感觉怎么样？',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '感谢你选择我们开始训练！如果过程中有哪里觉得不好用、操作不顺手，或者发现了漏洞，欢迎告诉我们。',
            style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '我们会积极听取你宝贵的意见，把产品做得更好。',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onFeedback,
              icon: const Icon(Icons.forum_outlined),
              label: const Text('我要反馈'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '目前用得不错',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}