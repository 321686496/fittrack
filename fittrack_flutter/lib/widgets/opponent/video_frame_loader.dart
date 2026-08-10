// lib/widgets/opponent/video_frame_loader.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;

/// 每个皮肤的帧数（从 extract_video_frames.py 提取结果）
const Map<String, Map<String, int>> _frameCounts = {
  'beginner':   {'idle': 24,  'train': 97},
  'iron':       {'idle': 12,  'train': 37},
  'ninja':      {'idle': 12,  'train': 109},
  'ambassador': {'idle': 12,  'train': 37},
};

/// 加载皮肤的视频帧序列资源
class VideoFrameLoader {
  /// 加载指定皮肤的所有帧（已知帧数，直接加载）
  static Future<List<ui.Image>> loadFrames(String skinId, String mode) async {
    final count = _frameCounts[skinId]?[mode] ?? 0;
    if (count == 0) return [];

    final frames = <ui.Image>[];
    for (int i = 0; i < count; i++) {
      final path = 'assets/opponent/video_frames/${skinId}_${mode}/${skinId}_${mode}_${i.toString().padLeft(4, '0')}.png';
      try {
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List();
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(bytes, completer.complete);
        frames.add(await completer.future);
      } catch (e) {
        // 单帧失败不中断，继续加载后续帧
      }
    }
    return frames;
  }

  /// 预加载皮肤的待机+训练帧
  static Future<VideoFrameSet> preload(String skinId) async {
    final idleFrames = await loadFrames(skinId, 'idle');
    final trainFrames = await loadFrames(skinId, 'train');
    return VideoFrameSet(
      idleFrames: idleFrames,
      trainFrames: trainFrames,
    );
  }
}

class VideoFrameSet {
  final List<ui.Image> idleFrames;
  final List<ui.Image> trainFrames;

  const VideoFrameSet({
    required this.idleFrames,
    required this.trainFrames,
  });

  bool get isLoaded => idleFrames.isNotEmpty && trainFrames.isNotEmpty;
}
