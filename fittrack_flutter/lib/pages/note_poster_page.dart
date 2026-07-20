import 'package:flutter/material.dart';
import '../data/training_note.dart';
import '../themes/app_themes.dart';
import '../widgets/note_poster.dart';
import '../widgets/page_header.dart';

/// 笔记海报全屏页面
///
/// v1.2 优化：从 BottomSheet 改为全屏页面，含 PageHeader 返回按钮
class NotePosterPage extends StatelessWidget {
  final TrainingNote note;
  final Map<String, dynamic>? boundRecord;

  const NotePosterPage({
    super.key,
    required this.note,
    this.boundRecord,
  });

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
                note: note,
                boundRecord: boundRecord,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
