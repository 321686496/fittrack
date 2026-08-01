import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class PageHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBellTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onSearchTap;
  final bool isTabPage; // 首页tab页面，不显示返回按钮，但显示标题

  const PageHeader({
    super.key,
    this.onBack,
    this.title,
    this.subtitle,
    this.onBellTap,
    this.onCalendarTap,
    this.onStatsTap,
    this.onSearchTap,
    this.isTabPage = false,
  });

  // 缓存平台检查结果，避免每次 build 都执行 try-catch
  static final bool _supportsBackdropFilter = _detectBackdropFilterSupport();
  static bool _detectBackdropFilterSupport() {
    if (kIsWeb) return true;
    try {
      return !Platform.isFuchsia;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final showBack = onBack != null;
    final isLogo = !showBack && !isTabPage && title == null;

    Widget content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (showBack)
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                if (showBack) const SizedBox(width: 12),
                Expanded(
                  child: isLogo
                      ? Text(
                          'FITPLAN',
                          style: TextStyle(
                            color: colors.accentGlow,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        )
                      : Text(
                          title ?? '',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (onBellTap != null)
                  GestureDetector(
                    onTap: onBellTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                if (onBellTap != null) const SizedBox(width: 8),
                if (onCalendarTap != null)
                  GestureDetector(
                    onTap: onCalendarTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                if (onCalendarTap != null) const SizedBox(width: 8),
                if (onStatsTap != null)
                  GestureDetector(
                    onTap: onStatsTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                if (onStatsTap != null) const SizedBox(width: 8),
                if (onSearchTap != null)
                  GestureDetector(
                    onTap: onSearchTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.search,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: colors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: _supportsBackdropFilter
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: content,
              ),
            )
          : content,
    );
  }
}
