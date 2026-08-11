import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/data/storage.dart';
import '../lib/services/recommendation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Storage.addRecord/getRecords 依赖 SQLite，测试环境需初始化 ffi databaseFactory
  // （与 invitation_service_test.dart 等项目测试保持一致）
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    Storage.clearAll();
  });

  group('RecommendationService.generateBanners', () {
    test('首项必为 invitation 类型', () {
      final banners = RecommendationService.generateBanners();
      expect(banners, isNotEmpty);
      expect(banners.first.type, 'invitation');
    });

    test('invitation 携带进度数据（默认无邀请 → nextMilestone 1）', () {
      final banners = RecommendationService.generateBanners();
      final first = banners.first;
      expect(first.type, 'invitation');
      final extra = first.extra!;
      expect(extra['totalReferrals'], 0);
      expect(extra['nextMilestone'], 1);
      expect(extra['isAmbassador'], false);
    });
  });
}
