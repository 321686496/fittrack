import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/course_content.dart';
import '../utils/art_assets.dart';
import '../widgets/page_header.dart';

import '../l10n/i18n.dart';
class CourseListPage extends StatelessWidget {
  CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PageHeader(title: tr(context, '系统化课程'), subtitle: tr(context, '从入门到精通的完整训练体系'), onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: CourseLibrary.courses.length,
              itemBuilder: (ctx, i) {
                final c = CourseLibrary.courses[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/course/${c.id}'),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: c.coverColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // 课程封面美术（缺失时回退到渐变）
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                courseArtAsset(c.id),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => SizedBox.shrink(),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 0.7],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(c.coverEmoji, style: TextStyle(fontSize: 48)),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 卡片高度固定 120，英文标题/副标题更长，
                                      // 限制单行省略，避免内容撑破卡片
                                      Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 4),
                                      Text(c.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      SizedBox(height: 8),
                                      Text(tr(context, '${c.chapters.length}章 · ${c.pointsCost}积分'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white60, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
