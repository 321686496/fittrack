import '../data/storage.dart';

/// 休息时间偏好推荐服务
///
/// 基于用户历史训练记录中的实际休息时间，计算推荐的休息秒数。
/// 需要用户首次训练满 7 天后才会提供推荐。
class RestPreferenceService {
  static final RestPreferenceService instance = RestPreferenceService._();
  RestPreferenceService._();

  /// 是否已满足推荐条件：用户首次训练满 7 天
  bool isPreferenceAvailable() {
    final records = Storage.getRecords();
    if (records.isEmpty) return false;

    final earliest = records.reduce((a, b) =>
        (a['date'] as num) < (b['date'] as num) ? a : b);
    final firstTrainingDate =
        DateTime.fromMillisecondsSinceEpoch((earliest['date'] as num).toInt());
    return DateTime.now().difference(firstTrainingDate).inDays >= 7;
  }

  /// 计算推荐休息秒数，数据不足返回 null
  int? computeRecommendedRestSeconds() {
    if (!isPreferenceAvailable()) return null;

    final records = Storage.getRecords();
    final allActuals = <int>[];

    // 取最近 10 条 records 的 restLog
    for (final r in records.take(10)) {
      final restLog = r['restLog'] as List? ?? [];
      for (final log in restLog) {
        final logMap = log is Map<String, dynamic>
            ? log
            : Map<String, dynamic>.from(log as Map);
        // 兼容新旧字段
        final actual = (logMap['actualRestSeconds'] as num?)?.toInt() ??
            (logMap['actualTime'] as num?)?.toInt();
        final reason = logMap['restEndReason'] as String?;
        // 过滤掉自动超时上限结算的异常记录
        if (actual != null && actual > 0 && reason != 'autoTimeout') {
          allActuals.add(actual);
        }
      }
    }

    if (allActuals.length < 3) return null; // 至少 3 条有效样本

    // IQR 异常过滤
    allActuals.sort();
    final q1 = _percentile(allActuals, 25);
    final q3 = _percentile(allActuals, 75);
    final iqr = q3 - q1;
    final lower = q1 - 1.5 * iqr;
    final upper = q3 + 1.5 * iqr;
    final filtered = allActuals.where((s) => s >= lower && s <= upper).toList();

    if (filtered.isEmpty) return null;

    // 加权平均：越近期权重越高（线性递增）
    double weightedSum = 0;
    double weightSum = 0;
    for (var i = 0; i < filtered.length; i++) {
      final w = (i + 1).toDouble();
      weightedSum += filtered[i] * w;
      weightSum += w;
    }
    final avg = (weightedSum / weightSum).round();
    // 取 5 秒为粒度对齐
    final aligned = ((avg + 2.5) ~/ 5) * 5;
    // 钳制到合理区间 [15, 600]
    return aligned.clamp(15, 600);
  }

  int _percentile(List<int> sorted, int p) {
    final idx = (p / 100 * (sorted.length - 1)).round();
    return sorted[idx.clamp(0, sorted.length - 1)];
  }
}
