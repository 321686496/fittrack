import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';

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

    // Primary recommendation based on goal and frequency
    if (goal == '增肌' && freqNum >= 4) {
      plans.add(_buildPlan(
        name: '五分化增肌计划',
        type: '五分化',
        frequency: '5天/周',
        difficulty: '进阶',
        totalWeeks: 8,
        desc: '针对有一定基础的训练者，每天专注一个肌群，最大化肌肉刺激与生长。',
        days: [
          {
            'day': 1,
            'label': '胸部',
            'muscle': '胸',
            'exercises': [
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'restTime': 60},
            ],
          },
          {
            'day': 2,
            'label': '背部',
            'muscle': '背',
            'exercises': [
              {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'restTime': 75},
              {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 60},
            ],
          },
          {
            'day': 3,
            'label': '腿部',
            'muscle': '腿',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
              {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
            ],
          },
          {
            'day': 4,
            'label': '肩部',
            'muscle': '肩',
            'exercises': [
              {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'restTime': 60},
            ],
          },
          {
            'day': 5,
            'label': '手臂 + 核心',
            'muscle': '手臂/核心',
            'exercises': [
              {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'restTime': 60},
              {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '60秒', 'restTime': 45},
              {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 45},
            ],
          },
        ],
      ));
    } else if (goal == '增肌' && freqNum < 4) {
      plans.add(_buildPlan(
        name: '三分化增肌计划',
        type: '三分化',
        frequency: '3天/周',
        difficulty: '中级',
        totalWeeks: 8,
        desc: '推拉腿三分化训练，每次训练覆盖多个肌群，适合时间有限的增肌者。',
        days: [
          {
            'day': 1,
            'label': '推（胸+肩+三头）',
            'muscle': '胸/肩',
            'exercises': [
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e3', 'name': '上斜卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '12-15', 'restTime': 60},
            ],
          },
          {
            'day': 2,
            'label': '拉（背+二头）',
            'muscle': '背',
            'exercises': [
              {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'restTime': 90},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
              {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '10-12', 'restTime': 60},
            ],
          },
          {
            'day': 3,
            'label': '腿（腿+核心）',
            'muscle': '腿',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 5, 'reps': '5-8', 'restTime': 120},
              {'id': 'e10', 'name': '腿举', 'sets': 4, 'reps': '10-12', 'restTime': 90},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'restTime': 45},
              {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 45},
            ],
          },
        ],
      ));
    } else if (goal == '减脂') {
      plans.add(_buildPlan(
        name: 'HIIT燃脂计划',
        type: 'HIIT',
        frequency: '3天/周',
        difficulty: '中级',
        totalWeeks: 6,
        desc: '高强度间歇训练结合力量动作，最大化燃脂效果，保留肌肉量。',
        days: [
          {
            'day': 1,
            'label': '上肢HIIT',
            'muscle': '上肢',
            'exercises': [
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '15', 'restTime': 30},
            ],
          },
          {
            'day': 2,
            'label': '下肢HIIT',
            'muscle': '腿',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 4, 'reps': '10-12', 'restTime': 60},
              {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'restTime': 30},
              {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 30},
            ],
          },
          {
            'day': 3,
            'label': '全身HIIT',
            'muscle': '全身',
            'exercises': [
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '15', 'restTime': 30},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '15', 'restTime': 30},
              {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '15', 'restTime': 30},
            ],
          },
        ],
      ));
    } else if (goal == '塑形') {
      plans.add(_buildPlan(
        name: '塑形美体计划',
        type: '塑形',
        frequency: '4天/周',
        difficulty: '中级',
        totalWeeks: 8,
        desc: '兼顾力量与有氧，重点塑造身体线条，打造匀称体态。',
        days: [
          {
            'day': 1,
            'label': '上肢塑形',
            'muscle': '上肢',
            'exercises': [
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '12-15', 'restTime': 60},
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '15', 'restTime': 45},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e12', 'name': '侧平举', 'sets': 3, 'reps': '15', 'restTime': 45},
            ],
          },
          {
            'day': 2,
            'label': '下肢塑形',
            'muscle': '腿',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 4, 'reps': '10-12', 'restTime': 90},
              {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '12-15', 'restTime': 60},
              {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 45},
            ],
          },
          {
            'day': 3,
            'label': '背部塑形',
            'muscle': '背',
            'exercises': [
              {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-12', 'restTime': 90},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'restTime': 60},
            ],
          },
          {
            'day': 4,
            'label': '核心 + 手臂',
            'muscle': '核心/手臂',
            'exercises': [
              {'id': 'e13', 'name': '哑铃弯举', 'sets': 3, 'reps': '12-15', 'restTime': 45},
              {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'restTime': 45},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '45秒', 'restTime': 30},
              {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'restTime': 30},
            ],
          },
        ],
      ));
    } else if (goal == '保持健康') {
      plans.add(_buildPlan(
        name: '全身健康计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '初级',
        totalWeeks: 6,
        desc: '全面均衡的全身训练，维持身体机能，提升整体健康水平。',
        days: [
          {
            'day': 1,
            'label': '全身训练A',
            'muscle': '全身',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'restTime': 90},
            ],
          },
          {
            'day': 2,
            'label': '全身训练B',
            'muscle': '全身',
            'exercises': [
              {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            ],
          },
          {
            'day': 3,
            'label': '全身训练C',
            'muscle': '全身',
            'exercises': [
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'restTime': 30},
            ],
          },
        ],
      ));
    }

    // Add beginner plan as second option if level is 新手/初级
    if (level == '新手' || level == '初级') {
      plans.add(_buildPlan(
        name: '新手入门计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '入门',
        totalWeeks: 4,
        desc: '从零开始的基础训练计划，动作简单安全，帮助建立运动习惯。',
        days: [
          {
            'day': 1,
            'label': '全身训练A',
            'muscle': '全身',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'restTime': 90},
            ],
          },
          {
            'day': 2,
            'label': '全身训练B',
            'muscle': '全身',
            'exercises': [
              {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            ],
          },
          {
            'day': 3,
            'label': '全身训练C',
            'muscle': '全身',
            'exercises': [
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'restTime': 30},
            ],
          },
        ],
      ));
    }

    // If no plans were generated (shouldn't happen), add a default
    if (plans.isEmpty) {
      plans.add(_buildPlan(
        name: '全身健康计划',
        type: '全身训练',
        frequency: '3天/周',
        difficulty: '初级',
        totalWeeks: 6,
        desc: '全面均衡的全身训练，维持身体机能，提升整体健康水平。',
        days: [
          {
            'day': 1,
            'label': '全身训练A',
            'muscle': '全身',
            'exercises': [
              {'id': 'e9', 'name': '杠铃深蹲', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e1', 'name': '杠铃卧推', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e5', 'name': '引体向上', 'sets': 3, 'reps': '8-10', 'restTime': 90},
            ],
          },
          {
            'day': 2,
            'label': '全身训练B',
            'muscle': '全身',
            'exercises': [
              {'id': 'e10', 'name': '腿举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e6', 'name': '杠铃划船', 'sets': 3, 'reps': '10-12', 'restTime': 90},
              {'id': 'e11', 'name': '哑铃推举', 'sets': 3, 'reps': '10-12', 'restTime': 90},
            ],
          },
          {
            'day': 3,
            'label': '全身训练C',
            'muscle': '全身',
            'exercises': [
              {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'restTime': 60},
              {'id': 'e7', 'name': '高位下拉', 'sets': 3, 'reps': '12', 'restTime': 75},
              {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '30秒', 'restTime': 30},
            ],
          },
        ],
      ));
    }

    setState(() {
      _recommendedPlans = plans;
    });
  }

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
    Storage.addPlan({
      ...plan,
      'status': 'active',
      'progress': 0,
      'week': 1,
      'badge': '进行中',
    });
    widget.onComplete();
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
            height: 44,
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
