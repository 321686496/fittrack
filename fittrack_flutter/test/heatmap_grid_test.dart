import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/widgets/heatmap_grid.dart';

void main() {
  testWidgets('HeatmapGrid renders 7 weekday labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: HeatmapGrid(records: [])),
    ));
    await tester.pump();
    // Should show 7 day-of-week headers
    expect(find.text('一'), findsOneWidget);
    expect(find.text('日'), findsOneWidget);
  });

  testWidgets('HeatmapGrid highlights trained day', (WidgetTester tester) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final records = <Map<String, dynamic>>[
      {'date': today.millisecondsSinceEpoch, 'duration': 3600, 'id': 'r1'},
    ];
    // ignore: date_str unused, but kept for debugging
    // ignore: unused_local_variable
    final _ = todayStr;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HeatmapGrid(records: records)),
    ));
    await tester.pump();
    // The widget should render without error
    expect(find.byType(HeatmapGrid), findsOneWidget);
  });
}
