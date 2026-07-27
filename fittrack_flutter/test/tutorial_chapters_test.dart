import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/tutorial_content.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('Tutorial chapters', () {
    test('basic tutorial 应有 3 章', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.chapters.length, 3);
      expect(t.chapters[0].title, '动作要领');
      expect(t.chapters[1].title, '常见错误');
      expect(t.chapters[2].title, '呼吸与变式');
    });

    test('chapterPointsCost basic=0', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.chapterPointsCost, 0);
    });

    test('chapterPointsCost advanced=50', () {
      final t = TutorialLibrary.advancedTutorials.first;
      expect(t.chapterPointsCost, 50);
    });

    test('chapterPointsCost topic=80', () {
      final t = TutorialLibrary.topicTutorials.first;
      expect(t.chapterPointsCost, 80);
    });

    test('chapterPointsCost master=120', () {
      final t = TutorialLibrary.masterTutorials.first;
      expect(t.chapterPointsCost, 120);
    });

    test('chapterFeatureId 格式正确', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.chapterFeatureId('keypoints'), 'tutorial_${t.id}_chapter_keypoints');
    });

    test('allChaptersFeatureId 格式正确', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.allChaptersFeatureId, 'tutorial_${t.id}_all');
    });

    test('basic 类型所有章节默认已解锁', () {
      final t = TutorialLibrary.basicTutorials.first;
      expect(t.isChapterUnlocked('keypoints'), true);
      expect(t.isChapterUnlocked('mistakes'), true);
      expect(t.isChapterUnlocked('breathing'), true);
    });

    test('advanced 类型未解锁时章节应锁定', () {
      final t = TutorialLibrary.advancedTutorials.first;
      // 未解锁状态下应锁定
      expect(t.isChapterUnlocked('keypoints'), false);
    });

    test('allTutorials 应包含所有 4 类教学', () {
      final all = TutorialLibrary.allTutorials;
      expect(all.length,
        TutorialLibrary.basicTutorials.length +
        TutorialLibrary.advancedTutorials.length +
        TutorialLibrary.topicTutorials.length +
        TutorialLibrary.masterTutorials.length);
    });
  });
}
