// lib/widgets/opponent/video_frame_animation.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  final List<ui.Image> _idleFrames = [];
  ui.Image? _currentImage;
  final Map<int, ui.Image> _trainCache = {};
  int _loadingIndex = -1;
  int _loadVersion = 0;
  bool _idleLoaded = false;

  String get _assetName => _skinToAsset[widget.skinId] ?? 'beginner';

  String _framePath(String mode, int index) {
    return 'assets/opponent/video_frames/${_assetName}_${mode}/${_assetName}_${mode}_${index.toString().padLeft(4, '0')}.png';
  }

  Future<ui.Image> _decodeFrame(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<void> _preloadIdleFrames() async {
    final count = kFrameCounts[_assetName]?['idle'] ?? 0;
    if (count == 0) return;

    for (int i = 0; i < count; i++) {
      try {
        final image = await _decodeFrame(_framePath('idle', i));
        if (mounted) {
          _idleFrames.add(image);
        } else {
          return;
        }
      } catch (_) {
        break;
      }
    }

    if (mounted) {
      setState(() {
        _idleLoaded = true;
        if (_idleFrames.isNotEmpty) {
          _currentImage = _idleFrames[0];
        }
      });
    }
  }

  void _updateFrame(double progress) {
    final mode = widget.isTraining ? 'train' : 'idle';
    final count = kFrameCounts[_assetName]?[mode] ?? 0;
    if (count == 0) return;

    final frameIndex = (progress * count).floor() % count;

    if (mode == 'idle') {
      if (frameIndex < _idleFrames.length) {
        final img = _idleFrames[frameIndex];
        if (_currentImage != img) {
          setState(() => _currentImage = img);
        }
      }
    } else {
      if (_trainCache.containsKey(frameIndex)) {
        final img = _trainCache[frameIndex]!;
        if (_currentImage != img) {
          setState(() => _currentImage = img);
        }
      } else if (frameIndex != _loadingIndex) {
        _loadingIndex = frameIndex;
        _loadVersion++;
        final version = _loadVersion;
        final path = _framePath('train', frameIndex);
        _decodeFrame(path).then((image) {
          if (mounted && _loadVersion == version) {
            _trainCache[frameIndex] = image;
            setState(() => _currentImage = image);
          }
        }).catchError((_) {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _preloadIdleFrames();
  }

  @override
  void didUpdateWidget(covariant VideoFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 progress 或 isTraining 变化时更新帧
    if (oldWidget.progress != widget.progress || oldWidget.isTraining != widget.isTraining) {
      _updateFrame(widget.progress);
    }
  }

  @override
  void dispose() {
    for (final img in _idleFrames) {
      img.dispose();
    }
    for (final img in _trainCache.values) {
      img.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.showAura && widget.auraColor != null)
          Positioned.fill(
            child: IgnorePointer(
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
          ),
        Center(
          child: _currentImage != null
              ? RawImage(image: _currentImage, fit: BoxFit.contain)
              : const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ],
    );
  }
}
