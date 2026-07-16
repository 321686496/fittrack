import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../widgets/page_header.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: '系统化课程', subtitle: '从入门到精通的完整训练体系', onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: CourseLibrary.courses.length,
              itemBuilder: (ctx, i) {
                final c = CourseLibrary.courses[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/course/${c.id}'),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c.coverColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(c.coverEmoji, style: const TextStyle(fontSize: 48)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(c.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(c.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('${c.chapters.length}章 · ${c.pointsCost}积分', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
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
