import 'dart:ui';
import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class PageHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final String? title;
  final String? subtitle;
  final VoidCallback? onBellTap;
  final VoidCallback? onCalendarTap;

  const PageHeader({
    super.key,
    this.onBack,
    this.title,
    this.subtitle,
    this.onBellTap,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgSecondary.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: colors.borderColor,
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (onBack != null)
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
                      if (onBack != null) const SizedBox(width: 12),
                      Expanded(
                        child: onBack != null
                            ? Text(
                                title ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                'FITPLAN',
                                style: TextStyle(
                                  color: colors.accentGlow,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                      ),
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
                      const SizedBox(width: 8),
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
          ),
        ),
      ),
    );
  }
}
