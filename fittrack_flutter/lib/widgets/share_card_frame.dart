import 'package:flutter/material.dart';

/// A 9:16 vertical share card rendered via RepaintBoundary.
class ShareCardFrame extends StatelessWidget {
  final Map<String, dynamic> record;
  final Size size;

  const ShareCardFrame({
    required this.record,
    this.size = const Size(1080, 1920),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final name = record['name'] as String? ?? '训练完成';
    final totalWeight = record['totalWeight'] as int? ?? 0;
    final totalSets = record['totalSets'] as int? ?? 0;
    final duration = record['duration'] as int? ?? 0;
    final dateTs = record['date'] as int? ?? 0;
    final date = dateTs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dateTs)
        : DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final durationStr = '${(duration / 60).floor()}分钟';

    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 120, color: Colors.amber),
          const SizedBox(height: 40),
          const Text('今日训练完成',
              style: TextStyle(color: Colors.white70, fontSize: 36)),
          const SizedBox(height: 24),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          _metricRow('总重量', '$totalWeight kg'),
          const SizedBox(height: 24),
          _metricRow('总组数', '$totalSets 组'),
          const SizedBox(height: 24),
          _metricRow('训练时长', durationStr),
          const SizedBox(height: 24),
          _metricRow('日期', dateStr),
          const Spacer(),
          const Text('FitTrack 燃力 · 记录每一组',
              style: TextStyle(color: Colors.white54, fontSize: 28)),
          const SizedBox(height: 20),
          // QR code placeholder: in production use a real QR rendering library
          Container(
            width: 200, height: 200,
            color: Colors.white,
            alignment: Alignment.center,
            child: const Text('二维码', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 32)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
