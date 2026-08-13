import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/invitation_service.dart';
import '../services/plan_recommendation_service.dart';
import '../services/plan_unlock_service.dart';
import '../widgets/common_widgets.dart';

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
  List<PlanRecommendation> _recommendedPlans = [];

  @override
  void initState() {
    super.initState();
    _recommendedPlans = _generateRecommendations();
  }

  List<PlanRecommendation> _generateRecommendations() {
    if (!SystemPlanLibrary.instance.isLoaded) return [];
    return PlanRecommendationService.instance.recommend(limit: 5);
  }

  Future<void> _selectPlan(PlanRecommendation rec) async {
    try {
      // 暂停现有 active 计划（await 确保持久化完成）
      final existingPlans = Storage.getPlans();
      for (final p in existingPlans) {
        if (p['status'] == 'active') {
          await Storage.updatePlanAsync(
              p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
        }
      }

      // 检查是否为精品计划且未解锁
      if (rec.plan.isPremium &&
          !PlanUnlockService.instance.isPlanUnlocked(rec.plan.id)) {
        // 跳转到详情页让用户解锁
        if (!mounted) return;
        context.push('/plan-library/detail/${rec.plan.id}');
        return;
      }

      // 添加新计划
      final newPlan = rec.plan.toStoragePlan();
      await Storage.addPlanAsync(newPlan);
      Storage.dataChanged.value = !Storage.dataChanged.value;

      widget.onComplete();
    } catch (e) {
      debugPrint('采用推荐计划失败: $e');
      if (!mounted) return;
      FitToast.error(context, '采用计划失败，请重试');
    }
  }

  /// v1 新手引导末尾：邀请码激活弹层
  void _showInviteCodeSheet() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
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
                                FitToast.info(ctx, '请输入邀请码');
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
                              if (success) {
                                FitToast.success(ctx, msg);
                              } else {
                                FitToast.error(ctx, msg);
                              }
                              if (success && ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

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
              child: _recommendedPlans.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          '计划库加载中，请稍后重试',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      itemCount: _recommendedPlans.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPlanCard(
                            colors,
                            _recommendedPlans[index],
                            index,
                          ),
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

  Widget _buildPlanCard(
    LiftTrackColors colors,
    PlanRecommendation rec,
    int index,
  ) {
    final isPrimary = index == 0;
    final plan = rec.plan;
    final exerciseCount = plan.days.fold<int>(
      0,
      (sum, day) => sum + day.exercises.length,
    );
    final matchPercent = (rec.score.clamp(0, 100)).round();

    // 难度 / 训练类型 / 目标 中文化
    final difficultyLabel =
        kDifficultyLabelsZh[plan.difficulty] ?? plan.difficulty;
    final typeLabel =
        kTrainingTypeLabelsZh[plan.trainingType] ?? plan.trainingType;
    final goalLabel = kGoalLabelsZh[plan.goal] ?? plan.goal;
    final frequencyLabel = '${plan.recommendedFrequency}天/周';

    // 按钮文案：精品未解锁 → "前往解锁"，否则 → "选择此计划"
    final isLocked =
        plan.isPremium && !PlanUnlockService.instance.isPlanUnlocked(plan.id);

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
          // Top badges row
          Row(
            children: [
              if (isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              if (isPrimary) const SizedBox(width: 8),
              if (plan.isPremium)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.accentGlow.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium,
                          size: 12, color: colors.accentGlow),
                      const SizedBox(width: 4),
                      Text(
                        isLocked
                            ? '精品 · 需${plan.pointsCost}积分解锁'
                            : '精品 · 已解锁',
                        style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (matchPercent > 0)
                Text(
                  '匹配度 $matchPercent%',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Plan name
          Text(
            plan.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            plan.description,
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
              _buildTag(colors, Icons.flag_outlined, goalLabel),
              _buildTag(colors, Icons.category_outlined, typeLabel),
              _buildTag(colors, Icons.repeat, frequencyLabel),
              _buildTag(colors, Icons.signal_cellular_alt, difficultyLabel),
              _buildTag(colors, Icons.fitness_center, '$exerciseCount个动作'),
              _buildTag(
                  colors, Icons.calendar_today, '${plan.totalWeeks}周'),
            ],
          ),
          // Recommendation reasons (最多 3 条)
          if (rec.reasons.isNotEmpty) ...[
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rec.reasons.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: colors.accentGlow),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Select button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => _selectPlan(rec),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isPrimary ? colors.accentGlow : colors.bgElevated,
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
              child: Text(
                isLocked ? '前往解锁' : '选择此计划',
                style: const TextStyle(
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

  Widget _buildTag(LiftTrackColors colors, IconData icon, String text) {
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
