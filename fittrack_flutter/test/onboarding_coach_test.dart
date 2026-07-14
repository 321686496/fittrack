import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/widgets/onboarding_coach.dart';

void main() {
  testWidgets('OnboardingCoach renders first step prompt',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OnboardingCoach(
          onComplete: () {},
          onSkip: () {},
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('今天练什么部位？'), findsOneWidget);
  });
}
