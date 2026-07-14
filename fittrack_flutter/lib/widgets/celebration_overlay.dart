import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class CelebrationOverlay {
  static Future<OverlayEntry?> show(
    BuildContext context, {
    required Map<String, dynamic> record,
    Map<String, dynamic>? previousRecord,
  }) {
    final completer = Completer<OverlayEntry?>();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CelebrationWidget(
        record: record,
        previousRecord: previousRecord,
        onDismiss: () {
          entry.remove();
          completer.complete(entry);
        },
      ),
    );
    overlay.insert(entry);
    return completer.future;
  }
}

class _CelebrationWidget extends StatefulWidget {
  final Map<String, dynamic> record;
  final Map<String, dynamic>? previousRecord;
  final VoidCallback onDismiss;

  const _CelebrationWidget({
    required this.record,
    required this.previousRecord,
    required this.onDismiss,
  });

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _particles = <_Particle>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _spawnParticles();
    _ctrl.forward().whenComplete(widget.onDismiss);
  }

  void _spawnParticles() {
    final rng = Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        angle: rng.nextDouble() * 2 * pi,
        speed: 80 + rng.nextDouble() * 120,
        size: 4 + rng.nextDouble() * 6,
        color: HSVColor.fromAHSV(1.0, rng.nextDouble() * 360, 0.7, 1.0)
            .toColor(),
      ));
    }
  }

  String _buildMessage() {
    if (widget.previousRecord == null) {
      return '你的健身旅程开始了';
    }
    final prev = widget.previousRecord!;
    final prevWeight = prev['totalWeight'] as int? ?? 0;
    final curWeight = widget.record['totalWeight'] as int? ?? 0;
    if (prevWeight == 0 || curWeight == 0) return '训练完成';
    final delta = (curWeight - prevWeight) / prevWeight;
    if (delta > 0.02) return '总重量提升 ${(delta * 100).round()}%';
    if (delta < -0.02) return '比上次更快完成';
    return '保持稳定，继续努力';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            return CustomPaint(
              size: Size.infinite,
              painter: _ParticlePainter(_particles, _ctrl.value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration,
                      color: Colors.amber, size: 80),
                  const SizedBox(height: 16),
                  Text(widget.record['name'] as String? ?? '训练完成',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_buildMessage(),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 18)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1 - t).clamp(0.0, 1.0);
    for (final p in particles) {
      final dx = center.dx + cos(p.angle) * p.speed * t * 3;
      final dy = center.dy + sin(p.angle) * p.speed * t * 3;
      // Resolution 1: withOpacity NOT withValues (Flutter 3.7.12 compatibility)
      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.drawCircle(Offset(dx, dy), p.size * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
