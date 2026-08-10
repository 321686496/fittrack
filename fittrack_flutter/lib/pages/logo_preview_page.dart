import 'package:flutter/material.dart';

/// Logo 设计预览页 — 用代码精确绘制多个 Logo 方案
class LogoPreviewPage extends StatelessWidget {
  const LogoPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('LiftTrack Logo 预览', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('方案 1: L + 杠铃片（字母 L 图形化）'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '1A · 竖 L + 底部杠铃片',
                  child: const _LogoLBarbell(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '1B · 圆角方框版',
                  child: const _LogoLBarbellRounded(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionTitle('方案 2: 哑铃（纯图形）'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '2A · 几何哑铃',
                  child: const _LogoDumbbell(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '2B · 圆角方框版',
                  child: const _LogoDumbbellRounded(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionTitle('方案 3: 向上箭头/山峰（举起象征）'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '3A · 实心箭头',
                  child: const _LogoArrow(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '3B · 空心箭头',
                  child: const _LogoArrowOutline(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionTitle('方案 4: LT 字母徽章'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '4A · LT 嵌套',
                  child: const _LogoLTBadge(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '4B · 圆形徽章',
                  child: const _LogoLTCircle(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionTitle('方案 5: 杠铃片截面（圆环）'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '5A · 不完整圆环',
                  child: const _LogoRing(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '5B · 双环追踪',
                  child: const _LogoDoubleRing(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const _SectionTitle('方案 6: L + 哑铃组合'),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCard(
                  label: '6A · L 横杠=哑铃杆',
                  child: const _LogoLDumbbell(),
                ),
                const SizedBox(width: 16),
                _LogoCard(
                  label: '6B · 圆角方框版',
                  child: const _LogoLDumbbellRounded(),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFFF6B35),
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _LogoCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF333333), width: 1),
            ),
            child: Center(child: child),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── 方案 1: L + 杠铃片 ─────────────────────────────────────────
class _LogoLBarbell extends StatelessWidget {
  const _LogoLBarbell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _LBarbellPainter(),
    );
  }
}

class _LBarbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    // L 竖线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 10, 16, 60),
        const Radius.circular(3),
      ),
      paint,
    );
    // L 横线（底部）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, 58, 50, 16),
        const Radius.circular(3),
      ),
      paint,
    );
    // 杠铃片（底部横线下方，3 个堆叠）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(34, 76, 10, 16),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(48, 76, 10, 16),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(62, 76, 10, 16),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoLBarbellRounded extends StatelessWidget {
  const _LogoLBarbellRounded();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: CustomPaint(
        size: const Size(100, 100),
        painter: _LBarbellWhitePainter(),
      ),
    );
  }
}

class _LBarbellWhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // L 竖线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28, 12, 14, 52),
        const Radius.circular(2),
      ),
      paint,
    );
    // L 横线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28, 54, 44, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    // 杠铃片
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(32, 70, 8, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(44, 70, 8, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(56, 70, 8, 14),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 方案 2: 哑铃 ────────────────────────────────────────────────
class _LogoDumbbell extends StatelessWidget {
  const _LogoDumbbell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _DumbbellPainter(),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    // 杠铃杆
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 44, 60, 12),
        const Radius.circular(3),
      ),
      paint,
    );
    // 左侧配重（外）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 32, 14, 36),
        const Radius.circular(4),
      ),
      paint,
    );
    // 左侧配重（内）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(18, 36, 8, 28),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右侧配重（外）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(78, 32, 14, 36),
        const Radius.circular(4),
      ),
      paint,
    );
    // 右侧配重（内）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(74, 36, 8, 28),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoDumbbellRounded extends StatelessWidget {
  const _LogoDumbbellRounded();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: CustomPaint(
        size: const Size(100, 100),
        painter: _DumbbellWhitePainter(),
      ),
    );
  }
}

class _DumbbellWhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 杠铃杆
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(22, 44, 56, 12),
        const Radius.circular(3),
      ),
      paint,
    );
    // 左外
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 34, 14, 32),
        const Radius.circular(4),
      ),
      paint,
    );
    // 左内
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 38, 8, 24),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右外
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(76, 34, 14, 32),
        const Radius.circular(4),
      ),
      paint,
    );
    // 右内
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(72, 38, 8, 24),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 方案 3: 向上箭头 ────────────────────────────────────────────
class _LogoArrow extends StatelessWidget {
  const _LogoArrow();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _ArrowPainter(),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final path = Path();
    // 外三角
    path.moveTo(50, 8);
    path.lineTo(90, 80);
    path.lineTo(70, 80);
    path.lineTo(70, 50);
    path.lineTo(30, 50);
    path.lineTo(30, 80);
    path.lineTo(10, 80);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoArrowOutline extends StatelessWidget {
  const _LogoArrowOutline();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _ArrowOutlinePainter(),
    );
  }
}

class _ArrowOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final path = Path();
    // 外三角
    path.moveTo(50, 8);
    path.lineTo(92, 82);
    path.lineTo(72, 82);
    path.lineTo(72, 52);
    path.lineTo(28, 52);
    path.lineTo(28, 82);
    path.lineTo(8, 82);
    path.close();
    // 内三角（挖空）
    path.moveTo(50, 30);
    path.lineTo(72, 70);
    path.lineTo(50, 70);
    path.lineTo(28, 70);
    path.close();

    // 用 evenOdd 填充规则挖空
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 方案 4: LT 徽章 ─────────────────────────────────────────────
class _LogoLTBadge extends StatelessWidget {
  const _LogoLTBadge();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _LTBadgePainter(),
    );
  }
}

class _LTBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    // 外框
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(5, 5, 90, 90),
        const Radius.circular(8),
      ),
      paint,
    );
    // 内部黑色区域
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, 76, 76),
        const Radius.circular(5),
      ),
      bgPaint,
    );
    // L 字母
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 22, 16, 56),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 64, 36, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    // T 字母
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(48, 22, 32, 14),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(58, 22, 12, 42),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoLTCircle extends StatelessWidget {
  const _LogoLTCircle();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _LTCirclePainter(),
    );
  }
}

class _LTCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    // 外圆
    canvas.drawCircle(
      const Offset(50, 50),
      45,
      paint,
    );
    // 内部黑色
    final bgPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(50, 50),
      36,
      bgPaint,
    );
    // L
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 24, 12, 42),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 54, 26, 12),
        const Radius.circular(2),
      ),
      paint,
    );
    // T
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(44, 24, 28, 12),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(54, 24, 10, 32),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 方案 5: 圆环 ────────────────────────────────────────────────
class _LogoRing extends StatelessWidget {
  const _LogoRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _RingPainter(),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(10, 10, 80, 80),
      -0.3, // 起始角度（稍微偏移，制造缺口）
      5.8, // 弧度（不到 2π，留缺口）
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoDoubleRing extends StatelessWidget {
  const _LogoDoubleRing();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _DoubleRingPainter(),
    );
  }
}

class _DoubleRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 外环
    paint.strokeWidth = 8;
    canvas.drawArc(
      Rect.fromLTWH(8, 8, 84, 84),
      -0.2,
      5.6,
      false,
      paint,
    );
    // 内环
    paint.strokeWidth = 6;
    canvas.drawArc(
      Rect.fromLTWH(24, 24, 52, 52),
      2.5,
      4.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 方案 6: L + 哑铃组合 ────────────────────────────────────────
class _LogoLDumbbell extends StatelessWidget {
  const _LogoLDumbbell();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _LDumbbellPainter(),
    );
  }
}

class _LDumbbellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    // L 竖线（杠铃杆左半）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 10, 12, 50),
        const Radius.circular(3),
      ),
      paint,
    );
    // L 横线（杠铃杆）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 48, 60, 12),
        const Radius.circular(3),
      ),
      paint,
    );
    // 左配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 38, 10, 32),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(72, 38, 10, 32),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右内配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(64, 42, 8, 24),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoLDumbbellRounded extends StatelessWidget {
  const _LogoLDumbbellRounded();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: CustomPaint(
        size: const Size(100, 100),
        painter: _LDumbbellWhitePainter(),
      ),
    );
  }
}

class _LDumbbellWhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // L 竖线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 12, 10, 44),
        const Radius.circular(2),
      ),
      paint,
    );
    // L 横线
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 46, 52, 10),
        const Radius.circular(2),
      ),
      paint,
    );
    // 左配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 38, 10, 28),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(66, 38, 10, 28),
        const Radius.circular(3),
      ),
      paint,
    );
    // 右内配重
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(58, 42, 8, 20),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
