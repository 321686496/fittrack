// lib/pages/plan_library_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/plan_unlock_service.dart';
import '../services/points_service.dart';
import '../themes/app_themes.dart';
import '../utils/art_assets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class PlanLibraryDetailPage extends StatefulWidget {
  final String planId;
  const PlanLibraryDetailPage({super.key, required this.planId});

  @override
  State<PlanLibraryDetailPage> createState() => _PlanLibraryDetailPageState();
}

class _PlanLibraryDetailPageState extends State<PlanLibraryDetailPage> {
  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    final plan = SystemPlanLibrary.instance.getById(widget.planId);

    if (plan == null) {
      return Scaffold(
        backgroundColor: ft.bgSecondary,
        body: Column(
          children: [
            PageHeader(
              title: '计划不存在',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text('计划不存在', style: TextStyle(color: ft.textSecondary)),
              ),
            ),
          ],
        ),
      );
    }

    final isUnlocked = !plan.isPremium ||
        PlanUnlockService.instance.isPlanUnlocked(plan.id);
    final unlockInfo = PlanUnlockService.instance.getUnlockInfo(plan.id);

    return Scaffold(
      backgroundColor: ft.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: plan.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(plan, ft),
                const SizedBox(height: 16),
                _buildStats(plan, ft),
                const SizedBox(height: 16),
                _buildDescription(plan, ft),
                const SizedBox(height: 16),
                if (isUnlocked)
                  _buildDays(plan, ft)
                else
                  _buildLockedDays(plan, ft),
                const SizedBox(height: 80), // 底部按钮空间
              ],
            ),
          ),
          _buildBottomBar(plan, isUnlocked, unlockInfo, ft),
        ],
      ),
    );
  }

  Widget _buildHeader(SystemPlan plan, LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: plan.coverColors
              .map((c) =>
                  Color(int.parse(c.substring(1), radix: 16) | 0xFF000000))
              .toList(),
        ),
      ),
      child: Stack(
        children: [
          // 目标主题封面美术（缺失时回退到渐变）
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                goalArtAsset(plan.goal) ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.65),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.coverEmoji, style: const TextStyle(fontSize: 48)),
                  const Spacer(),
                  if (plan.isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '精品计划',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                plan.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(SystemPlan plan, LiftTrackColors ft) {
    final List<MapEntry<String, String>> stats = [
      MapEntry('难度', kDifficultyLabelsZh[plan.difficulty] ?? plan.difficulty),
      MapEntry('类型', kTrainingTypeLabelsZh[plan.trainingType] ?? plan.trainingType),
      MapEntry('频率', '每周${plan.recommendedFrequency}练'),
      MapEntry('周期', '${plan.totalWeeks}周'),
      MapEntry('休息', '${plan.defaultRestTime}秒'),
      MapEntry('训练日', '${plan.days.length}天'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: stats
            .map((s) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.value,
                      style: TextStyle(
                        color: ft.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.key,
                      style: TextStyle(color: ft.textMuted, fontSize: 11),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDescription(SystemPlan plan, LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '计划说明',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.description,
            style: TextStyle(color: ft.textSecondary, fontSize: 14, height: 1.6),
          ),
          if (plan.suitableFor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '适合人群',
              style: TextStyle(
                color: ft.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plan.suitableFor,
              style: TextStyle(color: ft.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  /// 未解锁付费计划时的训练日占位卡片
  Widget _buildLockedDays(SystemPlan plan, LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ft.warningColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              color: ft.warningColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '解锁后查看完整训练安排',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '本计划共 ${plan.days.length} 个训练日，包含详细动作、组数次数与休息时间',
            style: TextStyle(color: ft.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '支付 ${plan.pointsCost} 积分解锁，90 天内可查看与使用',
            style: TextStyle(color: ft.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDays(SystemPlan plan, LiftTrackColors ft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ft.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '训练日安排',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.days.map((d) => _buildDayItem(d, ft)),
        ],
      ),
    );
  }

  Widget _buildDayItem(SystemPlanDay day, LiftTrackColors ft) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ft.purpleColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'D${day.day}',
                style: TextStyle(
                  color: ft.purpleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.label,
                  style: TextStyle(
                    color: ft.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${day.muscle} · ${day.exercises.length}个动作',
                  style: TextStyle(color: ft.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      children: [
        ...day.exercises.map((e) => Padding(
              padding: const EdgeInsets.only(
                left: 38,
                top: 4,
                bottom: 4,
                right: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.name,
                      style: TextStyle(color: ft.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${e.sets}×${e.reps}',
                    style: TextStyle(
                      color: ft.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${e.restTime}s',
                    style: TextStyle(color: ft.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildBottomBar(
    SystemPlan plan,
    bool isUnlocked,
    PlanUnlockInfo? unlockInfo,
    LiftTrackColors ft,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ft.bgCard,
        border: Border(top: BorderSide(color: ft.borderColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (plan.isPremium) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUnlocked && unlockInfo != null)
                      Text(
                        '剩余 ${unlockInfo.remainingDays} 天有效',
                        style: TextStyle(
                          color: ft.successColor,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        '当前积分: ${PointsService.instance.points}',
                        style: TextStyle(color: ft.textMuted, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? '已解锁'
                          : '需 ${plan.pointsCost} 积分解锁（90天有效）',
                      style: TextStyle(
                        color: isUnlocked ? ft.successColor : ft.warningColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: () => _handleAction(plan, isUnlocked),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUnlocked ? ft.purpleColor : ft.warningColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isUnlocked
                      ? '采用此计划'
                      : '支付 ${plan.pointsCost} 积分解锁',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(SystemPlan plan, bool isUnlocked) async {
    if (!isUnlocked) {
      // 解锁流程
      final result = await PlanUnlockService.instance.unlockPlan(
        plan.id,
        plan.pointsCost,
      );
      if (!mounted) return;
      switch (result) {
        case UnlockResult.success:
          FitToast.success(context, '解锁成功！90天内可使用此计划');
          setState(() {}); // 刷新 UI
          break;
        case UnlockResult.insufficientPoints:
          FitToast.error(
            context,
            '积分不足，还差 ${plan.pointsCost - PointsService.instance.points} 积分',
          );
          break;
        case UnlockResult.alreadyUnlocked:
          setState(() {});
          break;
        case UnlockResult.unknownPlan:
          FitToast.error(context, '计划不存在');
          break;
      }
      return;
    }

    // 已解锁（或免费计划）→ 采用
    await _adoptPlan(plan);
  }

  Future<void> _adoptPlan(SystemPlan plan) async {
    try {
      // 先进入重量确认页，用户确认/修改后返回 动作id → 重量
      final weights =
          await context.push<Map<String, double>>('/plan-weight-confirm',
              extra: plan);
      if (!mounted) return;
      if (weights == null) return; // 用户取消

      // 暂停现有 active 计划（await 确保持久化完成）
      final existingPlans = Storage.getPlans();
      for (final p in existingPlans) {
        if (p['status'] == 'active') {
          await Storage.updatePlanAsync(
              p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
        }
      }
      // 添加新计划（携带确认后的建议重量）
      final newPlan = plan.toStoragePlan(weights: weights);
      await Storage.addPlanAsync(newPlan);
      Storage.dataChanged.value = !Storage.dataChanged.value;

      if (!mounted) return;
      // 保存成功后跳转首页并提示用户可以开始训练
      FitToast.success(context, '已采用计划：${plan.name}，开始训练吧！');
      context.go('/home');
    } catch (e) {
      debugPrint('采用计划失败: $e');
      if (!mounted) return;
      FitToast.error(context, '采用计划失败，请重试');
    }
  }
}
