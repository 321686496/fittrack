import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../services/poster_generator.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_preview_dialog.dart';

/// 笔记海报全屏页面
///
/// v1.2 优化：从 BottomSheet 改为全屏页面，含 PageHeader 返回按钮
///
/// v1.3 优化（2026-07-21）：进入页面后自动调用 [PosterGenerator.capture]
/// 生成 PNG，弹出 [PosterPreviewDialog] 预览；预览关闭后自动 pop 回上一页。
/// 不再保留页面内的"立即分享"/"保存图片"按钮，统一走 [PosterPreviewDialog]。
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
  final GlobalKey _posterKey = GlobalKey();
  bool _capturing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 等首帧渲染完成后再截图
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndShow());
  }

  Future<void> _captureAndShow() async {
    try {
      // 等待多帧，确保 RepaintBoundary 内的 QrImageView 等完成 layout + paint
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 100));

      final imagePath = await PosterGenerator.capture(
        _posterKey,
        fileNamePrefix: 'fittrack_note',
      );
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
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = '$e';
      });
      FitToast.error(context, '海报生成失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: NotePosterContent(
                note: widget.note,
                boundRecord: widget.boundRecord,
                posterKey: _posterKey,
              ),
            ),
          ),
          if (_capturing)
            LinearProgressIndicator(
              color: colors.accentGlow,
              backgroundColor: colors.borderColor,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: colors.warningColor, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
