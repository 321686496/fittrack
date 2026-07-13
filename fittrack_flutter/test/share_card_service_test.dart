import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/widgets/share_card_frame.dart';

void main() {
  testWidgets('ShareCardFrame renders training summary fields',
      (WidgetTester tester) async {
    final record = <String, dynamic>{
      'name': '胸肌训练',
      'totalWeight': 3250,
      'totalSets': 16,
      'duration': 3120,
      'date': DateTime(2026, 7, 13).millisecondsSinceEpoch,
    };
    // The share card is a fixed 1080x1920 render target; expand the test
    // surface so the card is not clipped by the default 800x600 viewport.
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShareCardFrame(
          record: record,
          size: const Size(1080, 1920),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('胸肌训练'), findsOneWidget);
    expect(find.textContaining('3250'), findsOneWidget);
    expect(find.textContaining('16'), findsOneWidget);
  });
}
