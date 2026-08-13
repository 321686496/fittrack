// lib/widgets/opponent/opponent_renderer.dart
import 'package:flutter/material.dart';
import 'opponent_skin_config.dart';
import 'video_frame_animation.dart';

class OpponentRenderer extends StatefulWidget {
  final String skinId;
  final Size size;
  final bool autoTrain;
  final bool showAura;
  final bool animate;

  const OpponentRenderer({
    super.key,
    required this.skinId,
    required this.size,
    this.autoTrain = false,
    this.showAura = false,
    this.animate = true,
  });

  @override
  State<OpponentRenderer> createState() => _OpponentRendererState();
}

class _OpponentRendererState extends State<OpponentRenderer>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _trainController;
  late AnimationController _entryController;
  bool _isTraining = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      // 帧序列按 12fps 播放一整圈所需时长，与动作插值时长解耦，
      // 避免 97 帧等长序列在 1.2s 内被快速播完
      duration: frameLoopDuration(widget.skinId, 'idle'),
    );
    if (widget.animate) {
      _idleController.repeat();
    } else {
      _idleController.value = 0.0;
    }
    _trainController = AnimationController(
      vsync: this,
      duration: frameLoopDuration(widget.skinId, 'train'),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    if (widget.autoTrain) {
      Future.delayed(const Duration(seconds: 2), _startTraining);
    }
  }

  void _startTraining() {
    if (!mounted) return;
    setState(() => _isTraining = true);
    _trainController.repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    _trainController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = OpponentSkinConfig.byId(widget.skinId);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _trainController, _entryController]),
        builder: (context, _) {
          final progress = _isTraining ? _trainController.value : _idleController.value;
          final entryOffset = (1 - Curves.elasticOut.transform(_entryController.value)) * 60;
          return Transform.translate(
            offset: Offset(0, entryOffset),
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: VideoFrameAnimation(
                skinId: widget.skinId,
                isTraining: _isTraining,
                progress: progress,
                showAura: widget.showAura,
                auraColor: skin.palette.auraColor,
                entryProgress: _entryController.value,
              ),
            ),
          );
        },
      ),
    );
  }
}
