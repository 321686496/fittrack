import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/storage.dart';

/// 海报配色（跟随用户当前 App 主题）
///
/// 通过 [PosterColors.fromThemeId] 工厂根据 themeId 解析对应主题色，
/// 保证分享海报与应用内主题视觉一致。每个主题包含：
/// 背景渐变 + 品牌主色/副色 + 三档文字色 + 卡片底色/边框色。
class PosterColors {
  final Color bgTop;
  final Color bgBottom;
  final Color brand;
  final Color brandSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color success;
  final Color warning;
  final bool isDark;

  const PosterColors({
    required this.bgTop,
    required this.bgBottom,
    required this.brand,
    required this.brandSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.success,
    required this.warning,
    required this.isDark,
  });

  /// 根据主题 ID 解析海报配色。
  /// - themeId 为 null：从全局 Settings 读取当前用户主题
  /// - 未知 themeId：回退到活力运动
  factory PosterColors.fromThemeId(String? themeId) {
    // null 表示由调用方读取当前用户设置
    if (themeId == null) {
      final settingsTheme = Storage.getSettings()['theme'] as String?;
      return PosterColors.fromThemeId(settingsTheme ?? 'vitality-sport');
    }
    switch (themeId) {
      case 'vitality-sport':
        return const PosterColors(
          bgTop: Color(0xFFFFF8F4),
          bgBottom: Color(0xFFFFF1E8),
          brand: Color(0xFFFF6B35),
          brandSecondary: Color(0xFFFF8C5A),
          textPrimary: Color(0xFF222222),
          textSecondary: Color(0xFF555555),
          textMuted: Color(0xFF999999),
          cardBg: Color(0x0FFF6B35),
          cardBorder: Color(0x1AFF6B35),
          success: Color(0xFF22C55E),
          warning: Color(0xFFF59E0B),
          isDark: false,
        );
      case 'iron-forge':
        return const PosterColors(
          bgTop: Color(0xFF0a0e14),
          bgBottom: Color(0xFF141c28),
          brand: Color(0xFFef4444),
          brandSecondary: Color(0xFFf97316),
          textPrimary: Color(0xFFf1f5f9),
          textSecondary: Color(0xFF94a3b8),
          textMuted: Color(0xFF475569),
          cardBg: Color(0x14FFFFFF),
          cardBorder: Color(0x1FFFFFFF),
          success: Color(0xFF22c55e),
          warning: Color(0xFFf59e0b),
          isDark: true,
        );
      case 'blossom':
        return const PosterColors(
          bgTop: Color(0xFFfdf2f8),
          bgBottom: Color(0xFFfce7f3),
          brand: Color(0xFFec4899),
          brandSecondary: Color(0xFFf472b6),
          textPrimary: Color(0xFF1e1b2e),
          textSecondary: Color(0xFF6b5f7b),
          textMuted: Color(0xFFa89bb8),
          cardBg: Color(0x14ec4899),
          cardBorder: Color(0x1Aec4899),
          success: Color(0xFF10b981),
          warning: Color(0xFFf59e0b),
          isDark: false,
        );
      case 'silver-care':
        return const PosterColors(
          bgTop: Color(0xFFffffff),
          bgBottom: Color(0xFFf0fdf4),
          brand: Color(0xFF059669),
          brandSecondary: Color(0xFF10b981),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF374151),
          textMuted: Color(0xFF6b7280),
          cardBg: Color(0x14059669),
          cardBorder: Color(0x26059669),
          success: Color(0xFF059669),
          warning: Color(0xFFd97706),
          isDark: false,
        );
      case 'fresh-minimal':
        return const PosterColors(
          bgTop: Color(0xFFf8fafc),
          bgBottom: Color(0xFFf1f5f9),
          brand: Color(0xFF0ea5e9),
          brandSecondary: Color(0xFF38bdf8),
          textPrimary: Color(0xFF0f172a),
          textSecondary: Color(0xFF475569),
          textMuted: Color(0xFF94a3b8),
          cardBg: Color(0x0F0f172a),
          cardBorder: Color(0x140f172a),
          success: Color(0xFF10b981),
          warning: Color(0xFFf59e0b),
          isDark: false,
        );
      case 'neon-cyber':
        return const PosterColors(
          bgTop: Color(0xFF0a0015),
          bgBottom: Color(0xFF15002e),
          brand: Color(0xFFd946ef),
          brandSecondary: Color(0xFF22d3ee),
          textPrimary: Color(0xFFf5f3ff),
          textSecondary: Color(0xFFa78bfa),
          textMuted: Color(0xFF6b5e9e),
          cardBg: Color(0x1Ad946ef),
          cardBorder: Color(0x26d946ef),
          success: Color(0xFF34d399),
          warning: Color(0xFFfbbf24),
          isDark: true,
        );
      case 'black-gold':
        return const PosterColors(
          bgTop: Color(0xFF0c0a09),
          bgBottom: Color(0xFF1a1612),
          brand: Color(0xFFf59e0b),
          brandSecondary: Color(0xFFfbbf24),
          textPrimary: Color(0xFFfef3c7),
          textSecondary: Color(0xFFa89f84),
          textMuted: Color(0xFF6b5a4e),
          cardBg: Color(0x1Af59e0b),
          cardBorder: Color(0x26f59e0b),
          success: Color(0xFF10b981),
          warning: Color(0xFFf59e0b),
          isDark: true,
        );
      default:
        return PosterColors.fromThemeId('vitality-sport');
    }
  }

  /// 从全局 Settings 读取当前主题并返回对应海报配色
  factory PosterColors.fromCurrentSettings() {
    final themeId = Storage.getSettings()['theme'] as String?;
    return PosterColors.fromThemeId(themeId);
  }
}

/// 海报统一渐变背景 + 装饰光晕
///
/// 用法：
/// ```
/// PosterBackground(
///   colors: PosterColors.fromThemeId(themeId),
///   child: ...,
/// )
/// ```
class PosterBackground extends StatelessWidget {
  final Widget child;
  final PosterColors colors;

  const PosterBackground({
    super.key,
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // 说明：必须用 StackFit.passthrough + Positioned.fill 渐变背景。
    // 若用 StackFit.expand，当父级只给宽度（高度无界，如海报截图 Positioned(height: null)）
    // 时 Stack 会被撑成无限高 → assert(size.isFinite) 失败 → 布局中断 → RepaintBoundary
    // 永不完成 paint → 海报截图报「RepaintBoundary 尚未完成绘制」。passthrough 在
    // 紧凑约束（固定海报高度）下与 expand 行为一致，在宽松约束下高度随内容自适应。
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // 渐变背景（填充整个 Stack，高度自适应）
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.bgTop, colors.bgBottom],
              ),
            ),
          ),
        ),
        // 右上角品牌色光晕
        Positioned(
          top: -250,
          right: -200,
          child: Container(
            width: 700,
            height: 700,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.brand.withOpacity(colors.isDark ? 0.18 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // 左下角副色光晕
        Positioned(
          bottom: -200,
          left: -200,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.brandSecondary.withOpacity(colors.isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// 海报统一品牌头部（logo + 品牌名 + 装饰线）
class PosterBrandHeader extends StatelessWidget {
  final String? subtitle;
  final PosterColors colors;

  const PosterBrandHeader({
    super.key,
    this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.brand, colors.brandSecondary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.fitness_center,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'LiftTrack',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 装饰线
        Container(
          width: 80,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.brand, colors.brandSecondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 22,
            ),
          ),
        ],
      ],
    );
  }
}

/// 海报统一底部二维码区
class PosterQrFooter extends StatelessWidget {
  final String qrData;
  final String? hint;
  final PosterColors colors;

  const PosterQrFooter({
    super.key,
    required this.qrData,
    this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 二维码
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.brand.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            gapless: true,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: colors.brand,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hint ?? '扫码了解更多',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'LiftTrack · 训练',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
