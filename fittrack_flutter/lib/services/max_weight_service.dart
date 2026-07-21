// lib/services/max_weight_service.dart
// MaxWeightService：扫描训练记录中的所有 exercises[].sets[].weight，
// 提供全局最大重量 + 按部位分组的 Top N 动作。
import '../data/storage.dart';

class MaxWeightRecord {
  final String exerciseName;
  final double weight;
  final String muscleGroup;
  final DateTime date;
  final String? recordId;

  MaxWeightRecord({
    required this.exerciseName,
    required this.weight,
    required this.muscleGroup,
    required this.date,
    this.recordId,
  });
}

class MaxWeightService {
  static final MaxWeightService instance = MaxWeightService._();
  MaxWeightService._();

  /// 获取全局最大重量（扫描所有训练记录的所有 sets）
  MaxWeightRecord? getGlobalMax() {
    final records = Storage.getRecords();
    MaxWeightRecord? best;
    for (final r in records) {
      final exercises = r['exercises'] as List? ?? [];
      for (final e in exercises) {
        if (e is! Map) continue;
        final sets = e['sets'] as List? ?? [];
        for (final s in sets) {
          if (s is! Map) continue;
          final weight = (s['weight'] as num?)?.toDouble() ?? 0;
          if (weight > 0 && (best == null || weight > best.weight)) {
            best = MaxWeightRecord(
              exerciseName: (e['name'] as String?) ?? '',
              weight: weight,
              muscleGroup: _inferMuscleGroup((e['name'] as String?) ?? ''),
              date: DateTime.fromMillisecondsSinceEpoch(_readTimestamp(r)),
              recordId: r['id'] as String?,
            );
          }
        }
      }
    }
    return best;
  }

  /// 按部位分组获取 Top N 动作最大重量（同一动作在不同训练中可能多次出现，保留每次记录）
  Map<String, List<MaxWeightRecord>> getTopByMuscleGroup({int limit = 5}) {
    final Map<String, List<MaxWeightRecord>> grouped = {};
    final records = Storage.getRecords();
    for (final r in records) {
      final exercises = r['exercises'] as List? ?? [];
      for (final e in exercises) {
        if (e is! Map) continue;
        final name = (e['name'] as String?) ?? '';
        final group = _inferMuscleGroup(name);
        final sets = e['sets'] as List? ?? [];
        double maxW = 0;
        for (final s in sets) {
          if (s is! Map) continue;
          final w = (s['weight'] as num?)?.toDouble() ?? 0;
          if (w > maxW) maxW = w;
        }
        if (maxW > 0) {
          grouped.putIfAbsent(group, () => []);
          grouped[group]!.add(MaxWeightRecord(
            exerciseName: name,
            weight: maxW,
            muscleGroup: group,
            date: DateTime.fromMillisecondsSinceEpoch(_readTimestamp(r)),
            recordId: r['id'] as String?,
          ));
        }
      }
    }
    // 每组按重量倒序取 Top N
    final result = <String, List<MaxWeightRecord>>{};
    grouped.forEach((key, list) {
      list.sort((a, b) => b.weight.compareTo(a.weight));
      result[key] = list.take(limit).toList();
    });
    return result;
  }

  /// 记录时间戳：兼容 timestamp / date / createTime 三种字段名（毫秒）
  static int _readTimestamp(Map<String, dynamic> r) {
    final v = r['timestamp'] ?? r['date'] ?? r['createTime'];
    if (v is int) return v;
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// 简单部位推断（通过动作名关键字）
  static String _inferMuscleGroup(String name) {
    final n = name.toLowerCase();
    if (n.contains('卧推') || n.contains('夹胸') || n.contains('俯卧撑')) return '胸部';
    if (n.contains('飞鸟') && (n.contains('胸') || n.contains('平'))) return '胸部';
    if (n.contains('硬拉') || n.contains('划船') || n.contains('引体') ||
        n.contains('下拉') || n.contains('高位') || n.contains('杠铃划') ||
        n.contains('单臂划')) return '背部';
    if (n.contains('深蹲') || n.contains('腿举') || n.contains('腿屈伸') ||
        n.contains('弓步') || n.contains('提踵') || n.contains('腿弯举') ||
        n.contains('保加利亚')) return '腿部';
    if (n.contains('推举') || n.contains('侧平举') || n.contains('前平举') ||
        n.contains('肩推') || n.contains('阿诺德')) return '肩膀';
    if (n.contains('弯举') || n.contains('臂屈伸') || n.contains('锤式') ||
        n.contains('绳索下压') || n.contains('集中弯')) return '手臂';
    if (n.contains('卷腹') || n.contains('平板支撑') || n.contains('举腿') ||
        n.contains('俄罗斯转体') || n.contains('仰卧起坐') || n.contains('腹部')) return '核心';
    return '其他';
  }

  static const List<String> kMuscleGroups = ['胸部', '背部', '腿部', '肩膀', '手臂', '核心', '其他'];
}
