// lib/data/weight_comparisons.dart
// 趣味对比阈值表：把举起的最大重量映射为日常物品的趣味对照。
class WeightComparison {
  final double minKg;
  final double maxKg;
  final String label;
  final String emoji;

  const WeightComparison({
    required this.minKg,
    required this.maxKg,
    required this.label,
    required this.emoji,
  });

  /// 按重量区间返回对应趣味对照；超出最大区间则返回最后一个区间。
  static WeightComparison forWeight(double kg) {
    for (final c in kWeightComparisons) {
      if (kg >= c.minKg && kg < c.maxKg) return c;
    }
    return kWeightComparisons.last;
  }
}

const List<WeightComparison> kWeightComparisons = [
  WeightComparison(minKg: 0, maxKg: 20, label: '一只小猫', emoji: '🐱'),
  WeightComparison(minKg: 20, maxKg: 50, label: '一袋大米', emoji: '🍚'),
  WeightComparison(minKg: 50, maxKg: 80, label: '一个成年人', emoji: '🧑'),
  WeightComparison(minKg: 80, maxKg: 120, label: '一只成年猩猩', emoji: '🦍'),
  WeightComparison(minKg: 120, maxKg: 180, label: '一只熊猫', emoji: '🐼'),
  WeightComparison(minKg: 180, maxKg: 250, label: '一辆摩托车', emoji: '🏍️'),
  WeightComparison(minKg: 250, maxKg: 400, label: '一头牛', emoji: '🐂'),
  WeightComparison(minKg: 400, maxKg: 600, label: '一匹马', emoji: '🐎'),
  WeightComparison(minKg: 600, maxKg: 1000, label: '一辆小汽车', emoji: '🚗'),
  WeightComparison(minKg: 1000, maxKg: 1500, label: '一头大象幼崽', emoji: '🐘'),
  WeightComparison(minKg: 1500, maxKg: double.infinity, label: '一辆小货车', emoji: '🚚'),
];
