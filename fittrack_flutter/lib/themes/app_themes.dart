import 'package:flutter/material.dart';

/// Custom theme extension for LiftTrack extra colors
@immutable
class LiftTrackColors extends ThemeExtension<LiftTrackColors> {
  final Color bgSecondary;
  final Color bgCard;
  final Color bgElevated;
  final Color accentGlow;
  final Color accentSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color purpleColor;

  const LiftTrackColors({
    required this.bgSecondary,
    required this.bgCard,
    required this.bgElevated,
    required this.accentGlow,
    required this.accentSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.purpleColor,
  });

  @override
  LiftTrackColors copyWith({
    Color? bgSecondary,
    Color? bgCard,
    Color? bgElevated,
    Color? accentGlow,
    Color? accentSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? purpleColor,
  }) {
    return LiftTrackColors(
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      bgElevated: bgElevated ?? this.bgElevated,
      accentGlow: accentGlow ?? this.accentGlow,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      borderColor: borderColor ?? this.borderColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      purpleColor: purpleColor ?? this.purpleColor,
    );
  }

  @override
  LiftTrackColors lerp(LiftTrackColors? other, double t) {
    if (other is! LiftTrackColors) return this;
    return LiftTrackColors(
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      purpleColor: Color.lerp(purpleColor, other.purpleColor, t)!,
    );
  }
}

class AppTheme {
  static ThemeData getTheme(String themeId) {
    switch (themeId) {
      case 'vitality-sport':
        return _vitalitySportTheme;
      case 'iron-forge':
        return _ironForgeTheme;
      case 'blossom':
        return _blossomTheme;
      case 'silver-care':
        return _silverCareTheme;
      case 'fresh-minimal':
        return _freshMinimalTheme;
      case 'neon-cyber':
        return _neonCyberTheme;
      case 'black-gold':
        return _blackGoldTheme;
      default:
        return _vitalitySportTheme;
    }
  }

  static List<Map<String, dynamic>> get themes => [
        {
          'id': 'vitality-sport',
          'name': '活力运动',
          'desc': '动感活力，年轻有劲',
          'icon': '🔥',
          'colors': [0xFFFF6B35, 0xFFFFFFFF, 0xFF222222],
        },
        {
          'id': 'iron-forge',
          'name': '硬核铁馆',
          'desc': '粗犷原始，力量感十足',
          'icon': '🏋️',
          'colors': [0xFF0a0e14, 0xFFef4444, 0xFFf97316],
        },
        {
          'id': 'blossom',
          'name': '柔美花语',
          'desc': '柔和圆润，优雅精致',
          'icon': '🌸',
          'colors': [0xFFfdf2f8, 0xFFec4899, 0xFFf472b6],
        },
        {
          'id': 'silver-care',
          'name': '长者关怀',
          'desc': '大字高对比，清晰易读',
          'icon': '🛡️',
          'colors': [0xFFffffff, 0xFF059669, 0xFF10b981],
        },
        {
          'id': 'fresh-minimal',
          'name': '清新极简',
          'desc': '大量留白，极简克制',
          'icon': '🍃',
          'colors': [0xFFf8fafc, 0xFF0ea5e9, 0xFF38bdf8],
        },
        {
          'id': 'neon-cyber',
          'name': '赛博霓虹',
          'desc': '霓虹发光，数字未来感',
          'icon': '🎮',
          'colors': [0xFF0a0015, 0xFFd946ef, 0xFF22d3ee],
        },
        {
          'id': 'black-gold',
          'name': '黑金尊享',
          'desc': '奢华精致，沉稳尊贵',
          'icon': '👑',
          'colors': [0xFF0c0a09, 0xFFf59e0b, 0xFFfbbf24],
        },
      ];

  // ============================================================
  // Theme 0: Vitality Sport (活力运动)
  // Energetic & Dynamic — 动感、活力、年轻化
  // 活力橙主色 + 大圆角 + 渐变元素 + 运动轨迹线条
  // ============================================================
  static final ThemeData _vitalitySportTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFFFF8C5A),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFEF4444),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF222222),
      onError: Color(0xFFFFFFFF),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFFFFF4EE),
        bgCard: Color(0xFFFFFFFF),
        bgElevated: Color(0xFFFFF8F4),
        accentGlow: Color(0xFFFF6B35),
        accentSecondary: Color(0xFFFF8C5A),
        textPrimary: Color(0xFF222222),
        textSecondary: Color(0xFF555555),
        textMuted: Color(0xFF999999),
        borderColor: Color(0x1AFF6B35),
        successColor: Color(0xFF22C55E),
        warningColor: Color(0xFFF59E0B),
        infoColor: Color(0xFF3B82F6),
        purpleColor: Color(0xFFA855F7),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shadowColor: const Color(0x14FF6B35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x1AFF6B35), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAFAFA),
      foregroundColor: Color(0xFF222222),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF222222),
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: Color(0xFF222222),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF222222),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
      bodyLarge: TextStyle(color: Color(0xFF222222)),
      bodyMedium: TextStyle(color: Color(0xFF555555)),
      bodySmall: TextStyle(color: Color(0xFF999999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFFFF4EE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1AFF6B35), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1AFF6B35), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x66FF6B35), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1AFF6B35),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFFFF6B35),
      unselectedItemColor: Color(0xFF999999),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFFF6B35),
      foregroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFFFF4EE),
      selectedColor: const Color(0xFFFF6B35),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Color(0x1AFF6B35), width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFFF6B35),
      linearTrackColor: Color(0xFFFFF4EE),
    ),
  );

  // ============================================================
  // Theme 1: Iron Forge (硬核铁馆)
  // Brutalist — 粗犷、原始、力量感
  // 零圆角 + 粗边框 + 偏移硬阴影 + 大写粗体
  // ============================================================
  static final ThemeData _ironForgeTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0a0e14),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFef4444),
      secondary: Color(0xFFf97316),
      surface: Color(0xFF141c28),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFF000000),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFf1f5f9),
      onError: Color(0xFF000000),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFF0f1520),
        bgCard: Color(0xFF141c28),
        bgElevated: Color(0xFF1a2436),
        accentGlow: Color(0x40ef4444),
        accentSecondary: Color(0xFFf97316),
        textPrimary: Color(0xFFf1f5f9),
        textSecondary: Color(0xFF94a3b8),
        textMuted: Color(0xFF475569),
        borderColor: Color(0x14FFFFFF),
        successColor: Color(0xFF22c55e),
        warningColor: Color(0xFFf59e0b),
        infoColor: Color(0xFF3b82f6),
        purpleColor: Color(0xFFa855f7),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFF141c28),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Color(0x14FFFFFF), width: 3),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0a0e14),
      foregroundColor: Color(0xFFf1f5f9),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFf1f5f9),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFef4444),
        foregroundColor: const Color(0xFF000000),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Color(0xFFef4444), width: 3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
        color: Color(0xFFf1f5f9),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFFf1f5f9),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF94a3b8),
      ),
      bodyLarge: TextStyle(color: Color(0xFFf1f5f9)),
      bodyMedium: TextStyle(color: Color(0xFF94a3b8)),
      bodySmall: TextStyle(color: Color(0xFF475569)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0f1520),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0x14FFFFFF), width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: Color(0x80ef4444), width: 3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x14FFFFFF),
      thickness: 3,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0a0e14),
      selectedItemColor: Color(0xFFef4444),
      unselectedItemColor: Color(0xFF475569),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFef4444),
      foregroundColor: const Color(0xFF000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Color(0xFFef4444), width: 3),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF141c28),
      selectedColor: const Color(0xFFef4444),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: Color(0x14FFFFFF), width: 3),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFef4444),
      linearTrackColor: Color(0xFF1a2436),
    ),
  );

  // ============================================================
  // Theme 2: Blossom (柔美花语)
  // Soft & Flowing — 柔和、圆润、优雅
  // 大圆角 + 细边框 + 柔和阴影 + 衬线标题
  // ============================================================
  static final ThemeData _blossomTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFfdf2f8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFec4899),
      secondary: Color(0xFFf472b6),
      surface: Color(0xFFffffff),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFFffffff),
      onSecondary: Color(0xFFffffff),
      onSurface: Color(0xFF1e1b2e),
      onError: Color(0xFFffffff),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFFfce7f3),
        bgCard: Color(0xFFffffff),
        bgElevated: Color(0xFFfdf2f8),
        accentGlow: Color(0x2Eec4899),
        accentSecondary: Color(0xFFf472b6),
        textPrimary: Color(0xFF1e1b2e),
        textSecondary: Color(0xFF6b5f7b),
        textMuted: Color(0xFFa89bb8),
        borderColor: Color(0x1Aec4899),
        successColor: Color(0xFF10b981),
        warningColor: Color(0xFFf59e0b),
        infoColor: Color(0xFF8b5cf6),
        purpleColor: Color(0xFFa855f7),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFFffffff),
      elevation: 0,
      shadowColor: const Color(0x14ec4899),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x1Aec4899), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFfdf2f8),
      foregroundColor: Color(0xFF1e1b2e),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF1e1b2e),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFec4899),
        foregroundColor: const Color(0xFFffffff),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Color(0xFF1e1b2e),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF1e1b2e),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF6b5f7b),
      ),
      bodyLarge: TextStyle(color: Color(0xFF1e1b2e)),
      bodyMedium: TextStyle(color: Color(0xFF6b5f7b)),
      bodySmall: TextStyle(color: Color(0xFFa89bb8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFfce7f3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1Aec4899), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1Aec4899), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x66ec4899), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1Aec4899),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFffffff),
      selectedItemColor: Color(0xFFec4899),
      unselectedItemColor: Color(0xFFa89bb8),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFec4899),
      foregroundColor: const Color(0xFFffffff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFfce7f3),
      selectedColor: const Color(0xFFec4899),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
        side: const BorderSide(color: Color(0x1Aec4899), width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFec4899),
      linearTrackColor: Color(0xFFfce7f3),
    ),
  );

  // ============================================================
  // Theme 3: Silver Care (长者关怀)
  // Accessible & Clear — 大字、高对比、简单清晰
  // 超大字体 + 高对比度 + 宽松间距 + 粗边框
  // ============================================================
  static final ThemeData _silverCareTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFffffff),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF059669),
      secondary: Color(0xFF10b981),
      surface: Color(0xFFffffff),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFFffffff),
      onSecondary: Color(0xFFffffff),
      onSurface: Color(0xFF111827),
      onError: Color(0xFFffffff),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFFf0fdf4),
        bgCard: Color(0xFFffffff),
        bgElevated: Color(0xFFf0fdf4),
        accentGlow: Color(0x26059669),
        accentSecondary: Color(0xFF10b981),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF374151),
        textMuted: Color(0xFF6b7280),
        borderColor: Color(0x26059669),
        successColor: Color(0xFF059669),
        warningColor: Color(0xFFd97706),
        infoColor: Color(0xFF2563eb),
        purpleColor: Color(0xFF7c3aed),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFFffffff),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0x26059669), width: 2),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFffffff),
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF111827),
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: const Color(0xFFffffff),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 34,
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 30,
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 26,
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 24,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 22,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 20,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: Color(0xFF111827),
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
        fontSize: 18,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        fontSize: 16,
      ),
      bodyLarge: TextStyle(
        color: Color(0xFF111827),
        fontSize: 18,
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF374151),
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        color: Color(0xFF6b7280),
        fontSize: 14,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFf0fdf4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x26059669), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x26059669), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x26059669),
      thickness: 2,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFffffff),
      selectedItemColor: Color(0xFF059669),
      unselectedItemColor: Color(0xFF6b7280),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 14),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF059669),
      foregroundColor: const Color(0xFFffffff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFf0fdf4),
      selectedColor: const Color(0xFF059669),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0x26059669), width: 2),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF059669),
      linearTrackColor: Color(0xFFf0fdf4),
    ),
  );

  // ============================================================
  // Theme 4: Fresh Minimal (清新极简)
  // Minimal & Clean — 大量留白、极细线条、克制用色
  // 细边框 + 微阴影 + 大留白 + 无装饰
  // ============================================================
  static final ThemeData _freshMinimalTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFf8fafc),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0ea5e9),
      secondary: Color(0xFF38bdf8),
      surface: Color(0xFFffffff),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFFffffff),
      onSecondary: Color(0xFFffffff),
      onSurface: Color(0xFF0f172a),
      onError: Color(0xFFffffff),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFFf1f5f9),
        bgCard: Color(0xFFffffff),
        bgElevated: Color(0xFFf8fafc),
        accentGlow: Color(0x1F0ea5e9),
        accentSecondary: Color(0xFF38bdf8),
        textPrimary: Color(0xFF0f172a),
        textSecondary: Color(0xFF475569),
        textMuted: Color(0xFF94a3b8),
        borderColor: Color(0x0F0f172a),
        successColor: Color(0xFF10b981),
        warningColor: Color(0xFFf59e0b),
        infoColor: Color(0xFF6366f1),
        purpleColor: Color(0xFF8b5cf6),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFFffffff),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x0F0f172a), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFf8fafc),
      foregroundColor: Color(0xFF0f172a),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF0f172a),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0ea5e9),
        foregroundColor: const Color(0xFFffffff),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF0f172a),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF0f172a),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
      bodyLarge: TextStyle(color: Color(0xFF0f172a)),
      bodyMedium: TextStyle(color: Color(0xFF475569)),
      bodySmall: TextStyle(color: Color(0xFF94a3b8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFf1f5f9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x0F0f172a), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x0F0f172a), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x590ea5e9), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x0F0f172a),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFffffff),
      selectedItemColor: Color(0xFF0ea5e9),
      unselectedItemColor: Color(0xFF94a3b8),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFF0ea5e9),
      foregroundColor: const Color(0xFFffffff),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFf1f5f9),
      selectedColor: const Color(0xFF0ea5e9),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0x0F0f172a), width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF0ea5e9),
      linearTrackColor: Color(0xFFf1f5f9),
    ),
  );

  // ============================================================
  // Theme 5: Neon Cyber (赛博霓虹)
  // Cyberpunk — 霓虹发光、锐利几何、数字未来感
  // 发光边框 + 霓虹色 + 极小圆角
  // ============================================================
  static final ThemeData _neonCyberTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0a0015),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFd946ef),
      secondary: Color(0xFF22d3ee),
      surface: Color(0xFF15002e),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFF0a0015),
      onSecondary: Color(0xFF0a0015),
      onSurface: Color(0xFFf5f3ff),
      onError: Color(0xFF000000),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFF0f0022),
        bgCard: Color(0xFF15002e),
        bgElevated: Color(0xFF1f0044),
        accentGlow: Color(0x59d946ef),
        accentSecondary: Color(0xFFe879f9),
        textPrimary: Color(0xFFf5f3ff),
        textSecondary: Color(0xFFa78bfa),
        textMuted: Color(0xFF6b5e9e),
        borderColor: Color(0x26d946ef),
        successColor: Color(0xFF34d399),
        warningColor: Color(0xFFfbbf24),
        infoColor: Color(0xFF22d3ee),
        purpleColor: Color(0xFFc084fc),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFF15002e),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0x26d946ef), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0a0015),
      foregroundColor: Color(0xFFf5f3ff),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFf5f3ff),
        fontSize: 18,
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFd946ef),
        foregroundColor: const Color(0xFF0a0015),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Color(0xFFd946ef), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          letterSpacing: 3,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: Color(0xFFf5f3ff),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w400,
        color: Color(0xFFf5f3ff),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w400,
        color: Color(0xFFa78bfa),
      ),
      bodyLarge: TextStyle(color: Color(0xFFf5f3ff)),
      bodyMedium: TextStyle(color: Color(0xFFa78bfa)),
      bodySmall: TextStyle(color: Color(0xFF6b5e9e)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0f0022),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0x26d946ef), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0x26d946ef), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0x99d946ef), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x26d946ef),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0a0015),
      selectedItemColor: Color(0xFFd946ef),
      unselectedItemColor: Color(0xFF6b5e9e),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFd946ef),
      foregroundColor: const Color(0xFF0a0015),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF15002e),
      selectedColor: const Color(0xFFd946ef),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
        side: const BorderSide(color: Color(0x26d946ef), width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFd946ef),
      linearTrackColor: Color(0xFF1f0044),
    ),
  );

  // ============================================================
  // Theme 6: Black Gold (黑金尊享)
  // Luxury — 奢华、精致、沉稳、尊贵
  // 金色渐变 + 衬线字体 + 精致阴影 + 高级质感
  // ============================================================
  static final ThemeData _blackGoldTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0c0a09),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFf59e0b),
      secondary: Color(0xFFfbbf24),
      surface: Color(0xFF1a1612),
      error: Color(0xFFef4444),
      onPrimary: Color(0xFF0c0a09),
      onSecondary: Color(0xFF0c0a09),
      onSurface: Color(0xFFfef3c7),
      onError: Color(0xFF000000),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      LiftTrackColors(
        bgSecondary: Color(0xFF12100e),
        bgCard: Color(0xFF1a1612),
        bgElevated: Color(0xFF241e18),
        accentGlow: Color(0x33f59e0b),
        accentSecondary: Color(0xFFfbbf24),
        textPrimary: Color(0xFFfef3c7),
        textSecondary: Color(0xFFa89f84),
        textMuted: Color(0xFF6b5a4e),
        borderColor: Color(0x1Af59e0b),
        successColor: Color(0xFF10b981),
        warningColor: Color(0xFFf59e0b),
        infoColor: Color(0xFF93c5fd),
        purpleColor: Color(0xFFc084fc),
      ),
    ],
    cardTheme: CardTheme(
      color: const Color(0xFF1a1612),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x1Af59e0b), width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0c0a09),
      foregroundColor: Color(0xFFfef3c7),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFFfef3c7),
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFf59e0b),
        foregroundColor: const Color(0xFF0c0a09),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFf59e0b), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      displayMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      displaySmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
        color: Color(0xFFfef3c7),
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFFfef3c7),
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFFa89f84),
      ),
      bodyLarge: TextStyle(color: Color(0xFFfef3c7)),
      bodyMedium: TextStyle(color: Color(0xFFa89f84)),
      bodySmall: TextStyle(color: Color(0xFF6b5a4e)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF12100e),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x1Af59e0b), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x1Af59e0b), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0x73f59e0b), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x1Af59e0b),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0c0a09),
      selectedItemColor: Color(0xFFf59e0b),
      unselectedItemColor: Color(0xFF6b5a4e),
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: const Color(0xFFf59e0b),
      foregroundColor: const Color(0xFF0c0a09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1a1612),
      selectedColor: const Color(0xFFf59e0b),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0x1Af59e0b), width: 1),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFFf59e0b),
      linearTrackColor: Color(0xFF241e18),
    ),
  );
}

/// 便捷主题访问类
class LiftTrackTheme {
  /// ???? ID ??
  static const List<String> lightThemeIds = [
    'vitality-sport',
    'blossom',
    'silver-care',
    'fresh-minimal',
  ];

  /// ???? ID ??
  static const List<String> darkThemeIds = [
    'iron-forge',
    'neon-cyber',
    'black-gold',
  ];

  /// ???????????
  static bool isDarkTheme(String themeId) => darkThemeIds.contains(themeId);

  /// ???????????
  static bool isLightTheme(String themeId) => lightThemeIds.contains(themeId);

  // ??? API ??
  static ThemeData get dark => AppTheme.getTheme('iron-forge');
  static ThemeData get light => AppTheme.getTheme('vitality-sport');

  /// 判断 [time]（或当前时刻）是否处于"定点夜间（深色）窗口"内。
  /// [timedDarkTime] 格式 "HH:mm"，窗口以它起点持续 12 小时。
  /// [testNow] 用于测试注入；生产环境传 null 使用 DateTime.now()。
  /// 时间解析失败时回退到 18:00。
  static bool isTimedDarkNow(String timedDarkTime, {DateTime? testNow}) {
    final parts = timedDarkTime.split(':');
    int startHour = 18, startMinute = 0;
    if (parts.length == 2) {
      startHour = int.tryParse(parts[0]) ?? 18;
      startMinute = int.tryParse(parts[1]) ?? 0;
    }

    final now = testNow ?? DateTime.now();
    final startMinutes = (startHour * 60 + startMinute) % 1440;
    final nowMinutes = now.hour * 60 + now.minute;
    final endMinutes = (startMinutes + 720) % 1440; // 窗口持续 12 小时

    if (startMinutes <= endMinutes) {
      // 不跨零点
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // 跨零点
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }
}
