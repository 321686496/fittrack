import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // ignore: depend_on_referenced_packages
import '../themes/app_themes.dart';
import '../data/course_content.dart';
import '../data/content_block.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../services/points_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ChapterReadPage extends StatefulWidget {
  final String courseId;
  final String chapterId;
  const ChapterReadPage({super.key, required this.courseId, required this.chapterId});

  @override
  State<ChapterReadPage> createState() => _ChapterReadPageState();
}

class _ChapterReadPageState extends State<ChapterReadPage> {
  bool _learned = false;

  @override
  void initState() {
    super.initState();
    final learnedList = Storage.getSettings()['learnedChapters'] as List? ?? [];
    _learned = learnedList.any((id) => id == widget.chapterId);
  }

  Future<void> _completeLearning(Chapter chapter) async {
    final settings = Storage.getSettings();
    final learnedList = List<String>.from(settings['learnedChapters'] as List? ?? []);
    if (learnedList.contains(widget.chapterId)) return;

    learnedList.add(widget.chapterId);
    settings['learnedChapters'] = learnedList;
    Storage.saveSettings(settings);

    final reward = chapter.pointsReward ?? 10;
    await PointsService.instance.addPoints(reward, 'course_learn');

    if (mounted) {
      setState(() => _learned = true);
      FitToast.success(context, '恭喜获得 $reward 积分');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final course = CourseLibrary.getById(widget.courseId);
    final chapter = course?.chapters.where((c) => c.id == widget.chapterId).firstOrNull;
    if (chapter == null) return const Scaffold(body: Center(child: Text('章节不存在')));

    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: chapter.title, subtitle: course!.title, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(colors, chapter),
                  // 完成学习按钮
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _learned ? null : () => _completeLearning(chapter),
                        child: Text(_learned ? '已学习' : '完成学习 +${chapter.pointsReward ?? 10} 积分'),
                      ),
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

  Widget _buildContent(LiftTrackColors colors, Chapter chapter) {
    if (chapter.blocks.isEmpty) {
      return _buildLegacyContent(colors, chapter);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: chapter.blocks.map((b) => _buildBlock(colors, b)).toList(),
    );
  }

  Widget _buildLegacyContent(LiftTrackColors colors, Chapter chapter) {
    // 旧逻辑 fallback：content.split('\n\n') + imageEmojis + 推荐动作卡片
    final course = CourseLibrary.getById(widget.courseId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...chapter.content.split('\n\n').asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          final emoji = idx < chapter.imageEmojis.length ? chapter.imageEmojis[idx] : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (emoji != null) ...[
                Container(
                  width: double.infinity,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: course!.coverColors.map((c) => c.withOpacity(0.3)).toList(),
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
                ),
              ],
              Text(text, style: TextStyle(
                color: colors.textPrimary, fontSize: 14, height: 1.6,
              )),
              const SizedBox(height: 16),
            ],
          );
        }),
        if (chapter.recommendedExerciseIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('推荐动作', style: TextStyle(
            color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 12),
          ...chapter.recommendedExerciseIds.map((id) => _buildExerciseCard(colors, id)),
        ],
      ],
    );
  }

  Widget _buildBlock(LiftTrackColors colors, ContentBlock b) {
    switch (b.type) {
      case BlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(b.text!, style: TextStyle(
            color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
          )),
        );
      case BlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(b.text!, style: TextStyle(
            color: colors.textSecondary, fontSize: 14, height: 1.6,
          )),
        );
      case BlockType.image:
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(b.imageUrl!, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) =>
                Container(height: 120, color: colors.bgSecondary, child: Icon(Icons.broken_image, color: colors.textMuted)),
              ),
            ),
            if (b.imageCaption != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                child: Text(b.imageCaption!, style: TextStyle(
                  color: colors.textMuted, fontSize: 12,
                ), textAlign: TextAlign.center),
              ),
          ],
        );
      case BlockType.quote:
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colors.accentGlow, width: 3)),
          ),
          child: Text(b.text!, style: TextStyle(
            color: colors.textSecondary, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6,
          )),
        );
      case BlockType.bulletList:
        final items = b.text!.split('\n');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(width: 5, height: 5, decoration: BoxDecoration(color: colors.accentGlow, shape: BoxShape.circle)),
                  ),
                  Expanded(child: Text(item.trim(), style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5))),
                ],
              ),
            )).toList(),
          ),
        );
      case BlockType.exerciseCard:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildExerciseCard(colors, b.exerciseId!),
        );
      case BlockType.callout:
        final bgColor = b.calloutType == 'warning' ? colors.warningColor : (b.calloutType == 'tip' ? colors.successColor : colors.accentGlow);
        final icon = b.calloutType == 'warning' ? Icons.warning_amber_rounded : (b.calloutType == 'tip' ? Icons.lightbulb_outline : Icons.info_outline);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bgColor.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: bgColor, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(b.text!, style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.5))),
            ],
          ),
        );
    }
  }

  Widget _buildExerciseCard(LiftTrackColors colors, String exerciseId) {
    final ex = MockData.exercises.firstWhere(
      (e) => e['id'] == exerciseId,
      orElse: () => {'name': exerciseId},
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.play_circle_outline, color: colors.accentGlow, size: 20),
          const SizedBox(width: 10),
          Text(ex['name'] as String, style: TextStyle(
            color: colors.textPrimary, fontSize: 14,
          )),
        ],
      ),
    );
  }
}
