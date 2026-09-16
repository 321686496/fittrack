import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';
import '../widgets/poster_capture_helper.dart';

/// 笔记海报页面
///
/// 复用 [PosterCaptureHelper.captureAndPreview] 统一的内容自适应截图流程，
/// NotePosterContent 以 1080 宽全分辨率渲染，截图更清晰。
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
    try {
      await PosterCaptureHelper.captureAndPreview(
        context,
        posterWidget: NotePosterContent(
          note: widget.note,
          boundRecord: widget.boundRecord,
        ),
        posterWidth: NotePosterContent.posterWidth,
        title: '训练笔记海报',
        fileNamePrefix: 'fittrack_note',
      );
    } catch (e) {
      if (mounted) {
        FitToast.error(context, '海报生成失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
        // 预览弹窗已关闭，返回上一页
        Navigator.of(context).pop();
      }
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
