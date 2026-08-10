// lib/widgets/opponent/video_frame_animation.dart
import 'package:flutter/material.dart';

/// 每个皮肤的帧数
const Map<String, Map<String, int>> kFrameCounts = {
  'beginner':   {'idle': 24,  'train': 97},
  'iron':       {'idle': 12,  'train': 37},
  'ninja':      {'idle': 12,  'train': 109},
  'ambassador': {'idle': 12,  'train': 37},
};

/// 用 Image.asset 逐帧渲染视频序列（内存友好，Flutter 自动缓存管理）
class VideoFrameAnimation extends StatelessWidget {
  final String skinId;
  final bool isTraining;
  final double progress; // 0.0 ~ 1.0
  final bool showAura;
  final Color? auraColor;
  final double entryProgress;

  const VideoFrameAnimation({
    super.key,
    required this.skinId,
    required this.isTraining,
    required this.progress,
    this.showAura = false,
    this.auraColor,
    this.entryProgress = 1.0,
  });

  String _framePath(String mode, int index) {
    return 'assets/opponent/video_frames/${skinId}_${mode}/${skinId}_${mode}_${index.toString().padLeft(4, '0')}.png';
  }

  int _currentFrameIndex(String mode) {
    final count = kFrameCounts[skinId]?[mode] ?? 0;
    if (count == 0) return 0;
    return (progress * count).floor() % count;
  }

  @override
  Widget build(BuildContext context) {
    final mode = isTraining ? 'train' : 'idle';
    final frameIndex = _currentFrameIndex(mode);
    final imagePath = _framePath(mode, frameIndex);

    return Stack(
      children: [
        // 光圈
        if (showAura && auraColor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: auraColor!.withOpacity(0.2 * entryProgress),
                  boxShadow: [
                    BoxShadow(
                      color: auraColor!.withOpacity(0.15 * entryProgress),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        // 当前帧
        Center(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              // 加载失败时显示空白
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
