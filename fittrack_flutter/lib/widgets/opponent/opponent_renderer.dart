// lib/widgets/opponent/opponent_renderer.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'opponent_skin_config.dart';
import 'painters/body_painter.dart';
import 'painters/head_painter.dart';
import 'painters/outfit_painter.dart';
import 'painters/prop_painter.dart';

class OpponentRenderer extends StatefulWidget {
  final String skinId;
  final Size size;
  final bool autoTrain;
  final bool showAura;
  /// 是否启动 idle 循环动画。默认 true 保持原视觉行为。
  /// 在不可见区域（如 IndexedStack 中非当前 tab）可传 false 节省 CPU。
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

  // 预加载贴图
  ui.Image? _faceImage;
  ui.Image? _outfitImage;
  ui.Image? _propImage;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    final skin = OpponentSkinConfig.byId(widget.skinId);
    _idleController = AnimationController(
      vsync: this,
      duration: skin.idleMotion.duration,
    );
    // 仅在显式请求动画时启动循环；缩略图保持静态首帧，避免每帧重绘
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

    _preloadImages(skin);
  }

  Future<void> _preloadImages(OpponentSkinConfig skin) async {
    ui.Image? face, outfit, prop;
    final results = await Future.wait([
      if (skin.faceAsset != null) _loadImage(skin.faceAsset!),
      if (skin.outfitAsset != null) _loadImage(skin.outfitAsset!),
      if (skin.propAsset != null) _loadImage(skin.propAsset!),
    ]);
    if (!mounted) return;
    // 按顺序赋值，避免索引越界（旧代码 results[1]/[2] 在缺资源时 RangeError）
    int idx = 0;
    if (skin.faceAsset != null) face = results[idx++];
    if (skin.outfitAsset != null) outfit = results[idx++];
    if (skin.propAsset != null) prop = results[idx++];
    setState(() {
      _faceImage = face;
      _outfitImage = outfit;
      _propImage = prop;
      _imagesLoaded = true;
    });
  }

  Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      return completer.future;
    } catch (_) {
      return null; // fallback to code drawing
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
    return AnimatedBuilder(
      animation: Listenable.merge([_idleController, _trainController, _entryController]),
      builder: (context, _) {
        final skin = OpponentSkinConfig.byId(widget.skinId);
        final progress = _isTraining ? _trainController.value : _idleController.value;
        final frame = (_isTraining ? skin.trainingMotion : skin.idleMotion)
            .interpolate(progress);
        final entryOffset = (1 - Curves.elasticOut.transform(_entryController.value)) * 60;

        final isThumbnail = widget.size.width < 80;

        return RepaintBoundary(
          child: Transform.translate(
            offset: Offset(0, entryOffset),
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: CustomPaint(
                painter: CompositePainter(
                  skin: skin,
                  frame: frame,
                  showAura: widget.showAura,
                  entryProgress: _entryController.value,
                  faceImage: _imagesLoaded ? _faceImage : null,
                  outfitImage: _imagesLoaded ? _outfitImage : null,
                  propImage: _imagesLoaded ? _propImage : null,
                  isThumbnail: isThumbnail,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 聚合 4 个子 Painter
class CompositePainter extends CustomPainter {
  final OpponentSkinConfig skin;
  final MotionFrame frame;
  final bool showAura;
  final double entryProgress;
  final ui.Image? faceImage;
  final ui.Image? outfitImage;
  final ui.Image? propImage;
  final bool isThumbnail;

  const CompositePainter({
    required this.skin,
    required this.frame,
    required this.showAura,
    required this.entryProgress,
    required this.faceImage,
    required this.outfitImage,
    required this.propImage,
    this.isThumbnail = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 光圈
    if (showAura) _drawAura(canvas, size);

    // 身体
    BodyPainter(palette: skin.palette, frame: frame).paint(canvas, size);

    // 服饰（缩略图跳过）
    if (!isThumbnail) {
      OutfitPainter(palette: skin.palette, frame: frame, outfitImage: outfitImage)
          .paint(canvas, size);
    }

    // 头部
    HeadPainter(palette: skin.palette, frame: frame, faceImage: faceImage)
        .paint(canvas, size);

    // 道具（缩略图跳过）
    if (!isThumbnail) {
      PropPainter(palette: skin.palette, frame: frame, propImage: propImage)
          .paint(canvas, size);
    }
  }

  void _drawAura(Canvas canvas, Size size) {
    final scale = size.width / 240.0;
    canvas.save();
    canvas.scale(scale);
    final auraPaint = Paint()
      ..color = skin.palette.auraColor.withOpacity(0.2 * entryProgress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(const Offset(120, 120), 100, auraPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompositePainter old) {
    return old.frame != frame ||
        old.entryProgress != entryProgress ||
        old.faceImage != faceImage ||
        old.outfitImage != outfitImage ||
        old.propImage != propImage ||
        old.skin.id != skin.id;
  }
}
