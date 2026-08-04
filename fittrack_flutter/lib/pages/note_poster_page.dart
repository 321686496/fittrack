import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../services/poster_generator.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_preview_dialog.dart';

/// 笔记海报页面
///
/// v1.4 优化：改为 Overlay 离屏渲染模式（与其他海报一致），
/// NotePosterContent 以 1080×1920 全分辨率渲染，截图更清晰。
/// 页面上只显示 loading 动画，截图完成后弹出 [PosterPreviewDialog]。
class NotePosterPage extends StatefulWidget {
  final TrainingNote note;
  final Map<String, dynamic>? boundRecord;

  const NotePosterPage({
    super.key,
    required this.note,
    this.boundRecord,
  });

  @override
  State<NotePosterPage> createState() => _NotePosterPageState();
}

class _NotePosterPageState extends State<NotePosterPage> {
  bool _capturing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndShow());
  }

  Future<void> _captureAndShow() async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);
    const posterWidth = NotePosterContent.posterWidth;
    const posterHeight = NotePosterContent.posterHeight;

    // 用 Overlay + Positioned(offscreen) 渲染海报
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -posterWidth,
        top: -posterHeight,
        width: posterWidth,
        height: posterHeight,
        child: Material(
          color: Colors.transparent,
          child: OverflowBox(
            minWidth: posterWidth,
            maxWidth: posterWidth,
            minHeight: posterHeight,
            maxHeight: posterHeight,
            child: RepaintBoundary(
              key: boundaryKey,
              child: NotePosterContent(
                note: widget.note,
                boundRecord: widget.boundRecord,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    // paint 等待已统一收敛到 PosterGenerator.capture 内部，
    // 此处不再使用固定 50ms 等待（首帧 paint 未完成时调用 toImage 会触发
    // '!debugNeedsPaint' 断言）。
    try {
      final imagePath = await PosterGenerator.capture(
        boundaryKey,
        fileNamePrefix: 'fittrack_note',
      );
      entry.remove();
      if (!mounted) return;
      setState(() => _capturing = false);
      await PosterPreviewDialog.show(
        context,
        imagePath: imagePath,
        title: '训练笔记海报',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      entry.remove();
      if (!mounted) return;
      setState(() => _capturing = false);
      FitToast.error(context, '海报生成失败：$e');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '笔记海报',
            isTabPage: false,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colors.accentGlow,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _capturing ? '正在生成海报...' : '生成完成',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
