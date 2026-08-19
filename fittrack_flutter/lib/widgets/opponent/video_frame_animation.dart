// lib/widgets/opponent/video_frame_animation.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// 帧序列播放帧率，与 scripts/extract_video_frames.py 的 target_fps 保持一致。
/// 一整套动作循环按该帧率逐帧播放，避免被动作时长错误加速。
const double kFramePlaybackFps = 12.0;

/// 每套皮肤/角色的帧数：idle 待机 / train 训练。
/// 数值必须与 assets/opponent/video_frames 下的实际帧数一致。
const Map<String, Map<String, int>> kFrameCounts = {
  'beginner':   {'idle': 24,  'train': 97},
  'iron':       {'idle': 12,  'train': 37},
  'ninja':      {'idle': 12,  'train': 109},
  'ambassador': {'idle': 12,  'train': 37},
  'default_male':   {'idle': 24,  'train': 97},
  'default_female': {'idle': 24,  'train': 96},
};

const Map<String, String> _skinToAsset = {
  'skin_beginner': 'beginner',
  'skin_iron_warrior': 'iron',
  'skin_cyber_ninja': 'ninja',
  'skin_ambassador': 'ambassador',
  'default_male': 'default_male',
  'default_female': 'default_female',
};

/// skinId/characterId -> 素材目录名。
String opponentAssetName(String skinId) => _skinToAsset[skinId] ?? 'beginner';

/// 某个模式（idle/train）完整循环一次所需时长：
/// 按提取帧率逐帧播放，即 frameCount / kFramePlaybackFps 秒。
Duration frameLoopDuration(String skinId, String mode) {
  final count = kFrameCounts[opponentAssetName(skinId)]?[mode] ?? 0;
  if (count <= 0) return Duration.zero;
  return Duration(
    microseconds:
        (count / kFramePlaybackFps * Duration.microsecondsPerSecond).round(),
  );
}

/// 根据 progress(0-1) 计算当前帧索引。
/// 控制器时长设为 [frameLoopDuration] 时，progress 的一整个周期 = 一套循环。
int opponentFrameIndex(String skinId, bool isTraining, double progress) {
  final mode = isTraining ? 'train' : 'idle';
  final count = kFrameCounts[opponentAssetName(skinId)]?[mode] ?? 0;
  if (count == 0) return 0;
  final idx = (progress * count).floor() % count;
  return idx < 0 ? idx + count : idx;
}

/// 视频帧动画：用 Image.asset 逐帧渲染（Flutter 标准组件，跨平台兼容）。
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
  /// 提前预热的后续帧数，保证帧切换时新图已解码，避免闪烁/卡顿。
  static const int _preloadWindow = 3;

  String _lastMode = '';
  int _lastFrame = -1;

  String get _assetName => opponentAssetName(widget.skinId);

  String _framePath(String mode, int index) {
    return 'assets/opponent/video_frames/${_assetName}_$mode/${_assetName}_${mode}_${index.toString().padLeft(4, '0')}.png';
  }

  int _currentFrameIndex() =>
      opponentFrameIndex(widget.skinId, widget.isTraining, widget.progress);

  @override
  void initState() {
    super.initState();
    // 首次挂载后预热当前帧窗口
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPreload());
  }

  @override
  void didUpdateWidget(covariant VideoFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPreload();
  }

  /// 帧变化时预热当前帧及其后几帧（ImageCache 会滚动淘汰旧帧，
  /// 但每帧在播放前已完成解码，显示时无需等待）。
  void _syncPreload() {
    if (!mounted) return;
    final mode = widget.isTraining ? 'train' : 'idle';
    final frame = _currentFrameIndex();
    if (mode == _lastMode && frame == _lastFrame) return;
    _lastMode = mode;
    _lastFrame = frame;

    final count = kFrameCounts[_assetName]?[mode] ?? 0;
    if (count == 0) return;
    for (int i = 0; i <= _preloadWindow; i++) {
      final idx = (frame + i) % count;
      precacheImage(AssetImage(_framePath(mode, idx)), context).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.isTraining ? 'train' : 'idle';
    final frameIndex = _currentFrameIndex();
    final imagePath = _framePath(mode, frameIndex);

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
          // 当前帧：不更换 key + gaplessPlayback，
          // 帧切换时保留上一帧直到新帧解码完成，避免闪烁
          Center(
            child: Image.asset(
              imagePath,
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
