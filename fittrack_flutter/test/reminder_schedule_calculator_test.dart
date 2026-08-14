import 'package:fittrack_flutter/services/reminder_schedule_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDailyReminder', () {
    test('目标时间在今天之后 -> 今天', () {
      final now = DateTime(2026, 8, 14, 10, 0);
      final result = nextDailyReminder(now, 18, 30);
      expect(result, DateTime(2026, 8, 14, 18, 30));
    });

    test('目标时间已过 -> 明天', () {
      final now = DateTime(2026, 8, 14, 19, 0);
      final result = nextDailyReminder(now, 18, 30);
      expect(result, DateTime(2026, 8, 15, 18, 30));
    });

    test('目标分钟未到（秒数提前）-> 今天', () {
      final now = DateTime(2026, 8, 14, 18, 29, 59);
      final result = nextDailyReminder(now, 18, 30);
      expect(result, DateTime(2026, 8, 14, 18, 30));
    });

    test('目标时间与当前完全相等 -> 今天（与旧逻辑一致）', () {
      final now = DateTime(2026, 8, 14, 18, 30, 0);
      final result = nextDailyReminder(now, 18, 30);
      expect(result, DateTime(2026, 8, 14, 18, 30));
    });

    test('跨月边界 -> 次月同一天', () {
      final now = DateTime(2026, 8, 31, 20, 0);
      final result = nextDailyReminder(now, 8, 0);
      expect(result, DateTime(2026, 9, 1, 8, 0));
    });
  });

  group('computeGymCardCandidates', () {
    final now = DateTime(2026, 8, 14, 10, 0);

    test('期限卡：提醒日 = 到期日 - 阈值天', () {
      final cards = [
        {
          'name': '年卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 8, 24, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].remindDate, DateTime(2026, 8, 17));
      expect(result[0].content, contains('10 天到期'));
    });

    test('期限卡：提醒日已过且未到期 -> 改为今天提醒', () {
      final cards = [
        {
          'name': '月卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 8, 17, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].remindDate, DateTime(2026, 8, 14));
    });

    test('期限卡已过期 -> 今天提醒并提示过期天数', () {
      final cards = [
        {
          'name': '过期卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 8, 12, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].remindDate, DateTime(2026, 8, 14));
      expect(result[0].content, contains('已过期 2 天'));
    });

    test('期限卡今天到期 -> 今天提醒', () {
      final cards = [
        {
          'name': '临期卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 8, 14, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].content, contains('今天到期'));
    });

    test('次卡剩余次数 <= 阈值 -> 今天提醒', () {
      final cards = [
        {
          'name': '次卡A',
          'cardType': '次卡',
          'endDate': 0,
          'remainingCount': 2,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].remindDate, DateTime(2026, 8, 14));
      expect(result[0].content, contains('仅剩 2 次'));
    });

    test('次卡剩余 0 -> 提示已用完', () {
      final cards = [
        {
          'name': '次卡B',
          'cardType': '次卡',
          'endDate': 0,
          'remainingCount': 0,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(1));
      expect(result[0].content, contains('已用完所有次数'));
    });

    test('次卡剩余次数高于阈值 -> 不生成提醒', () {
      final cards = [
        {
          'name': '次卡C',
          'cardType': '次卡',
          'endDate': 0,
          'remainingCount': 5,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, isEmpty);
    });

    test('无到期日的期限卡 -> 不生成提醒', () {
      final cards = [
        {
          'name': '无到期日',
          'cardType': '期限卡',
          'endDate': 0,
          'remainingCount': -1,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, isEmpty);
    });

    test('多张卡 -> 每张符合条件的卡各生成一个提醒（不是只取最近一张）', () {
      final cards = [
        {
          'name': '年卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 12, 1, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
        {
          'name': '次卡A',
          'cardType': '次卡',
          'endDate': 0,
          'remainingCount': 1,
        },
        {
          'name': '月卡',
          'cardType': '期限卡',
          'endDate': DateTime(2026, 8, 20, 23, 59).millisecondsSinceEpoch,
          'remainingCount': -1,
        },
        {
          'name': '次卡C',
          'cardType': '次卡',
          'endDate': 0,
          'remainingCount': 9,
        },
      ];
      final result = computeGymCardCandidates(
        cards: cards,
        daysThreshold: 7,
        countThreshold: 3,
        now: now,
      );
      expect(result, hasLength(3));
      expect(result.map((c) => c.name), ['年卡', '次卡A', '月卡']);
    });
  });
}
