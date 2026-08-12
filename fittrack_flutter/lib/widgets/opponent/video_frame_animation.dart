// lib/widgets/opponent/video_frame_animation.dart
import 'package:flutter/material.dart';

const Map<String, Map<String, int>> kFrameCounts = {
  'beginner':   {'idle': 24,  'train': 97},
  'iron':       {'idle': 12,  'train': 37},
  'ninja':      {'idle': 12,  'train': 109},
  'ambassador': {'idle': 12,  'train': 37},
};

const Map<String, String> _skinToAsset = {
  'skin_beginner': 'beginner',
  'skin_iron_warrior': 'iron',
  'skin_cyber_ninja': 'ninja',
  'skin_ambassador': 'ambassador',
};

/// 视频帧动画：用 Image.asset 逐帧渲染（Flutter 标准组件，跨平台兼容）
class VideoFrameAnimation extends StatefulWidget {
  final String skinId;
  final bool isTraining;
  final double progress;
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

  @override
  State<VideoFrameAnimation> createState() => _VideoFrameAnimationState();
}

class _VideoFrameAnimationState extends State<VideoFrameAnimation> {
  String _lastPath = '';

  String get _assetName => _skinToAsset[widget.skinId] ?? 'beginner';

  String _framePath(String mode, int index) {
    return 'assets/opponent/video_frames/${_assetName}_${mode}/${_assetName}_${mode}_${index.toString().padLeft(4, '0')}.png';
  }

  int _currentFrameIndex(String mode) {
    final count = kFrameCounts[_assetName]?[mode] ?? 0;
    if (count == 0) return 0;
    return (widget.progress * count).floor() % count;
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.isTraining ? 'train' : 'idle';
    final frameIndex = _currentFrameIndex(mode);
    final imagePath = _framePath(mode, frameIndex);

    // 帧变化时触发重建（Image.asset 内部有缓存，不会重复解码）
    if (_lastPath != imagePath) {
      _lastPath = imagePath;
      // 延迟到下一帧，避免在 build 中调用 setState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 光圈
          if (widget.showAura && widget.auraColor != null)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.auraColor!.withOpacity(0.2 * widget.entryProgress),
                  boxShadow: [
                    BoxShadow(
                      color: widget.auraColor!.withOpacity(0.15 * widget.entryProgress),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
          // 当前帧
          Center(
            child: Image.asset(
              imagePath,
              key: ValueKey(imagePath),
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
