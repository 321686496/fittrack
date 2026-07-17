import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/course_content.dart';
import '../services/points_service.dart';
import '../widgets/unlock_panel.dart';
import '../widgets/page_header.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  const CourseDetailPage({super.key, required this.courseId});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final course = CourseLibrary.getById(widget.courseId);
    if (course == null) return const Scaffold(body: Center(child: Text('课程不存在')));

    final isUnlocked = PointsService.instance.isFeatureUnlocked(course.id);

    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: course.title, subtitle: course.subtitle, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: course.chapters.length,
              itemBuilder: (ctx, i) {
                final ch = course.chapters[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: isUnlocked
                      ? () => context.push('/course/${course.id}/chapter/${ch.id}')
                      : () async {
                        final unlocked = await UnlockPanel.show(
                          context: context,
                          title: course.title,
                          description: course.description,
                          pointsCost: course.pointsCost,
                          featureId: course.id,
                        );
                        if (unlocked && mounted) setState(() {});
                      },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: colors.accentGlow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text('${i + 1}', style: TextStyle(
                              color: colors.accentGlow, fontWeight: FontWeight.bold,
                            ))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(ch.title, style: TextStyle(
                            color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
                          ))),
                          Icon(
                            isUnlocked ? Icons.chevron_right : Icons.lock_outline,
                            color: colors.textMuted, size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
