import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // ignore: depend_on_referenced_packages
import '../themes/app_themes.dart';
import '../data/course_content.dart';
import '../data/mock_data.dart';
import '../widgets/page_header.dart';

class ChapterReadPage extends StatelessWidget {
  final String courseId;
  final String chapterId;
  const ChapterReadPage({super.key, required this.courseId, required this.chapterId});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final course = CourseLibrary.getById(courseId);
    final chapter = course?.chapters.where((c) => c.id == chapterId).firstOrNull;
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
                  // 图文混排内容
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
                                colors: course.coverColors.map((c) => c.withOpacity(0.3)).toList(),
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
                  // 推荐动作卡片
                  if (chapter.recommendedExerciseIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('推荐动作', style: TextStyle(
                      color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold,
                    )),
                    const SizedBox(height: 12),
                    ...chapter.recommendedExerciseIds.map((id) {
                      final ex = MockData.exercises.firstWhere(
                        (e) => e['id'] == id,
                        orElse: () => {'name': id},
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
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
