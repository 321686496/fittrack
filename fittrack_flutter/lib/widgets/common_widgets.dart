import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

// ── SectionHeader ──────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? moreText;
  final VoidCallback? onMore;

  const SectionHeader({
    super.key,
    required this.title,
    this.moreText,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (moreText != null)
          GestureDetector(
            onTap: onMore,
            child: Text(
              moreText!,
              style: TextStyle(
                color: colors.accentGlow,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

// ── StatCard ───────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
}

// ── BadgeWidget ────────────────────────────────────────────────

enum BadgeVariant { accent, success, info, purple }

class BadgeWidget extends StatelessWidget {
  final String text;
  final BadgeVariant variant;

  const BadgeWidget({
    super.key,
    required this.text,
    this.variant = BadgeVariant.accent,
  });

  Color _bgColor(FitTrackColors colors) {
    switch (variant) {
      case BadgeVariant.accent:
        return colors.accentGlow.withOpacity(0.15);
      case BadgeVariant.success:
        return colors.successColor.withOpacity(0.15);
      case BadgeVariant.info:
        return colors.infoColor.withOpacity(0.15);
      case BadgeVariant.purple:
        return colors.purpleColor.withOpacity(0.15);
    }
  }

  Color _textColor(FitTrackColors colors) {
    switch (variant) {
      case BadgeVariant.accent:
        return colors.accentGlow;
      case BadgeVariant.success:
        return colors.successColor;
      case BadgeVariant.info:
        return colors.infoColor;
      case BadgeVariant.purple:
        return colors.purpleColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor(colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _textColor(colors),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── ProgressBar ────────────────────────────────────────────────

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final Color? fillColor;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.fillColor,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: colors.borderColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor ?? colors.accentGlow,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ── CardWidget ─────────────────────────────────────────────────

class CardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: child,
      ),
    );
  }
}

// ── MenuButton ─────────────────────────────────────────────────

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? colors.accentGlow),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── IconBtn ────────────────────────────────────────────────────

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  const IconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: size,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

// ── EmptyState ─────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DividerWidget ──────────────────────────────────────────────

class DividerWidget extends StatelessWidget {
  final double indent;

  const DividerWidget({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Divider(
      height: 1,
      thickness: 1,
      color: colors.borderColor,
      indent: indent,
      endIndent: indent,
    );
  }
}

// ==============================================================
// 自定义 Toast 提示（Overlay 实现，不被弹窗遮挡）
// ==============================================================

enum ToastType { info, success, warning, error }

class FitToast {
  FitToast._();

  /// 显示 Toast 提示，使用 Overlay 浮层，不会被任何弹窗遮挡
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayEntry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () {},
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      overlayEntry.remove();
    });
  }

  /// 快捷方法
  static void info(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.info);

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.success);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.warning);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: ToastType.error);
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // 自动消失
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _icon() {
    switch (widget.type) {
      case ToastType.info:
        return Icons.info_outline_rounded;
      case ToastType.success:
        return Icons.check_circle_outline_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
    }
  }

  Color _accentColor(FitTrackColors colors) {
    switch (widget.type) {
      case ToastType.info:
        return colors.infoColor;
      case ToastType.success:
        return colors.successColor;
      case ToastType.warning:
        return colors.warningColor;
      case ToastType.error:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final padding = MediaQuery.of(context).padding;

    return Positioned(
      top: padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accentColor(colors).withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon(), color: _accentColor(colors), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// 自定义确认弹窗（替代 AlertDialog）
// ==============================================================

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText,
    this.cancelText,
    this.confirmColor,
    this.icon,
  });

  /// 显示确认弹窗，返回 true 表示确认
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final danger = confirmColor ?? colors.warningColor;

    return Dialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: danger.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: danger, size: 24),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      cancelText ?? '取消',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(confirmText ?? '确认'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// 自定义信息弹窗（替代信息展示类 AlertDialog）
// ==============================================================

class InfoDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? actionText;
  final IconData? icon;
  final Color? iconColor;

  const InfoDialog({
    super.key,
    required this.title,
    required this.content,
    this.actionText,
    this.icon,
    this.iconColor,
  });

  /// 显示信息弹窗
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    String? actionText,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (_) => InfoDialog(
        title: title,
        content: content,
        actionText: actionText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final accent = iconColor ?? colors.accentGlow;

    return Dialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(actionText ?? '知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// 自定义成就弹窗
// ==============================================================

class AchievementDialog extends StatelessWidget {
  final String icon;
  final String name;
  final String desc;
  final VoidCallback? onDone;

  const AchievementDialog({
    super.key,
    required this.icon,
    required this.name,
    required this.desc,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required String icon,
    required String name,
    required String desc,
    VoidCallback? onDone,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AchievementDialog(
        icon: icon,
        name: name,
        desc: desc,
        onDone: onDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Dialog(
      backgroundColor: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.accentGlow, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              '恭喜达成成就！',
              style: TextStyle(
                color: colors.accentGlow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDone?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentGlow,
                  foregroundColor: colors.bgCard,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('太棒了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================
// 自定义底部弹窗（统一样式 + 安全区域适配）
// ==============================================================

class FitBottomSheet {
  FitBottomSheet._();

  /// 显示自定义底部弹窗
  /// [child] 为弹窗内容，[maxHeightRatio] 为最大高度占屏幕高度比例
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    double maxHeightRatio = 0.75,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _BottomSheetWrapper(
          maxHeightRatio: maxHeightRatio,
          child: builder(ctx),
        );
      },
    );
  }
}

class _BottomSheetWrapper extends StatelessWidget {
  final Widget child;
  final double maxHeightRatio;

  const _BottomSheetWrapper({
    required this.child,
    this.maxHeightRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final mediaQuery = MediaQuery.of(context);
    // 键盘高度：当输入框获得焦点时，键盘会遮挡底部内容
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;

    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        // 键盘弹出时，底部留出键盘高度，确保内容不被遮挡
        padding: EdgeInsets.only(bottom: keyboardHeight),
        duration: const Duration(milliseconds: 200),
        child: Container(
          constraints: BoxConstraints(
            // 键盘弹出时，限制最大高度为屏幕剩余可用高度
            maxHeight: mediaQuery.size.height * maxHeightRatio,
          ),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 内容区域
              Flexible(child: child),
              // 底部安全区域（键盘未弹出时）
              if (keyboardHeight == 0 && bottomPadding > 0)
                SizedBox(height: bottomPadding),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// 自定义输入框组件（带标签和验证提示）
// ==============================================================

class FitTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const FitTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.obscureText = false,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: hasError ? Colors.redAccent : colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: textAlign,
          maxLength: maxLength,
          obscureText: obscureText,
          onSubmitted: onSubmitted,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
            filled: true,
            fillColor: colors.bgElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : colors.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent.withOpacity(0.5) : colors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : colors.accentGlow,
                width: 1.5,
              ),
            ),
            counterText: '',
            suffixIcon: suffix,
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ==============================================================
// 自定义选择器组件（Chip 风格）
// ==============================================================

class FitChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color? selectedColor;

  const FitChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final accent = selectedColor ?? colors.accentGlow;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == selected;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.15) : colors.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? accent : colors.borderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? accent : colors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
