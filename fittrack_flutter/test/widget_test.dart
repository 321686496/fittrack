import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LiftTrackApp());
    await tester.pump();
    expect(find.text('LiftTrack'), findsOneWidget);
  });
}
