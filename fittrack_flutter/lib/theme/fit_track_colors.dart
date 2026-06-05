import 'package:flutter/material.dart';

@immutable
class FitTrackColors extends ThemeExtension<FitTrackColors> {
  final Color bgSecondary;
  final Color bgCard;
  final Color bgElevated;
  final Color accentGlow;
  final Color accentSecondary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color purpleColor;

  const FitTrackColors({
    required this.bgSecondary,
    required this.bgCard,
    required this.bgElevated,
    required this.accentGlow,
    required this.accentSecondary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.purpleColor,
  });

  @override
  FitTrackColors copyWith({
    Color? bgSecondary,
    Color? bgCard,
    Color? bgElevated,
    Color? accentGlow,
    Color? accentSecondary,
    Color? textSecondary,
    Color? textMuted,
    Color? borderColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? purpleColor,
  }) {
    return FitTrackColors(
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgCard: bgCard ?? this.bgCard,
      bgElevated: bgElevated ?? this.bgElevated,
      accentGlow: accentGlow ?? this.accentGlow,
      accentSecondary: accentSecondary ?? this.accentSecondary,
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
  FitTrackColors lerp(FitTrackColors? other, double t) {
    if (other is! FitTrackColors) return this;
    return FitTrackColors(
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      purpleColor: Color.lerp(purpleColor, other.purpleColor, t)!,
    );
  }

  static const dark = FitTrackColors(
    bgSecondary: Color(0xFF1A1A2E),
    bgCard: Color(0xFF16213E),
    bgElevated: Color(0xFF0F3460),
    accentGlow: Color(0xFF00D2FF),
    accentSecondary: Color(0xFF7B68EE),
    textSecondary: Color(0xFFB0B0C0),
    textMuted: Color(0xFF6C6C80),
    borderColor: Color(0xFF2A2A40),
    successColor: Color(0xFF00E676),
    warningColor: Color(0xFFFFAB00),
    infoColor: Color(0xFF448AFF),
    purpleColor: Color(0xFFB388FF),
  );
}
