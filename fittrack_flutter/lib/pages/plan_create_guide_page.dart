import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../themes/app_themes.dart';

/// 首次创建训练计划引导页
///
/// 首次进入"创建计划"时展示，帮助用户理解创建流程：
/// 命名计划 → 选择模板或从空开始 → 添加训练日与动作 → 保存开始训练。
class PlanCreateGuidePage extends StatefulWidget {
  const PlanCreateGuidePage({super.key});

  @override
  State<PlanCreateGuidePage> createState() => _PlanCreateGuidePageState();
}

class _PlanCreateGuidePageState extends State<PlanCreateGuidePage> {
  @override
  void initState() {
    super.initState();
    // 已展示过引导，后续不再弹出
    final s = Storage.getSettings();
    if (s['planGuideShown'] != true) {
      s['planGuideShown'] = true;
      Storage.saveSettings(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.accentGlow.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome, color: colors.accentGlow),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '3 步创建你的训练计划',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '从零开始也能轻松上手，快来看看怎么创建吧',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 28),
                    _buildStep(
                      colors,
                      step: '1',
                      icon: Icons.edit_outlined,
                      title: '给计划起个名字',
                      desc: '填写计划名称，如"增肌计划""减脂计划"，方便日后区分。',
                    ),
                    _buildStep(
                      colors,
                      step: '2',
                      icon: Icons.calendar_month_outlined,
                      title: '安排训练日与动作',
                      desc: '可以点击「训练类型」选择模板快速生成（三分化/四分化等），也可以从空开始：点右上角「+ 训练日」添加训练日，再点训练日内的「添加动作」选择动作并设置组数、次数、重量。',
                    ),
                    _buildStep(
                      colors,
                      step: '3',
                      icon: Icons.play_circle_outline,
                      title: '设置难度并保存',
                      desc: '选择难度等级与适用人群（全部/男性/女性），确认训练日安排后点击「创建计划」，即可开始训练。',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.infoColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.tips_and_updates_outlined, size: 18, color: colors.infoColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '小提示：保存后随时可以进入计划详情继续编辑训练日与动作。',
                              style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/add-plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('开始创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    LiftTrackColors colors, {
    required String step,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.accentGlow,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: colors.accentGlow),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
