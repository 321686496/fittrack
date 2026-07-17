import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/invitation_service.dart';

class PlanRecommendPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onComplete;

  const PlanRecommendPage({
    super.key,
    required this.profileData,
    required this.onComplete,
  });

  @override
  State<PlanRecommendPage> createState() => _PlanRecommendPageState();
}

class _PlanRecommendPageState extends State<PlanRecommendPage> {
  List<Map<String, dynamic>> _recommendedPlans = [];

  @override
  void initState() {
    super.initState();
    _generateRecommendations();
  }

  void _generateRecommendations() {
    final goal = widget.profileData['fitnessGoal'] as String? ?? '';
    final level = widget.profileData['fitnessLevel'] as String? ?? '';
    final frequency = widget.profileData['trainingFrequency'] as String? ?? '';

    final freqNum = int.tryParse(frequency.replaceAll(RegExp(r'[^0-9]'), '')) ?? 3;

    final plans = <Map<String, dynamic>>[];

    // === 计划1: 基于目标+频率的主推荐计划 ===
    if (goal == '增肌' && freqNum >= 4) {
      plans.add(_buildPlan(
        name: '五分化增肌计划',
        type: '五分化',
        frequency: '5天/周',
        difficulty: '进阶',
        totalWeeks: 8,
        desc: '针对有一定基础的训练者，每天专注一个肌群，最大化肌肉刺激与生长。',
        days: _fiveDaySplitDays(),
      ));
    } else if (goal == '增肌' && freqNum < 4) {
      plans.add(_buildPlan(
        name: '三分化增肌计划',
        type: '三分化',
        frequency: '3天/周',
        difficulty: '中级',
        totalWeeks: 8,
        desc: '推拉腿三分化训练，每次训练覆盖多个肌群，适合时间有限的增肌者。',
        days: _threeDaySplitDays(),
      ));
    } else if (goal == '减脂') {
      plans.add(_buildPlan(
        name: 'HIIT燃脂计划',
        type: 'HIIT',
        frequency: '3天/周',
        difficulty: '中级',
        totalWeeks: 6,
        desc: '高强度间歇训练结合力量动作，最大化燃脂效果，保留肌肉量。',
        days: _hiitDays(),
      ));
    } else if (goal == '塑形') {
      plans.add(_buildPlan(
        name: '塑形美体计划',
        type: '塑形',
        frequency: '4天/周',
        difficulty: '中级',
        totalWeeks: 8,
        desc: '兼顾力量与有氧，重点塑造身体线条，打造匀称体态。',
        days: _shapingDays(),
      ));
    } else {
      plans.add(_buildPlan(
        name: '全身健康计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '初级',
        totalWeeks: 6,
        desc: '全面均衡的全身训练，维持身体机能，提升整体健康水平。',
        days: _fullBodyDays(),
      ));
    }

    // === 计划2: 不同类型的备选计划 ===
    if (goal != '减脂') {
      plans.add(_buildPlan(
        name: 'HIIT燃脂计划',
        type: 'HIIT',
        frequency: '3天/周',
        difficulty: '中级',
        totalWeeks: 6,
        desc: '高强度间歇训练，快速燃烧脂肪，提升心肺能力。',
        days: _hiitDays(),
      ));
    }
    if (goal != '增肌' && freqNum >= 4) {
      plans.add(_buildPlan(
        name: '五分化增肌计划',
        type: '五分化',
        frequency: '5天/周',
        difficulty: '进阶',
        totalWeeks: 8,
        desc: '胸/背/腿/肩/手臂 五天循环，最大化肌肉刺激。',
        days: _fiveDaySplitDays(),
      ));
    }
    if (goal != '塑形' && freqNum < 4) {
      plans.add(_buildPlan(
        name: '塑形美体计划',
        type: '塑形',
        frequency: '4天/周',
        difficulty: '中级',
        totalWeeks: 8,
        desc: '兼顾力量与有氧，重点塑造身体线条。',
        days: _shapingDays(),
      ));
    }

    // === 计划3: 新手入门计划（适合所有用户） ===
    if (level == '新手' || level == '初级' || level.isEmpty) {
      plans.add(_buildPlan(
        name: '新手入门计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '入门',
        totalWeeks: 4,
        desc: '从零开始的基础训练计划，动作简单安全，帮助建立运动习惯。',
        days: _fullBodyDays(),
      ));
    }

    // === 计划4: 全身健康计划（兜底选项） ===
    if (plans.length < 3) {
      plans.add(_buildPlan(
        name: '全身健康计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '初级',
        totalWeeks: 6,
        desc: '全面均衡的全身训练，维持身体机能，提升整体健康水平。',
        days: _fullBodyDays(),
      ));
    }

    // 去重（按名称）
    final seen = <String>{};
    plans.removeWhere((p) {
      final name = p['name'] as String;
      if (seen.contains(name)) return true;
      seen.add(name);
      return false;
    });

    // 根据身体数据调整推荐顺序
    _reorderByBodyData(plans);

    setState(() {
      _recommendedPlans = plans;
    });
  }

  /// 根据身体数据（体脂率、目标体重、静息心率、BMI）调整推荐顺序
  void _reorderByBodyData(List<Map<String, dynamic>> plans) {
    if (plans.isEmpty) return;

    // 合并 profileData 和 Storage 中的身体数据
    final bodyData = <String, dynamic>{
      ...Storage.getBodyData(),
      ...widget.profileData,
    };
    final gender = bodyData['gender'] as String? ??
        Storage.getSettings()['gender'] as String? ??
        '';

    final bodyFat = (bodyData['bodyFat'] as num?)?.toDouble() ?? 0;
    final targetWeight = (bodyData['targetWeight'] as num?)?.toDouble() ?? 0;
    final currentWeight = (bodyData['weight'] as num?)?.toDouble() ?? 0;
    final restingHeartRate = (bodyData['restingHeartRate'] as num?)?.toDouble() ?? 0;
    final height = (bodyData['height'] as num?)?.toDouble() ?? 0;

    // 计算 BMI
    double bmi = 0;
    if (height > 0 && currentWeight > 0) {
      bmi = currentWeight / ((height / 100) * (height / 100));
    }

    // 判断条件
    final isHighBodyFat = bodyFat > 0 && (
        (gender == '女' && bodyFat > 30) ||
        (gender != '女' && bodyFat > 25));
    final isWeightLoss = targetWeight > 0 &&
        currentWeight > 0 &&
        targetWeight < currentWeight;
    final isHighHeartRate = restingHeartRate > 80;
    final isHighBMI = bmi > 28;

    // 无任何身体数据可用时，保持原顺序
    if (!isHighBodyFat && !isWeightLoss && !isHighHeartRate && !isHighBMI) {
      return;
    }

    // 为每个计划计算优先级分数
    int scoreOf(Map<String, dynamic> plan) {
      final name = plan['name'] as String? ?? '';
      final difficulty = plan['difficulty'] as String? ?? '';
      var score = 0;

      // 高体脂：优先 HIIT 燃脂
      if (isHighBodyFat && name.contains('HIIT')) score += 10;

      // 减重需求：优先 HIIT 或塑形
      if (isWeightLoss) {
        if (name.contains('HIIT')) score += 8;
        if (name.contains('塑形')) score += 5;
      }

      // 高 BMI：优先全身训练 + HIIT
      if (isHighBMI) {
        if (name.contains('全身')) score += 5;
        if (name.contains('HIIT')) score += 5;
      }

      // 高静息心率：优先入门级，避免高强度
      if (isHighHeartRate) {
        if (difficulty == '入门' || difficulty == '初级') score += 8;
        if (difficulty == '进阶' || difficulty == '高级') score -= 5;
      }

      return score;
    }

    // 按分数排序（保留原顺序作为 tiebreaker）
    final indexed = plans.asMap().entries.toList();
    indexed.sort((a, b) {
      final scoreA = scoreOf(a.value);
      final scoreB = scoreOf(b.value);
      if (scoreA != scoreB) return scoreB - scoreA; // 降序
      return a.key - b.key; // 原顺序
    });

    plans
      ..clear()
      ..addAll(indexed.map((e) => e.value));
  }

  // === 内置计划模板 ===

  List<Map<String, dynamic>> _fiveDaySplitDays() => [
    {
      'day': 1, 'label': '胸部', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'weight': 35.0, 'restTime': 90},
        {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'weight': 20.0, 'restTime': 60},
      ],
    },
    {
      'day': 2, 'label': '背部', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'weight': 35.0, 'restTime': 75},
        {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'weight': 30.0, 'restTime': 60},
      ],
    },
    {
      'day': 3, 'label': '腿部', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'weight': 50.0, 'restTime': 120},
        {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'weight': 80.0, 'restTime': 90},
      ],
    },
    {
      'day': 4, 'label': '肩部', 'muscle': '肩',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'weight': 8.0, 'restTime': 60},
      ],
    },
    {
      'day': 5, 'label': '手臂+核心', 'muscle': '手臂/核心',
      'exercises': [
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '60秒', 'weight': 0.0, 'restTime': 45},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 45},
      ],
    },
  ];

  List<Map<String, dynamic>> _threeDaySplitDays() => [
    {
      'day': 1, 'label': '推（胸+肩+三头）', 'muscle': '胸/肩',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 3, 'reps': '10-12', 'weight': 35.0, 'restTime': 90},
        {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'weight': 15.0, 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '12-15', 'weight': 8.0, 'restTime': 60},
      ],
    },
    {
      'day': 2, 'label': '拉（背+二头）', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'weight': 35.0, 'restTime': 75},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '10-12', 'weight': 10.0, 'restTime': 60},
      ],
    },
    {
      'day': 3, 'label': '腿（腿+核心）', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'weight': 50.0, 'restTime': 120},
        {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'weight': 80.0, 'restTime': 90},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'weight': 0.0, 'restTime': 45},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 45},
      ],
    },
  ];

  List<Map<String, dynamic>> _hiitDays() => [
    {
      'day': 1, 'label': '上肢HIIT', 'muscle': '上肢',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '12-15', 'weight': 40.0, 'restTime': 45},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '12-15', 'weight': 40.0, 'restTime': 45},
        {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '12-15', 'weight': 15.0, 'restTime': 45},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '15', 'weight': 10.0, 'restTime': 30},
      ],
    },
    {
      'day': 2, 'label': '下肢HIIT', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 4, 'reps': '10-12', 'weight': 50.0, 'restTime': 60},
        {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '12-15', 'weight': 80.0, 'restTime': 45},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'weight': 0.0, 'restTime': 30},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 30},
      ],
    },
    {
      'day': 3, 'label': '全身HIIT', 'muscle': '全身',
      'exercises': [
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '15', 'weight': 12.0, 'restTime': 30},
        {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12-15', 'weight': 35.0, 'restTime': 45},
        {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '15', 'weight': 8.0, 'restTime': 30},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '15', 'weight': 12.0, 'restTime': 30},
      ],
    },
  ];

  List<Map<String, dynamic>> _shapingDays() => [
    {
      'day': 1, 'label': '上肢塑形', 'muscle': '上肢',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '12-15', 'weight': 40.0, 'restTime': 60},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '15', 'weight': 12.0, 'restTime': 45},
        {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '12', 'weight': 15.0, 'restTime': 60},
        {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '15', 'weight': 8.0, 'restTime': 45},
      ],
    },
    {
      'day': 2, 'label': '下肢塑形', 'muscle': '腿',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 4, 'reps': '10-12', 'weight': 50.0, 'restTime': 90},
        {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '12-15', 'weight': 80.0, 'restTime': 60},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 45},
      ],
    },
    {
      'day': 3, 'label': '背部塑形', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-12', 'weight': 0.0, 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'weight': 35.0, 'restTime': 60},
        {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'weight': 30.0, 'restTime': 60},
      ],
    },
    {
      'day': 4, 'label': '核心+手臂', 'muscle': '核心/手臂',
      'exercises': [
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '12-15', 'weight': 10.0, 'restTime': 45},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 45},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'weight': 0.0, 'restTime': 30},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 30},
      ],
    },
  ];

  List<Map<String, dynamic>> _fullBodyDays() => [
    {
      'day': 1, 'label': '全身训练A', 'muscle': '全身',
      'exercises': [
        {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'weight': 50.0, 'restTime': 90},
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'weight': 0.0, 'restTime': 90},
      ],
    },
    {
      'day': 2, 'label': '全身训练B', 'muscle': '全身',
      'exercises': [
        {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'weight': 80.0, 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'weight': 15.0, 'restTime': 90},
      ],
    },
    {
      'day': 3, 'label': '全身训练C', 'muscle': '全身',
      'exercises': [
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
        {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'weight': 35.0, 'restTime': 75},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'weight': 0.0, 'restTime': 30},
      ],
    },
  ];

  Map<String, dynamic> _buildPlan({
    required String name,
    required String type,
    required String frequency,
    required String difficulty,
    required int totalWeeks,
    required String desc,
    required List<Map<String, dynamic>> days,
  }) {
    return {
      'name': name,
      'type': type,
      'frequency': frequency,
      'difficulty': difficulty,
      'totalWeeks': totalWeeks,
      'desc': desc,
      'days': days,
    };
  }

  void _selectPlan(Map<String, dynamic> plan) {
    // 先将现有活跃计划设为暂停
    final existingPlans = Storage.getPlans();
    for (final p in existingPlans) {
      if (p['status'] == 'active') {
        Storage.updatePlan(p['id'] as String, {...p, 'status': 'pending', 'badge': '待开始'});
      }
    }
    Storage.addPlan({
      ...plan,
      'status': 'active',
      'progress': 0,
      'week': 1,
      'badge': '进行中',
    });
    widget.onComplete();
  }

  /// v1 新手引导末尾：邀请码激活弹层
  void _showInviteCodeSheet() {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final controller = TextEditingController();
    bool activating = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgSecondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16, 12, 16,
                16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.card_giftcard,
                          size: 20, color: colors.accentGlow),
                      const SizedBox(width: 8),
                      Text(
                        '输入邀请码',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '输入好友的邀请码，激活后双方获得奖励',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9\-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'FIT-INV-XXXXXX',
                      hintStyle: TextStyle(
                          color: colors.textMuted, letterSpacing: 1),
                      filled: true,
                      fillColor: colors.bgCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: activating
                          ? null
                          : () async {
                              final code =
                                  controller.text.trim().toUpperCase();
                              if (code.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('请输入邀请码'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => activating = true);
                              final result = await InvitationService.instance
                                  .activateInvitationCode(code);
                              if (!ctx.mounted) return;
                              setSheetState(() => activating = false);

                              String msg;
                              bool success = false;
                              switch (result) {
                                case InvitationResult.success:
                                  msg = '激活成功！已获得7天高级统计全开放体验';
                                  success = true;
                                  break;
                                case InvitationResult.invalidFormat:
                                  msg = '格式错误：应为 FIT-INV-XXXXXX';
                                  break;
                                case InvitationResult.invalidSignature:
                                  msg = '邀请码无效，请检查后重试';
                                  break;
                                case InvitationResult.selfInvite:
                                  msg = '不能输入自己的邀请码哦';
                                  break;
                                case InvitationResult.alreadyActivated:
                                  msg = '你已激活过邀请码（一码一绑）';
                                  break;
                              }
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: success
                                      ? colors.successColor
                                      : colors.bgElevated,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              if (success && ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: activating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('立即激活',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '为你推荐',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '根据你的信息，我们为你精选了以下训练计划',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Plan list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                itemCount: _recommendedPlans.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPlanCard(colors, _recommendedPlans[index], index),
                  );
                },
              ),
            ),
            // Bottom actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.onComplete,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.accentGlow),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '自定义计划',
                        style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // v1 新手引导末尾：邀请码激活入口
                  TextButton.icon(
                    onPressed: _showInviteCodeSheet,
                    icon: Icon(Icons.card_giftcard_outlined,
                        size: 16, color: colors.accentGlow),
                    label: Text(
                      '我有邀请码',
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      '跳过',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(FitTrackColors colors, Map<String, dynamic> plan, int index) {
    final isPrimary = index == 0;
    final days = plan['days'] as List? ?? [];
    final exerciseCount = days.fold<int>(0, (sum, day) {
      final exercises = (day as Map<String, dynamic>)['exercises'] as List? ?? [];
      return sum + exercises.length;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary ? colors.accentGlow : colors.borderColor,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommended badge for first plan
          if (isPrimary)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '推荐',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          // Plan name
          Text(
            plan['name'] as String? ?? '',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            plan['desc'] as String? ?? '',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(colors, Icons.category_outlined, plan['type'] as String? ?? ''),
              _buildTag(colors, Icons.repeat, plan['frequency'] as String? ?? ''),
              _buildTag(colors, Icons.signal_cellular_alt, plan['difficulty'] as String? ?? ''),
              _buildTag(colors, Icons.fitness_center, '$exerciseCount个动作'),
            ],
          ),
          const SizedBox(height: 16),
          // Select button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _selectPlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? colors.accentGlow : colors.bgElevated,
                foregroundColor: isPrimary
                    ? (Theme.of(context).brightness == Brightness.dark
                        ? colors.textPrimary
                        : Colors.white)
                    : colors.accentGlow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isPrimary
                      ? BorderSide.none
                      : BorderSide(color: colors.accentGlow),
                ),
              ),
              child: const Text(
                '选择此计划',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(FitTrackColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
