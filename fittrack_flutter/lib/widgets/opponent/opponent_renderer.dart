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
    final skin = OpponentSkinConfig.byId(widget.skinId);
    _idleController = AnimationController(
      vsync: this,
      duration: skin.idleMotion.duration,
    );
    if (widget.animate) {
      _idleController.repeat();
    } else {
      _idleController.value = 0.0;
    }
    _trainController = AnimationController(
      vsync: this,
      duration: skin.trainingMotion.duration,
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
    final entryOffset = (1 - Curves.elasticOut.transform(_entryController.value)) * 60;
    final isThumbnail = widget.size.width < 80;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _trainController, _entryController]),
        builder: (context, _) {
          final progress = _isTraining ? _trainController.value : _idleController.value;
          return Transform.translate(
            offset: Offset(0, entryOffset),
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: isThumbnail
                  ? _buildThumbnail(skin)
                  : VideoFrameAnimation(
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

  /// 缩略图：用 face + outfit + prop 图片拼接
  Widget _buildThumbnail(OpponentSkinConfig skin) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 光圈
        if (widget.showAura)
          IgnorePointer(
            child: Container(
              width: widget.size.width * 0.9,
              height: widget.size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skin.palette.auraColor.withOpacity(0.15),
              ),
            ),
          ),
        // 服饰
        if (skin.outfitAsset != null)
          Positioned(
            bottom: 0,
            child: Image.asset(
              skin.outfitAsset!,
              width: widget.size.width * 0.7,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // 头部
        if (skin.faceAsset != null)
          Positioned(
            top: 0,
            child: Image.asset(
              skin.faceAsset!,
              width: widget.size.width * 0.55,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        // 道具
        if (skin.propAsset != null)
          Positioned(
            right: 0,
            bottom: widget.size.height * 0.3,
            child: Image.asset(
              skin.propAsset!,
              width: widget.size.width * 0.35,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
