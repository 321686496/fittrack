import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:fittrack_flutter/data/virtual_goods.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
  });

  group('VirtualGoodsStore', () {
    test('byId 返回已知商品', () {
      expect(VirtualGoodsStore.byId('skin_iron_warrior')?.name, '熔铁匠人');
      expect(VirtualGoodsStore.byId('skin_ambassador')?.isLimited, true);
    });

    test('byId 未知 id 返回 null', () {
      expect(VirtualGoodsStore.byId('not_exist'), isNull);
    });

    test('byCategory 过滤对手皮肤', () {
      final skins = VirtualGoodsStore.byCategory(GoodCategory.opponentSkin);
      expect(skins.length, 4);
      expect(skins.every((g) => g.category == GoodCategory.opponentSkin), true);
    });

    test('affordableWith 返回可负担商品（限定款排除）', () {
      final list = VirtualGoodsStore.affordableWith(300);
      expect(list.any((g) => g.id == 'skin_beginner'), true);
      expect(list.any((g) => g.id == 'skin_iron_warrior'), true);
      expect(list.any((g) => g.id == 'skin_cyber_ninja'), false);
      expect(list.any((g) => g.id == 'skin_ambassador'), false);
    });
  });
}
