import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../data/system_plan_library.dart';
import '../services/plan_recommendation_service.dart';
import '../services/plan_unlock_service.dart';
import '../utils/art_assets.dart';
import '../utils/gender_filter.dart';
import '../widgets/common_widgets.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/exercise_set_table.dart';
import '../widgets/page_header.dart';
import '../widgets/tab_refresh_mixin.dart';

// ============================================================
// Quick setup templates for auto-generating plan days
// ============================================================
const Map<String, List<Map<String, dynamic>>> _quickSetup = {
  '三分化': [
    {
      'day': 1, 'label': '胸部 + 三头肌', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'weight': 35.0, 'restTime': 90},
        {'id': 'e4', 'name': '绳索夹胸', 'sets': 3, 'reps': '15', 'weight': 20.0, 'restTime': 60},
      ],
    },
    {
      'day': 2, 'label': '背部 + 二头肌', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'weight': 35.0, 'restTime': 75},
        {'id': 'e8', 'name': '坐姿划船', 'sets': 3, 'reps': '12', 'weight': 30.0, 'restTime': 60},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
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
      'day': 4, 'label': '肩部 + 核心', 'muscle': '肩',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'weight': 8.0, 'restTime': 60},
        {'id': 'e15', 'name': '平板支撑', 'sets': 3, 'reps': '60秒', 'weight': 0.0, 'restTime': 45},
        {'id': 'e16', 'name': '卷腹', 'sets': 3, 'reps': '20', 'weight': 0.0, 'restTime': 45},
      ],
    },
    {
      'day': 5, 'label': '胸部 + 背部', 'muscle': '胸/背',
      'exercises': <Map<String, dynamic>>[],
    },
    {
      'day': 6, 'label': '腿部 + 手臂', 'muscle': '腿/手臂',
      'exercises': <Map<String, dynamic>>[],
    },
  ],
  '四分化': [
    {
      'day': 1, 'label': '胸部', 'muscle': '胸',
      'exercises': [
        {'id': 'e1', 'name': '杠铃卧推', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e2', 'name': '哑铃飞鸟', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
        {'id': 'e3', 'name': '上斜卧推', 'sets': 4, 'reps': '8-12', 'weight': 35.0, 'restTime': 90},
      ],
    },
    {
      'day': 2, 'label': '背部', 'muscle': '背',
      'exercises': [
        {'id': 'e5', 'name': '引体向上', 'sets': 4, 'reps': '8-12', 'weight': 0.0, 'restTime': 90},
        {'id': 'e6', 'name': '杠铃划船', 'sets': 4, 'reps': '8-12', 'weight': 40.0, 'restTime': 90},
        {'id': 'e7', 'name': '高位下拉', 'sets': 4, 'reps': '12', 'weight': 35.0, 'restTime': 75},
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
      'day': 4, 'label': '肩部 + 手臂', 'muscle': '肩/手臂',
      'exercises': [
        {'id': 'e11', 'name': '哑铃推举', 'sets': 4, 'reps': '8-12', 'weight': 15.0, 'restTime': 90},
        {'id': 'e12', 'name': '侧平举', 'sets': 4, 'reps': '12-15', 'weight': 8.0, 'restTime': 60},
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60},
      ],
    },
  ],
  '五分化': [
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
      'day': 5, 'label': '手臂', 'muscle': '手臂',
      'exercises': [
        {'id': 'e13', 'name': '哑铃弯举', 'sets': 4, 'reps': '10-12', 'weight': 10.0, 'restTime': 60},
        {'id': 'e14', 'name': '锤式弯举', 'sets': 3, 'reps': '12', 'weight': 12.0, 'restTime': 60},
      ],
    },
  ],
  '全身训练': [
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
  ],
};

const List<String> _planTypes = ['三分化', '四分化', '五分化', '全身训练', '自定义'];
const List<String> _difficulties = ['入门', '初级', '进阶', '高级'];

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> with TabRefreshMixin<PlanPage> {
  List<Map<String, dynamic>> _plans = [];
  // build 内重计算缓存（在 _loadPlans 中预计算）
  List<Map<String, dynamic>> _activePlansCache = const [];
  List<Map<String, dynamic>> _customSortedCache = const [];

  @override
  int get tabIndex => 1;

  @override
  void onTabBecameActive() {
    _loadPlans();
  }

  @override
  void initState() {
    super.initState();
    _loadPlans();
    Storage.dataChanged.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    Storage.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    _loadPlans();
  }

  void _loadPlans() {
    _plans = Storage.getPlans();
    _activePlansCache = _plans
        .where((p) => p['status'] == 'active' && _planMatchesGender(p))
        .toList();
    _customSortedCache = _sortCustomPlans(
      _plans.where((p) => _planMatchesGender(p)).toList(),
    );
    if (mounted) setState(() {});
  }

  /// 判断计划是否匹配用户性别（问卷未填性别时全部可见）
  bool _planMatchesGender(Map<String, dynamic> plan) {
    final gender = plan['gender'] as String? ?? 'all';
    return genderMatchesUser(gender);
  }

  bool _systemPlanMatchesGender(SystemPlan plan) {
    return genderMatchesUser(plan.gender);
  }

  List<Map<String, dynamic>> get _activePlans => _activePlansCache;

  void _deletePlan(String planId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '确认删除',
      content: '删除后无法恢复，确定要删除这个计划吗？',
      confirmText: '删除',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline_rounded,
    );
    if (confirmed == true) {
      Storage.deletePlan(planId);
      _loadPlans();
    }
  }

  void _showPlanEditor({Map<String, dynamic>? existingPlan}) {
    if (existingPlan != null) {
      // 编辑模式：使用弹窗编辑详细天数
      FitBottomSheet.show(
        context: context,
        maxHeightRatio: 0.85,
        builder: (ctx) => _PlanEditorSheet(
          existingPlan: existingPlan,
          onSave: (planData) async {
            await Storage.updatePlanAsync(
                existingPlan['id'] as String, planData);
            _loadPlans();
            if (ctx.mounted) Navigator.of(ctx).pop();
            // 保存成功后跳转首页并提示用户可以开始训练
            if (!mounted) return;
            FitToast.success(context, '计划已更新，开始训练吧！');
            context.go('/home');
          },
        ),
      );
    } else {
      // 新建模式：跳转到独立添加页面（含推荐）
      final settings = Storage.getSettings();
      final isFirstTime = settings['planGuideShown'] != true && Storage.getPlans().isEmpty;
      if (isFirstTime) {
        context.push('/plan-guide');
      } else {
        context.push('/add-plan');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            title: '训练计划',
            isTabPage: true,
          ),
          Expanded(
            child: _buildPlanList(colors),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: FloatingActionButton(
          onPressed: () => _showPlanEditor(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // ── Plan List View ─────────────────────────────────────────

  Widget _buildPlanList(LiftTrackColors colors) {
    // 使用 _loadPlans 中预计算的缓存，避免 build 内深拷贝 records
    final customSorted = _customSortedCache;
    final top3 = customSorted.take(3).toList();

    return RefreshIndicator(
      color: colors.accentGlow,
      backgroundColor: colors.bgCard,
      onRefresh: () async {
        _loadPlans();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 第一段：当前训练计划 ─────────────────────────────
            if (_activePlans.isNotEmpty) ...[
              const SectionHeader(title: '进行中的计划'),
              const SizedBox(height: 12),
              ..._activePlans.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPlanCard(colors, plan),
                  )),
              const SizedBox(height: 8),
            ],
            // ── 第二段：自定义计划 Top 3 ─────────────────────────
            if (top3.isNotEmpty) ...[
              SectionHeader(
                title: _activePlans.isNotEmpty ? '我的计划' : '自定义计划',
              ),
              const SizedBox(height: 12),
              ...top3.map((plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPlanCard(colors, plan),
                  )),
            ],
            // ── 第三段：推荐计划（始终展示）─────────────────────
            _buildRecommendedSection(),
            const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  /// 自定义计划排序：创建时间 30% + 使用次数 70%
  /// 排除已在"进行中的计划"展示的活跃计划，避免重复显示
  List<Map<String, dynamic>> _sortCustomPlans(List<Map<String, dynamic>> plans) {
    // 排除来自系统库的计划（有 sourcePlanId 的）和活跃计划（已在上方展示）
    final customPlans = plans.where((p) =>
        p['sourcePlanId'] == null && p['status'] != 'active').toList();
    final records = Storage.getRecords();

    // 计算每个计划的使用次数
    final useCount = <String, int>{};
    for (final r in records) {
      final planId = r['planId'] as String? ?? r['sourcePlanId'] as String?;
      if (planId != null) {
        useCount[planId] = (useCount[planId] ?? 0) + 1;
      }
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final scored = customPlans.map((p) {
      final planId = p['id'] as String;
      final createTime = (p['createTime'] as num?)?.toInt() ?? now;
      final daysSinceCreated = ((now - createTime) / (24 * 60 * 60 * 1000)).clamp(0, 365);
      // 创建时间越近分数越高（归一化到 0-30）
      final timeScore = (30 * (1 - daysSinceCreated / 365)).clamp(0.0, 30.0);
      // 使用次数归一化到 0-70
      final count = useCount[planId] ?? 0;
      final maxCount = useCount.values.fold(0, (a, b) => a > b ? a : b);
      final useScore = maxCount > 0 ? (70 * count / maxCount) : 0.0;
      return {'plan': p, 'score': timeScore + useScore};
    }).toList();

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    return scored.map((e) => e['plan'] as Map<String, dynamic>).toList();
  }

  /// 推荐区段：标题 + 3 个推荐卡片 + 浏览系统计划库按钮
  Widget _buildRecommendedSection() {
    if (!SystemPlanLibrary.instance.isLoaded) {
      return const SizedBox.shrink();
    }
    final recommendations = PlanRecommendationService.instance
        .recommend(limit: 12)
        .where((r) => _systemPlanMatchesGender(r.plan))
        .take(3)
        .toList();
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final ft = Theme.of(context).extension<LiftTrackColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
          child: Row(
            children: [
              Text(
                '为你推荐',
                style: TextStyle(
                  color: ft.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/plan-library'),
                child: Row(
                  children: [
                    Text(
                      '全部系统计划',
                      style: TextStyle(color: ft.purpleColor, fontSize: 13),
                    ),
                    Icon(Icons.chevron_right, color: ft.purpleColor, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...recommendations.map((r) => _buildRecommendationCard(r, ft)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/plan-library'),
              icon: const Icon(Icons.library_books),
              label: const Text('浏览系统计划库'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ft.purpleColor,
                side: BorderSide(color: ft.purpleColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 单个推荐卡片
  Widget _buildRecommendationCard(PlanRecommendation rec, LiftTrackColors ft) {
    final plan = rec.plan;
    final isUnlocked = !plan.isPremium ||
        PlanUnlockService.instance.isPlanUnlocked(plan.id);
    return GestureDetector(
      onTap: () => context.push('/plan-library/detail/${plan.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ft.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ft.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                goalArtAsset(plan.goal) ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: plan.coverColors
                          .map((c) => Color(int.parse(c.substring(1), radix: 16) | 0xFF000000))
                          .toList(),
                    ),
                  ),
                  child: Center(
                    child: Text(plan.coverEmoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                            color: ft.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (plan.isPremium && !isUnlocked)
                        Icon(Icons.lock, size: 14, color: ft.warningColor),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (rec.reasons.isNotEmpty)
                    Text(
                      rec.reasons.first,
                      style: TextStyle(color: ft.textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text(
                  '${rec.score.toInt()}%',
                  style: TextStyle(
                    color: ft.successColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('匹配', style: TextStyle(color: ft.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(LiftTrackColors colors, Map<String, dynamic> plan) {
    final progress = ((plan['progress'] as num? ?? 0) / 100.0).clamp(0.0, 1.0);
    final status = plan['status'] as String? ?? 'pending';
    final badgeText = plan['badge'] as String? ?? _statusLabel(status);
    final planId = plan['id'] as String;

    BadgeVariant badgeVariant;
    switch (status) {
      case 'active':
        badgeVariant = BadgeVariant.accent;
        break;
      case 'done':
        badgeVariant = BadgeVariant.success;
        break;
      default:
        badgeVariant = BadgeVariant.info;
    }

    return CardWidget(
      onTap: () => context.push('/plan/${plan['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${plan['name']}',
                  style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              BadgeWidget(text: badgeText, variant: badgeVariant),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${plan['frequency'] ?? ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Text(
                '${plan['difficulty'] ?? ''}',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Text(
                '第${plan['week'] ?? 0}/${plan['totalWeeks'] ?? 0}周',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(progress: progress),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(color: colors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          // ── 操作按钮行：暂停/切换/删除 ──────────────────────
          Row(
            children: [
              if (status == 'active') ...[
                _buildPlanActionButton(
                  colors,
                  icon: Icons.pause_circle_outline,
                  label: '暂停',
                  onTap: () => _pausePlan(planId),
                ),
                const SizedBox(width: 8),
              ] else if (status == 'paused' || status == 'pending') ...[
                _buildPlanActionButton(
                  colors,
                  icon: Icons.play_circle_outline,
                  label: '切换为此计划',
                  primary: true,
                  onTap: () => _switchToPlan(planId),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              _buildPlanActionButton(
                colors,
                icon: Icons.delete_outline,
                label: '删除',
                danger: true,
                onTap: () => _deletePlan(planId),
              ),
              const SizedBox(width: 8),
              _buildPlanActionButton(
                colors,
                icon: Icons.share_outlined,
                label: '分享',
                onTap: () => _showShareMenu(colors, plan),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShareMenu(LiftTrackColors colors, Map<String, dynamic> plan) {
    final planId = plan['id'] as String?;
    if (planId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '分享「${plan['name'] ?? '计划'}」',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.qr_code_2, color: colors.accentGlow),
              title: Text('生成分享码', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              onTap: () { Navigator.pop(ctx); context.push('/share-code'); },
            ),
            ListTile(
              leading: Icon(Icons.qr_code, color: colors.accentGlow),
              title: Text('生成二维码', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              onTap: () { Navigator.pop(ctx); context.push('/plan-qr/$planId'); },
            ),
            ListTile(
              leading: Icon(Icons.image_outlined, color: colors.accentGlow),
              title: Text('生成海报', style: TextStyle(color: colors.textPrimary, fontSize: 14)),
              trailing: Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              onTap: () { Navigator.pop(ctx); context.push('/plan-poster/$planId'); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建计划操作按钮
  Widget _buildPlanActionButton(
    LiftTrackColors colors, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
    bool danger = false,
  }) {
    Color btnColor;
    Color bgColor;
    if (danger) {
      btnColor = Colors.redAccent;
      bgColor = Colors.redAccent.withOpacity(0.1);
    } else if (primary) {
      btnColor = colors.accentGlow;
      bgColor = colors.accentGlow.withOpacity(0.12);
    } else {
      btnColor = colors.textSecondary;
      bgColor = colors.bgSecondary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: btnColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: btnColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: btnColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 暂停计划
  void _pausePlan(String planId) async {
    await Storage.updatePlanAsync(planId, {'status': 'paused', 'badge': '已暂停'});
    _loadPlans();
    if (mounted) FitToast.success(context, '计划已暂停');
  }

  /// 切换到指定计划（暂停其他活跃计划，激活该计划）
  void _switchToPlan(String planId) async {
    // 先暂停其他活跃计划
    for (final p in _plans) {
      if (p['id'] != planId && p['status'] == 'active') {
        await Storage.updatePlanAsync(
            p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
      }
    }
    // 激活目标计划
    await Storage.updatePlanAsync(planId, {'status': 'active', 'badge': '进行中'});
    _loadPlans();
    if (mounted) FitToast.success(context, '已切换训练计划');
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return '进行中';
      case 'done':
        return '已完成';
      case 'pending':
        return '待开始';
      case 'paused':
        return '已暂停';
      default:
        return status;
    }
  }

}

// ============================================================
// Plan Editor Bottom Sheet
// ============================================================

class _PlanEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? existingPlan;
  final void Function(Map<String, dynamic> data) onSave;

  const _PlanEditorSheet({
    this.existingPlan,
    required this.onSave,
  });

  @override
  State<_PlanEditorSheet> createState() => _PlanEditorSheetState();
}

class _PlanEditorSheetState extends State<_PlanEditorSheet> {
  late TextEditingController _nameController;
  String _selectedType = '三分化';
  String _selectedDifficulty = '进阶';
  late TextEditingController _totalWeeksController;
  late TextEditingController _restTimeController;
  List<Map<String, dynamic>> _days = [];

  // 缓存每个训练日的 label 控制器，避免在 build 中重复创建
  final Map<int, TextEditingController> _labelControllers = {};

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPlan;
    _nameController = TextEditingController(text: existing?['name'] as String? ?? '');
    _selectedType = existing?['type'] as String? ?? '三分化';
    _selectedDifficulty = existing?['difficulty'] as String? ?? '进阶';
    _totalWeeksController = TextEditingController(
      text: '${existing?['totalWeeks'] ?? 8}',
    );
    _restTimeController = TextEditingController(
      text: '${existing?['defaultRestTime'] ?? 90}',
    );

    if (existing != null && existing['days'] is List) {
      _days = (existing['days'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      _applyQuickSetup(_selectedType);
    }
    // 初始化 label 控制器
    _syncLabelControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalWeeksController.dispose();
    _restTimeController.dispose();
    for (final ctrl in _labelControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _syncLabelControllers() {
    // 为每个 day 创建/更新控制器
    for (int i = 0; i < _days.length; i++) {
      if (!_labelControllers.containsKey(i)) {
        _labelControllers[i] = TextEditingController(
          text: '${_days[i]['label'] ?? ''}',
        );
      }
    }
    // 清理多余的控制器
    final keysToRemove = _labelControllers.keys.where((k) => k >= _days.length).toList();
    for (final k in keysToRemove) {
      _labelControllers[k]!.dispose();
      _labelControllers.remove(k);
    }
  }

  void _applyQuickSetup(String type) {
    if (type == '自定义') {
      _days = [
        {'day': 1, 'label': '训练日1', 'muscle': '', 'exercises': <Map<String, dynamic>>[]},
      ];
    } else {
      final template = _quickSetup[type];
      if (template != null) {
        _days = template.map((d) {
          final map = Map<String, dynamic>.from(d);
          // 深拷贝 exercises 列表，避免 unmodifiable list
          final exs = map['exercises'];
          if (exs is List) {
            map['exercises'] = exs
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          return map;
        }).toList();
      }
    }
    _syncLabelControllers();
    setState(() {});
  }

  void _addDay() {
    _days.add({
      'day': _days.length + 1,
      'label': '训练日${_days.length + 1}',
      'muscle': '',
      'exercises': <Map<String, dynamic>>[],
    });
    _syncLabelControllers();
    setState(() {});
  }

  void _addRestDay() {
    _days.add({
      'day': _days.length + 1,
      'label': '休息日',
      'muscle': '',
      'isRest': true,
      'exercises': <Map<String, dynamic>>[],
    });
    _syncLabelControllers();
    setState(() {});
  }

  void _removeDay(int index) {
    _days.removeAt(index);
    for (int i = 0; i < _days.length; i++) {
      _days[i]['day'] = i + 1;
    }
    _syncLabelControllers();
    setState(() {});
  }

  void _addExercise(int dayIndex) {
    final settings = Storage.getSettings();
    final defaultSets = (settings['defaultSets'] as num?)?.toInt() ?? 3;
    final defaultReps = (settings['defaultReps'] as num?)?.toInt() ?? 10;
    final defaultWeight = (settings['defaultWeight'] as num?)?.toDouble() ?? 20.0;
    final defaultRestTime = (settings['defaultRestTime'] as num?)?.toInt() ?? 90;

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.7,
      builder: (ctx) => ExercisePickerSheet(
        defaultSets: defaultSets,
        defaultReps: defaultReps,
        defaultWeight: defaultWeight,
        defaultRestTime: defaultRestTime,
        onPick: (exercise, sets, reps, weight, restTime, setConfig) {
          final existing = _days[dayIndex]['exercises'];
          final exercises = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          final newEx = {
            'id': exercise['id'],
            'name': exercise['name'],
            'sets': sets,
            'reps': reps,
            'weight': weight,
            'restTime': restTime,
          };
          if (setConfig != null) {
            newEx['setConfig'] = setConfig;
          }
          exercises.add(newEx);
          _days[dayIndex]['exercises'] = exercises;
          setState(() {});
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _removeExercise(int dayIndex, int exIndex) {
    final existing = _days[dayIndex]['exercises'];
    final exercises = (existing is List)
        ? List<Map<String, dynamic>>.from(
            existing.map((e) => Map<String, dynamic>.from(e as Map)))
        : <Map<String, dynamic>>[];
    if (exIndex < exercises.length) {
      exercises.removeAt(exIndex);
      _days[dayIndex]['exercises'] = exercises;
      setState(() {});
    }
  }

  // 编辑指定训练日中的动作：弹出 ExercisePickerSheet 并预填当前参数
  void _editExercise(int dayIndex, int exIndex) {
    final exercises = _days[dayIndex]['exercises'] as List? ?? [];
    if (exIndex >= exercises.length) return;
    final ex = Map<String, dynamic>.from(exercises[exIndex] as Map);

    final setConfigRaw = ex['setConfig'] as List?;
    final initialSetConfig = setConfigRaw
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList()
        .cast<Map<String, dynamic>>();

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.7,
      builder: (ctx) => ExercisePickerSheet(
        defaultSets: (ex['sets'] as num?)?.toInt() ?? 3,
        defaultReps: int.tryParse(ex['reps']?.toString() ?? '10') ?? 10,
        defaultWeight: (ex['weight'] as num?)?.toDouble() ?? 20.0,
        defaultRestTime: (ex['restTime'] as num?)?.toInt() ?? 90,
        initialExercise: Storage.getAllExercises().firstWhere(
          (e) => e['id'] == ex['id'],
          orElse: () => {'id': ex['id'], 'name': ex['name'], 'category': '', 'equip': ''},
        ),
        initialSetConfig: initialSetConfig,
        onPick: (exercise, sets, reps, weight, restTime, setConfig) {
          final existing = _days[dayIndex]['exercises'];
          final exList = (existing is List)
              ? List<Map<String, dynamic>>.from(
                  existing.map((e) => Map<String, dynamic>.from(e as Map)))
              : <Map<String, dynamic>>[];
          if (exIndex < exList.length) {
            final updated = {
              'id': exercise['id'],
              'name': exercise['name'],
              'sets': sets,
              'reps': reps,
              'weight': weight,
              'restTime': restTime,
            };
            if (setConfig != null) {
              updated['setConfig'] = setConfig;
            }
            exList[exIndex] = updated;
          }
          _days[dayIndex]['exercises'] = exList;
          setState(() {});
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      FitToast.warning(context, '请输入计划名称');
      return;
    }

    final totalWeeks = int.tryParse(_totalWeeksController.text) ?? 8;
    final restTime = int.tryParse(_restTimeController.text) ?? 90;

    String frequency;
    switch (_selectedType) {
      case '三分化':
        frequency = '6天/周';
        break;
      case '四分化':
        frequency = '4天/周';
        break;
      case '五分化':
        frequency = '5天/周';
        break;
      case '全身训练':
        frequency = '3天/周';
        break;
      default:
        frequency = '${_days.length}天/周';
    }

    if (widget.existingPlan == null) {
      // 新建计划时，暂停其他活跃计划（await 确保持久化）
      final existingPlans = Storage.getPlans();
      for (final p in existingPlans) {
        if (p['status'] == 'active') {
          await Storage.updatePlanAsync(
              p['id'] as String, {'status': 'paused', 'badge': '已暂停'});
        }
      }
    }
    widget.onSave({
      'name': _nameController.text.trim(),
      'type': _selectedType,
      'frequency': frequency,
      'difficulty': _selectedDifficulty,
      'totalWeeks': totalWeeks,
      'defaultRestTime': restTime,
      'days': _days,
      'currentDayIndex': widget.existingPlan?['currentDayIndex'] ?? 0,
      'week': widget.existingPlan?['week'] ?? 0,
      'progress': widget.existingPlan?['progress'] ?? 0,
      'status': widget.existingPlan?['status'] ?? 'active',
      'badge': widget.existingPlan?['badge'] ?? '进行中',
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  widget.existingPlan != null ? '编辑计划' : '创建计划',
                  style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  _buildLabel(colors, '计划名称'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: const InputDecoration(hintText: '输入计划名称'),
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  _buildLabel(colors, '训练类型'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _planTypes.map((type) {
                      final isSelected = type == _selectedType;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = type);
                          _applyQuickSetup(type);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Difficulty selector
                  _buildLabel(colors, '难度等级'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _difficulties.map((diff) {
                      final isSelected = diff == _selectedDifficulty;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDifficulty = diff),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.15) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            diff,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Total weeks & Rest time
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, '总周数'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _totalWeeksController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: const InputDecoration(hintText: '8'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(colors, '默认休息(秒)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _restTimeController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: colors.textPrimary),
                              decoration: const InputDecoration(hintText: '90'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Days editor
                  Row(
                    children: [
                      _buildLabel(colors, '训练日'),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addDay,
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 18, color: colors.accentGlow),
                            Text('训练日', style: TextStyle(color: colors.accentGlow, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addRestDay,
                        child: Row(
                          children: [
                            Icon(Icons.bedtime_outlined, size: 18, color: colors.infoColor),
                            Text('休息日', style: TextStyle(color: colors.infoColor, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._days.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final day = entry.value;
                    return _buildDayEditor(colors, idx, day);
                  }),

                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('保存计划', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(LiftTrackColors colors, String text) {
    return Text(
      text,
      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  // 训练动作的小标签：用于展示组数/次数/重量/休息时间
  Widget _buildMiniTag(LiftTrackColors colors, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: colors.textSecondary, fontSize: 10),
      ),
    );
  }

  Widget _buildDayEditor(LiftTrackColors colors, int dayIndex, Map<String, dynamic> day) {
    final isRest = day['isRest'] == true;
    final exercises = (day['exercises'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final labelController = _labelControllers[dayIndex] ?? TextEditingController(text: '${day['label'] ?? ''}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRest ? colors.infoColor.withOpacity(0.06) : colors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isRest ? colors.infoColor.withOpacity(0.3) : colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isRest ? colors.infoColor.withOpacity(0.15) : colors.accentGlow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Icon(
                    isRest ? Icons.bedtime_outlined : Icons.fitness_center,
                    size: 14,
                    color: isRest ? colors.infoColor : colors.accentGlow,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: labelController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    hintText: isRest ? '休息日名称' : '训练日名称',
                  ),
                  onChanged: (val) => _days[dayIndex]['label'] = val,
                ),
              ),
              if (_days.length > 1)
                GestureDetector(
                  onTap: () => _removeDay(dayIndex),
                  child: Icon(Icons.close, size: 18, color: colors.textMuted),
                ),
            ],
          ),
          if (isRest) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: colors.infoColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement, size: 16, color: colors.infoColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '休息日 — 充分恢复，准备下一次训练',
                      style: TextStyle(color: colors.infoColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
          const SizedBox(height: 8),
          // Exercise list
          ...exercises.asMap().entries.map((exEntry) {
            final exIdx = exEntry.key;
            final ex = exEntry.value;
            final setConfig = ex['setConfig'] as List?;
            final hasPerSet = setConfig != null && setConfig.length > 1;
            // 格式化重量：整数时不显示小数，null 时显示 -
            final weightVal = ex['weight'];
            String weightStr;
            if (weightVal == null) {
              weightStr = '-';
            } else if (weightVal is num && weightVal == weightVal.toInt()) {
              weightStr = '${weightVal.toInt()}';
            } else {
              weightStr = '$weightVal';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _editExercise(dayIndex, exIdx),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 动作名称
                    Text(
                      '${ex['name']}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    if (hasPerSet) ...[
                      Row(
                        children: [
                          _buildMiniTag(colors, '共${ex['sets']}组 · 逐组设置'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _removeExercise(dayIndex, exIdx),
                            child: Icon(Icons.close, size: 14, color: colors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ExerciseSetTable(setConfig: setConfig!),
                    ] else
                      Row(
                        children: [
                          _buildMiniTag(colors, '${ex['sets']}组'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${ex['reps']}次'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${weightStr}kg'),
                          const SizedBox(width: 6),
                          _buildMiniTag(colors, '${ex['restTime']}秒'),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _removeExercise(dayIndex, exIdx),
                            child: Icon(Icons.close, size: 14, color: colors.textMuted),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _addExercise(dayIndex),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colors.borderColor, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text('添加动作', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }
}
