import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/widgets/celebration_overlay.dart';

void main() {
  testWidgets('CelebrationOverlay shows first-time message',
      (WidgetTester tester) async {
    final record = <String, dynamic>{
      'name': '胸肌训练',
      'totalWeight': 3250,
      'duration': 3120,
    };
    OverlayEntry? entry;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              entry = await CelebrationOverlay.show(context,
                  record: record, previousRecord: null);
            },
            child: const Text('show'),
          ),
        );
      }),
    ));
    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.textContaining('开始'), findsOneWidget);
    // Wait for animation to complete (3 seconds)
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
