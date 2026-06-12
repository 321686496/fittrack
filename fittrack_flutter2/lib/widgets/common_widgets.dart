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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
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
