/// 提醒调度相关的纯计算逻辑，便于单元测试。
library;

/// 健身卡提醒候选（一张卡对应一个后台提醒）。
class ReminderCandidate {
  final String name;
  final DateTime remindDate;
  final String content;

  const ReminderCandidate({
    required this.name,
    required this.remindDate,
    required this.content,
  });
}

/// 计算每日训练提醒的下一次触发时间。
///
/// 规则（与历史实现保持一致）：
/// - 目标时间在今天且尚未过去 -> 今天
/// - 目标时间已过 -> 明天同一时间
DateTime nextDailyReminder(DateTime now, int hour, int minute) {
  var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

/// 扫描所有健身卡，为每张符合条件的卡生成一个提醒候选。
///
/// 规则（与历史 `reschedule()` 语义一致）：
/// - 期限卡（endDate > 0）：提醒日 = 到期日 - 阈值天；若提醒日已过但卡未到期，改为今天；
///   内容按“今天到期 / 还有 N 天 / 已过期 N 天”生成。
/// - 次卡（cardType == '次卡'）：剩余次数 <= 阈值时今天提醒。
/// - 返回按卡顺序排列，每张符合条件的卡各一个候选（不再只取“最近”的一张）。
List<ReminderCandidate> computeGymCardCandidates({
  required List<Map<String, dynamic>> cards,
  required int daysThreshold,
  required int countThreshold,
  required DateTime now,
}) {
  final candidates = <ReminderCandidate>[];
  final today = DateTime(now.year, now.month, now.day);

  for (final card in cards) {
    final name = card['name'] as String? ?? '未命名卡';
    final cardType = card['cardType'] as String? ?? '';
    final endDate = card['endDate'] as int? ?? 0;
    final remaining = card['remainingCount'] as int? ?? -1;

    // 次卡：剩余次数 <= 阈值时今天提醒
    if (cardType == '次卡' && remaining >= 0 && remaining <= countThreshold) {
      final content = remaining == 0
          ? '「$name」已用完所有次数'
          : '「$name」仅剩 $remaining 次';
      candidates.add(ReminderCandidate(
        name: name,
        remindDate: today,
        content: content,
      ));
      continue;
    }

    // 期限卡：endDate > 0 才参与调度
    if (endDate <= 0) continue;
    final end = DateTime.fromMillisecondsSinceEpoch(endDate);
    final endDay = DateTime(end.year, end.month, end.day);
    final remindDate0 = endDay.subtract(Duration(days: daysThreshold));
    final remindDate = remindDate0.isBefore(today) ? today : remindDate0;

    final diff = endDay.difference(today).inDays;
    final String content;
    if (diff < 0) {
      content = '「$name」已过期 ${-diff} 天';
    } else if (diff == 0) {
      content = '「$name」今天到期';
    } else {
      content = '「$name」还有 $diff 天到期';
    }
    candidates.add(ReminderCandidate(
      name: name,
      remindDate: remindDate,
      content: content,
    ));
  }

  return candidates;
}
