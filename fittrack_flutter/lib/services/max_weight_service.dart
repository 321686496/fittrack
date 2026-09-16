// lib/services/max_weight_service.dart
// MaxWeightService：扫描训练记录中的 setRecords（{动作id: [{weight, reps, ...}]}），
// 提供全局最大重量 + 按部位分组的 Top N 动作。
import '../data/storage.dart';
import '../data/mock_data.dart';

import '../l10n/i18n.dart';
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

/// 单条记录内单个动作的最大重量条目（内部解析用）
class _ExerciseMax {
  final String name;
  final String group;
  final double weight;
  _ExerciseMax(this.name, this.group, this.weight);
}

class MaxWeightService {
  static final MaxWeightService instance = MaxWeightService._();
  MaxWeightService._();

  /// 获取全局最大重量（扫描所有训练记录的所有动作）
  MaxWeightRecord? getGlobalMax() {
    final records = Storage.getRecords();
    final lookup = _buildExerciseLookup();
    MaxWeightRecord? best;
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(_readTimestamp(r));
      final recordId = r['id'] as String?;
      for (final m in _extractRecordMaxWeights(r, lookup)) {
        if (best == null || m.weight > best.weight) {
          best = MaxWeightRecord(
            exerciseName: m.name,
            weight: m.weight,
            muscleGroup: m.group,
            date: date,
            recordId: recordId,
          );
        }
      }
    }
    return best;
  }

  /// 获取各部位的最大重量（单条，取该部位重量最高的记录）
  Map<String, double> getMaxByMuscleGroup() {
    final grouped = getTopByMuscleGroup(limit: 1);
    final result = <String, double>{};
    grouped.forEach((key, list) {
      if (list.isNotEmpty) {
        result[key] = list.first.weight;
      }
    });
    return result;
  }

  /// 按部位分组获取 Top N 动作最大重量（同一动作在不同训练中可能多次出现，保留每次记录）
  Map<String, List<MaxWeightRecord>> getTopByMuscleGroup({int limit = 5}) {
    final Map<String, List<MaxWeightRecord>> grouped = {};
    final records = Storage.getRecords();
    final lookup = _buildExerciseLookup();
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(_readTimestamp(r));
      final recordId = r['id'] as String?;
      for (final m in _extractRecordMaxWeights(r, lookup)) {
        grouped.putIfAbsent(m.group, () => []);
        grouped[m.group]!.add(MaxWeightRecord(
          exerciseName: m.name,
          weight: m.weight,
          muscleGroup: m.group,
          date: date,
          recordId: recordId,
        ));
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

  /// 构建动作 id → {name, category} 查找表。
  /// MockData 提供基础动作的分类，用户计划中的动作（含自定义动作）名称优先。
  static Map<String, Map<String, String>> _buildExerciseLookup() {
    final lookup = <String, Map<String, String>>{};
    for (final ex in MockData.exercises) {
      final id = ex['id']?.toString();
      if (id == null) continue;
      lookup[id] = {
        'name': ex['name']?.toString() ?? id,
        'category': ex['category']?.toString() ?? '',
      };
    }
    for (final p in Storage.getPlans()) {
      final days = p['days'] as List?;
      if (days == null) continue;
      for (final d in days) {
        if (d is! Map) continue;
        for (final ex in (d['exercises'] as List? ?? [])) {
          if (ex is! Map) continue;
          final id = ex['id']?.toString();
          if (id == null) continue;
          final name = ex['name']?.toString();
          final category = ex['category']?.toString();
          final prev = lookup[id];
          lookup[id] = {
            'name': (name != null && name.isNotEmpty) ? name : (prev?['name'] ?? id),
            'category':
                (category != null && category.isNotEmpty) ? category : (prev?['category'] ?? ''),
          };
        }
      }
    }
    return lookup;
  }

  /// 解析单条记录中每个动作的最大重量。
  /// setRecords = {动作id: [{weight, reps, ...}]}（训练页保存格式）
  static List<_ExerciseMax> _extractRecordMaxWeights(
    Map<String, dynamic> r,
    Map<String, Map<String, String>> lookup,
  ) {
    final result = <_ExerciseMax>[];
    final setRecords = r['setRecords'];
    if (setRecords is! Map) return result;

    for (final entry in setRecords.entries) {
      final exId = entry.key.toString();
      final info = lookup[exId];
      final name = info?['name'] ?? exId;
      var group = info?['category'] ?? '';
      if (group.isEmpty || !kMuscleGroups.contains(group)) {
        group = _inferMuscleGroup(name);
      }
      double maxW = 0;
      for (final s in (entry.value as List? ?? [])) {
        if (s is! Map) continue;
        final w = (s['weight'] as num?)?.toDouble() ?? 0;
        if (w > maxW) maxW = w;
      }
      if (maxW > 0) result.add(_ExerciseMax(name, group, maxW));
    }
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
    if (n.contains('卧推') || n.contains('夹胸') || n.contains('俯卧撑')) return trn('胸部');
    if (n.contains('飞鸟') && (n.contains('胸') || n.contains('平'))) return trn('胸部');
    if (n.contains('硬拉') || n.contains('划船') || n.contains('引体') ||
        n.contains('下拉') || n.contains('高位') || n.contains('杠铃划') ||
        n.contains('单臂划')) return trn('背部');
    if (n.contains('深蹲') || n.contains('腿举') || n.contains('腿屈伸') ||
        n.contains('弓步') || n.contains('提踵') || n.contains('腿弯举') ||
        n.contains('保加利亚')) return trn('腿部');
    if (n.contains('推举') || n.contains('侧平举') || n.contains('前平举') ||
        n.contains('肩推') || n.contains('阿诺德')) return trn('肩膀');
    if (n.contains('弯举') || n.contains('臂屈伸') || n.contains('锤式') ||
        n.contains('绳索下压') || n.contains('集中弯')) return trn('手臂');
    if (n.contains('卷腹') || n.contains('平板支撑') || n.contains('举腿') ||
        n.contains('俄罗斯转体') || n.contains('仰卧起坐') || n.contains('腹部')) return trn('核心');
    return trn('其他');
  }

  static List<String> get kMuscleGroups => _kMuscleGroupsMemo.value;
  static final LocaleMemo<List<String>> _kMuscleGroupsMemo = LocaleMemo(() => [trn('胸部'), trn('背部'), trn('腿部'), trn('肩膀'), trn('手臂'), trn('核心'), trn('其他')]);

  /// 各部位最大重量里程碑（kg），按升序排列
  static final Map<String, List<double>> kMuscleGroupMilestones = {
    '胸部': [20, 40, 60, 80, 100, 120, 140],
    '背部': [20, 40, 60, 80, 100, 120, 140, 160],
    '腿部': [30, 50, 80, 100, 120, 140, 160, 180, 200],
    '肩膀': [10, 20, 30, 40, 50, 60, 70],
    '手臂': [10, 15, 20, 25, 30, 40],
    '核心': [10, 20, 30, 40, 50],
    '其他': [20, 40, 60, 80, 100],
  };
}
