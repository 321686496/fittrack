import 'package:flutter/material.dart';

import '../l10n/i18n.dart';
/// 动作默认封面：按分类映射 emoji + 渐变色，使用 CustomPaint 绘制。
///
/// 入参 [category] 兼容简称（"胸"/"肩"/"背"/"腿"/"臂"/"核心"/"有氧"/"其他"）
/// 与全称（"胸部"/"背部"/"腿部"/"肩部"/"手臂"/"核心"/"跑步"）。
class DefaultExerciseCover extends StatelessWidget {
  final String category;
  final double? size;

  const DefaultExerciseCover({
    super.key,
    required this.category,
    this.size,
  });

  /// 解析分类对应的封面配置（emoji + 渐变两色）。
  static _CoverSpec _resolve(String category) {
    final c = category;
    if (c.contains(trn( '胸'))) {
      return _CoverSpec('💪', const Color(0xFFef4444), const Color(0xFFf97316));
    }
    if (c.contains(trn( '肩'))) {
      return _CoverSpec('🤸', const Color(0xFF3b82f6), const Color(0xFF06b6d4));
    }
    if (c.contains(trn( '背'))) {
      return _CoverSpec('🏹', const Color(0xFF8b5cf6), const Color(0xFF6366f1));
    }
    if (c.contains(trn( '腿'))) {
      return _CoverSpec('🦵', const Color(0xFF10b981), const Color(0xFF059669));
    }
    if (c.contains(trn( '臂'))) {
      return _CoverSpec('💪', const Color(0xFFf59e0b), const Color(0xFFef4444));
    }
    if (c.contains(trn( '核心'))) {
      return _CoverSpec('🎯', const Color(0xFFec4899), const Color(0xFFf43f5e));
    }
    if (c.contains(trn( '有氧')) || c.contains(trn( '跑步'))) {
      return _CoverSpec('🏃', const Color(0xFF06b6d4), const Color(0xFF3b82f6));
    }
    return _CoverSpec('🏋️', const Color(0xFF64748b), const Color(0xFF475569));
  }

  @override
  Widget build(BuildContext context) {
    final spec = _resolve(category);
    final s = size ?? 160.0;
    return SizedBox(
      width: double.infinity,
      height: s,
      child: CustomPaint(
        painter: _DefaultCoverPainter(spec: spec),
      ),
    );
  }
}

class _CoverSpec {
  final String emoji;
  final Color startColor;
  final Color endColor;

  _CoverSpec(this.emoji, this.startColor, this.endColor);
}

class _DefaultCoverPainter extends CustomPainter {
  final _CoverSpec spec;

  _DefaultCoverPainter({required this.spec});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 对角线渐变背景
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [spec.startColor, spec.endColor],
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 居中 emoji
    final emojiSize = size.height * 0.5;
    final tp = TextPainter(
      text: TextSpan(
        text: spec.emoji,
        style: TextStyle(
          fontSize: emojiSize,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    final emojiOffset = Offset(
      (size.width - tp.width) / 2,
      (size.height - tp.height) / 2,
    );
    tp.paint(canvas, emojiOffset);
  }

  @override
  bool shouldRepaint(covariant _DefaultCoverPainter oldDelegate) {
    return oldDelegate.spec.emoji != spec.emoji ||
        oldDelegate.spec.startColor != spec.startColor ||
        oldDelegate.spec.endColor != spec.endColor;
  }
}
