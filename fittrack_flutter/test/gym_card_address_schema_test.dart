// 隔离验证：address 列是否在 gym_cards 表中缺失（gym_card_page._showAddCardSheet 会写入 address）
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_flutter/data/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();
    // 预加载 gym_cards 缓存（各测试用独立 id，互不影响）
    await Storage.getGymCardsAsync();
  });

  test('addGymCardAsync 带 address（模拟 gym_card_page 添加）应成功持久化', () async {
    // 模拟 gym_card_page 提交的数据 —— 包含 address 字段
    final cardData = <String, dynamic>{
      'name': '测试年卡',
      'gymName': '金吉鸟健身',
      'address': 'XX市XX区XX路88号',
      'cardType': '年卡',
      'price': 1200,
      'startDate': DateTime(2025, 1, 1).millisecondsSinceEpoch,
      'endDate': DateTime(2026, 1, 1).millisecondsSinceEpoch,
      'remainingCount': -1,
      'totalCount': -1,
      'phone': '021-12345678',
      'remark': '',
    };

    try {
      final added = await Storage.addGymCardAsync(cardData);
      final cardId = added['id'] as String;
      // 从 DB 重新加载（模拟重启后 getGymCardsAsync 恢复缓存），验证确实已持久化
      final cards = await Storage.getGymCardsAsync();
      final card = cards.firstWhere((c) => c['id'] == cardId);
      expect(card['address'], 'XX市XX区XX路88号');
    } catch (e) {
      fail('addGymCardAsync 带 address 不应抛出异常: $e');
    }
  });

  test('updateGymCardAsync 写入 address 应成功持久化', () async {
    final cardData = <String, dynamic>{
      'name': '测试次卡',
      'gymName': '金吉鸟健身',
      'cardType': '次卡',
    };
    final added = await Storage.addGymCardAsync(cardData);
    final cardId = added['id'] as String;

    try {
      await Storage.updateGymCardAsync(cardId, {'address': '上海市浦东新区张江高科技园区'});
      // 从 DB 重新加载，验证 update 已持久化
      final cards = await Storage.getGymCardsAsync();
      final updated = cards.firstWhere((c) => c['id'] == cardId);
      expect(updated['address'], '上海市浦东新区张江高科技园区');
    } catch (e) {
      fail('updateGymCardAsync 写 address 不应抛出异常: $e');
    }
  });

  test('不提供 address 时默认落库为空字符串', () async {
    final cardData = <String, dynamic>{
      'name': '默认地址测试',
      'gymName': '超级猩猩',
      'cardType': '月卡',
      'price': 150,
      'startDate': DateTime(2025, 1, 1).millisecondsSinceEpoch,
      'endDate': DateTime(2025, 2, 1).millisecondsSinceEpoch,
    };
    // 不含 address 键
    cardData.remove('address');
    final added = await Storage.addGymCardAsync(cardData);
    final cardId = added['id'] as String;
    final allCards = await Storage.getGymCardsAsync();
    final found = allCards.firstWhere((c) => c['id'] == cardId);
    expect(found['address'], '');
  });
}
