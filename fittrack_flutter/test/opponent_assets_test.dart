// test/opponent_assets_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('all 12 opponent assets exist', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final paths = [
      'assets/opponent/face_beginner.png',
      'assets/opponent/face_iron.png',
      'assets/opponent/face_ninja.png',
      'assets/opponent/face_ambassador.png',
      'assets/opponent/outfit_beginner.png',
      'assets/opponent/outfit_iron.png',
      'assets/opponent/outfit_ninja.png',
      'assets/opponent/outfit_ambassador.png',
      'assets/opponent/prop_beginner.png',
      'assets/opponent/prop_iron.png',
      'assets/opponent/prop_ninja.png',
      'assets/opponent/prop_ambassador.png',
    ];
    for (final p in paths) {
      final asset = AssetImage(p);
      final config = ImageConfiguration.empty;
      final completer = asset.resolve(config);
      expect(completer, isNotNull, reason: '$p not found');
    }
  });
}
