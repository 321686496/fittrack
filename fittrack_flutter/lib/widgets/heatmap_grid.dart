import 'package:flutter/material.dart';

/// GitHub-style training heatmap showing the last 13 weeks.
class HeatmapGrid extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const HeatmapGrid({required this.records, super.key});

  Map<String, int> _aggregateByDate() {
    final map = <String, int>{};
    for (final r in records) {
      final ts = r['date'] as int?;
      if (ts == null || ts == 0) continue;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + ((r['duration'] as int?) ?? 0);
    }
    return map;
  }

  Color _colorForDuration(int duration, BuildContext context) {
    if (duration == 0) return Theme.of(context).dividerColor.withOpacity(0.3);
    if (duration < 1800) return Colors.blue.withOpacity(0.4);
    if (duration < 3600) return Colors.blue.withOpacity(0.7);
    return Colors.blue.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final aggregated = _aggregateByDate();
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    // 13 weeks ago Monday
    final startWeekday = todayMidnight.weekday; // 1=Mon..7=Sun
    final startDate =
        todayMidnight.subtract(Duration(days: startWeekday - 1 + 12 * 7));

    final weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return SizedBox(
      height: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('训练日历', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels column
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdayLabels
                      .map((l) => Text(l,
                          style: Theme.of(context).textTheme.bodySmall))
                      .toList(),
                ),
                const SizedBox(width: 8),
                // Grid: 13 columns × 7 rows
                Expanded(
                  child: Row(
                    children: List.generate(13, (weekIdx) {
                      return Expanded(
                        child: Column(
                          children: List.generate(7, (dayIdx) {
                            final date = startDate
                                .add(Duration(days: weekIdx * 7 + dayIdx));
                            if (date.isAfter(todayMidnight)) {
                              return const Expanded(child: SizedBox());
                            }
                            final key =
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            final duration = aggregated[key] ?? 0;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(1.5),
                                child: Tooltip(
                                  message:
                                      '$key\n训练时长: ${(duration / 60).round()} 分钟',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _colorForDuration(duration, context),
                                      borderRadius: BorderRadius.circular(2),
                                      border: duration >= 3600
                                          ? Border.all(
                                              color: Colors.blue.shade900,
                                              width: 1.2)
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
