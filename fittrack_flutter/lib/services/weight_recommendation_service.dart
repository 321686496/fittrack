// lib/services/weight_recommendation_service.dart
// 系统训练计划自动填充重量：动作分类 + 估算公式 + 历史匹配

enum ExerciseCategory {
  compoundPush, // 复合上肢推
  compoundPull, // 复合上肢拉
  compoundLeg, // 复合下肢
  isolationUpper, // 孤立上肢
  isolationLower, // 孤立下肢
  bodyweight, // 自重/有氧（不填重量）
}

enum WeightSource {
  history, // 历史记录
  estimate, // 估算
  bodyweight, // 自重
}

class ExerciseWeightSuggestion {
  final double? weight; // 自重动作为 null
  final WeightSource source;

  const ExerciseWeightSuggestion({this.weight, required this.source});
}

// ── 类别基础占比（入门男性，体重百分比）──
const Map<ExerciseCategory, double> _categoryRatio = {
  ExerciseCategory.compoundPush: 0.45,
  ExerciseCategory.compoundPull: 0.40,
  ExerciseCategory.compoundLeg: 0.70,
  ExerciseCategory.isolationUpper: 0.12,
  ExerciseCategory.isolationLower: 0.15,
  ExerciseCategory.bodyweight: 0.0,
};

// ── 水平系数（settings['fitnessLevel'] 实际值）──
const Map<String, double> _levelMultiplier = {
  '新手': 1.0,
  '初级': 1.15,
  '中级': 1.30,
  '高级': 1.45,
};

const double _defaultBodyWeight = 65.0; // 身体数据缺失时的默认体重
const double _minWeight = 2.5;
const double _compoundMax = 150.0;
const double _isolationMax = 50.0;

/// 动作分类：按关键词命中顺序判断（自重/有氧 → 复合下肢 → 复合上肢推 → 复合上肢拉 → 孤立下肢 → 孤立上肢）
ExerciseCategory classifyExercise(String name) {
  final n = name.replaceAll(RegExp(r'\s+'), '');
  // 自重/有氧（优先，避免"自重深蹲"误入复合下肢等）
  const bodyweightKeywords = [
    '自重深蹲', '俯卧撑', '引体向上', '卷腹', '平板支撑', '波比跳', '俄罗斯转体',
    '悬垂举腿', '仰卧举腿', '开合跳', '高抬腿', '登山跑', '鸟狗式', '死虫式',
    '深蹲跳', '箭步跳', '慢跑', '游泳', '动感单车', '椭圆机', '战绳', '农夫行走',
    '跳箱', '药球',
  ];
  for (final k in bodyweightKeywords) {
    if (n.contains(k)) return ExerciseCategory.bodyweight;
  }
  // 复合下肢
  const legKeywords = ['前蹲', '深蹲', '硬拉', '腿举', '箭步蹲', '弓步蹲', '保加利亚分腿蹲', '壶铃摆动', '力量翻', '箱式深蹲'];
  for (final k in legKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundLeg;
  }
  // 复合上肢推
  const pushKeywords = ['卧推', '推举', '实力举', '双杠臂屈伸', '阿诺德'];
  for (final k in pushKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundPush;
  }
  // 复合上肢拉（"直臂下压"用全称，避免误吞孤立"三头肌下压"）
  const pullKeywords = ['下拉', '划船', '直臂下压'];
  for (final k in pullKeywords) {
    if (n.contains(k)) return ExerciseCategory.compoundPull;
  }
  // 孤立下肢（"腿弯举"需在孤立上肢"弯举"之前判断）
  const isoLegKeywords = ['腿弯举', '腿屈伸', '提踵', '臀桥', '山羊挺身'];
  for (final k in isoLegKeywords) {
    if (n.contains(k)) return ExerciseCategory.isolationLower;
  }
  // 孤立上肢（未命中默认归入此类）
  const isoUpperKeywords = ['下压', '夹胸', '飞鸟', '平举', '面拉', '弯举', '臂屈伸', '三头', '法式推举'];
  for (final k in isoUpperKeywords) {
    if (n.contains(k)) return ExerciseCategory.isolationUpper;
  }
  return ExerciseCategory.isolationUpper;
}

/// 估算建议重量：体重 × 类别占比 × 水平系数 × 性别系数，取整到 2.5kg，并施加上下限
double estimateWeight({
  required double bodyWeight,
  required ExerciseCategory category,
  required String fitnessLevel,
  required String gender,
}) {
  final ratio = _categoryRatio[category] ?? 0.12;
  final level = _levelMultiplier[fitnessLevel] ?? 1.0;
  final genderMultiplier = gender == '女' ? 0.70 : 1.0;
  var v = bodyWeight * ratio * level * genderMultiplier;
  // 取整到 2.5kg
  v = (v / 2.5).round() * 2.5;
  if (v < _minWeight) v = _minWeight;
  final maxW = (category == ExerciseCategory.compoundPush ||
          category == ExerciseCategory.compoundPull ||
          category == ExerciseCategory.compoundLeg)
      ? _compoundMax
      : _isolationMax;
  if (v > maxW) v = maxW;
  return v;
}

class WeightRecommendationService {
  WeightRecommendationService._();
  static final WeightRecommendationService instance =
      WeightRecommendationService._();
}