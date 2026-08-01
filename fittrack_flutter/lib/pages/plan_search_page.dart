import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/system_plan_library.dart';
import '../services/plan_unlock_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';

/// 计划库搜索页
///
/// 设计依据：docs/superpowers/specs/2026-08-01-app-optimization-design.md §2.4
/// 搜索维度：name / goal / difficulty / trainingType / tags / suitableFor
/// 数据源：5 个目标 getByGoal 合并全量
class PlanSearchPage extends StatefulWidget {
  const PlanSearchPage({super.key});

  @override
  State<PlanSearchPage> createState() => _PlanSearchPageState();
}

class _PlanSearchPageState extends State<PlanSearchPage> {
  static const String _historyKey = 'planSearchHistory';
  static const int _maxHistory = 10;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _history = [];
  List<SystemPlan> _results = [];
  bool _hasSearched = false;
  bool _filterExpanded = false;

  // 筛选项（null 表示不限）
  String? _filterGoal;
  String? _filterDifficulty;
  String? _filterTrainingType;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── 历史记录 ─────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    if (mounted) setState(() => _history = raw);
  }

  Future<void> _saveHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_history);
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > _maxHistory) list.removeRange(_maxHistory, list.length);
    await prefs.setStringList(_historyKey, list);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _removeHistory(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_history)..remove(keyword);
    await prefs.setStringList(_historyKey, list);
    if (mounted) setState(() => _history = list);
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    if (mounted) setState(() => _history = []);
  }

  // ── 数据源与搜索 ─────────────────────────────────────────

  /// 全量数据源：合并 5 个 goal 的所有计划
  List<SystemPlan> get _allPlans {
    final plans = <SystemPlan>[];
    final seen = <String>{};
    for (final goal in kPlanGoals) {
      for (final p in SystemPlanLibrary.instance.getByGoal(goal)) {
        if (seen.add(p.id)) plans.add(p);
      }
    }
    return plans;
  }

  void _doSearch(String keyword) {
    final q = keyword.trim().toLowerCase();
    setState(() {
      _hasSearched = true;
      if (q.isEmpty && _filterGoal == null && _filterDifficulty == null && _filterTrainingType == null) {
        _results = [];
        return;
      }
      _results = _allPlans.where((p) {
        // 关键词模糊匹配
        if (q.isNotEmpty) {
          final name = p.name.toLowerCase();
          final goal = (kGoalLabelsZh[p.goal] ?? p.goal).toLowerCase();
          final goalRaw = p.goal.toLowerCase();
          final difficulty = (kDifficultyLabelsZh[p.difficulty] ?? p.difficulty).toLowerCase();
          final difficultyRaw = p.difficulty.toLowerCase();
          final trainingType =
              (kTrainingTypeLabelsZh[p.trainingType] ?? p.trainingType).toLowerCase();
          final trainingTypeRaw = p.trainingType.toLowerCase();
          final tags = p.tags.map((t) => t.toLowerCase()).join(' ');
          final suitableFor = p.suitableFor.toLowerCase();
          final hit = name.contains(q) ||
              goal.contains(q) ||
              goalRaw.contains(q) ||
              difficulty.contains(q) ||
              difficultyRaw.contains(q) ||
              trainingType.contains(q) ||
              trainingTypeRaw.contains(q) ||
              tags.contains(q) ||
              suitableFor.contains(q);
          if (!hit) return false;
        }
        // 筛选条件
        if (_filterGoal != null && p.goal != _filterGoal) return false;
        if (_filterDifficulty != null && p.difficulty != _filterDifficulty) return false;
        if (_filterTrainingType != null && p.trainingType != _filterTrainingType) {
          return false;
        }
        return true;
      }).toList();
    });
    _saveHistory(keyword);
  }

  void _onHistoryTap(String keyword) {
    _controller.text = keyword;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _doSearch(keyword);
  }

  void _applyFilter() {
    // 切换筛选后立即重新搜索（若有任意已搜索或筛选条件）
    if (_hasSearched ||
        _filterGoal != null ||
        _filterDifficulty != null ||
        _filterTrainingType != null) {
      _doSearch(_controller.text);
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(colors),
            _buildFilterArea(colors),
            Expanded(
              child: !_hasSearched &&
                      _filterGoal == null &&
                      _filterDifficulty == null &&
                      _filterTrainingType == null
                  ? _buildLanding(colors)
                  : (_results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          message: '未找到匹配的训练计划',
                        )
                      : _buildResultList(colors)),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部搜索栏 + 取消按钮
  Widget _buildSearchBar(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: colors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderColor),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _doSearch,
                onChanged: (v) {
                  if (v.trim().isEmpty &&
                      _filterGoal == null &&
                      _filterDifficulty == null &&
                      _filterTrainingType == null &&
                      _hasSearched) {
                    setState(() {
                      _hasSearched = false;
                      _results = [];
                    });
                  }
                },
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '搜索计划 / 目标 / 难度 / 类型',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: colors.textMuted, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            setState(() {
                              _hasSearched = false;
                              _results = [];
                            });
                          },
                          child: Icon(Icons.close,
                              size: 18, color: colors.textMuted),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '取消',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 可折叠筛选区
  Widget _buildFilterArea(FitTrackColors colors) {
    final hasActiveFilter = _filterGoal != null ||
        _filterDifficulty != null ||
        _filterTrainingType != null;
    return Container(
      color: colors.bgSecondary,
      child: Column(
        children: [
          // 折叠/展开按钮
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _filterExpanded = !_filterExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      size: 18,
                      color: hasActiveFilter
                          ? colors.accentGlow
                          : colors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '筛选',
                    style: TextStyle(
                      color: hasActiveFilter
                          ? colors.accentGlow
                          : colors.textSecondary,
                      fontSize: 14,
                      fontWeight: hasActiveFilter
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (hasActiveFilter) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.accentGlow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '●',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: hasActiveFilter
                        ? () {
                            setState(() {
                              _filterGoal = null;
                              _filterDifficulty = null;
                              _filterTrainingType = null;
                            });
                            _applyFilter();
                          }
                        : null,
                    child: Text(
                      '重置',
                      style: TextStyle(
                        color: hasActiveFilter
                            ? colors.accentGlow
                            : colors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _filterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          // 展开后的 chip 区
          if (_filterExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: colors.borderColor.withOpacity(0.5), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterSection(
                    colors,
                    label: '目标',
                    options: kPlanGoals
                        .map((g) => _FilterOption(g, kGoalLabelsZh[g] ?? g))
                        .toList(),
                    selected: _filterGoal,
                    onSelected: (v) => setState(
                        () => _filterGoal = _filterGoal == v ? null : v),
                  ),
                  const SizedBox(height: 10),
                  _filterSection(
                    colors,
                    label: '难度',
                    options: kPlanDifficulties
                        .map((d) =>
                            _FilterOption(d, kDifficultyLabelsZh[d] ?? d))
                        .toList(),
                    selected: _filterDifficulty,
                    onSelected: (v) => setState(() =>
                        _filterDifficulty =
                            _filterDifficulty == v ? null : v),
                  ),
                  const SizedBox(height: 10),
                  _filterSection(
                    colors,
                    label: '训练类型',
                    options: kPlanTrainingTypes
                        .map((t) =>
                            _FilterOption(t, kTrainingTypeLabelsZh[t] ?? t))
                        .toList(),
                    selected: _filterTrainingType,
                    onSelected: (v) => setState(() =>
                        _filterTrainingType =
                            _filterTrainingType == v ? null : v),
                  ),
                  const SizedBox(height: 8),
                  // 应用筛选按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilter();
                        setState(() => _filterExpanded = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('应用筛选',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterSection(
    FitTrackColors colors, {
    required String label,
    required List<_FilterOption> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: options.map((opt) {
            final isSelected = opt.value == selected;
            return GestureDetector(
              onTap: () => onSelected(opt.value),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentGlow.withOpacity(0.15)
                      : colors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.accentGlow : colors.borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected ? colors.accentGlow : colors.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 未搜索时的落地页：历史搜索 + 热门推荐
  Widget _buildLanding(FitTrackColors colors) {
    final hot = _allPlans.take(6).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('历史搜索',
                  style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _clearHistory,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 14, color: colors.textMuted),
                    const SizedBox(width: 2),
                    Text('清空',
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history
                .map((k) => _HistoryChip(
                      text: k,
                      onTap: () => _onHistoryTap(k),
                      onLongPress: () => _removeHistory(k),
                      colors: colors,
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        Text('热门推荐',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Column(
          children: hot.map((p) => _buildPlanCard(colors, p)).toList(),
        ),
      ],
    );
  }

  /// 搜索结果列表
  Widget _buildResultList(FitTrackColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildPlanCard(colors, _results[i]),
    );
  }

  /// 计划卡片：封面 + 标题 + 目标 + 难度 + 周数 + 解锁状态
  Widget _buildPlanCard(FitTrackColors colors, SystemPlan p) {
    final isUnlocked = !p.isPremium ||
        PlanUnlockService.instance.isPlanUnlocked(p.id);
    final coverColors = _parseCoverColors(p.coverColors);
    return GestureDetector(
      onTap: () => context.push('/plan-library/detail/${p.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            // 封面
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: coverColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(p.coverEmoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 12),
            // 标题与元信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      BadgeWidget(
                        text: kGoalLabelsZh[p.goal] ?? p.goal,
                        variant: BadgeVariant.accent,
                      ),
                      BadgeWidget(
                        text: kDifficultyLabelsZh[p.difficulty] ?? p.difficulty,
                        variant: _difficultyVariant(p.difficulty),
                      ),
                      BadgeWidget(
                        text: '${p.totalWeeks}周',
                        variant: BadgeVariant.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (p.tags.isNotEmpty)
                    Text(p.tags.take(3).join(' · '),
                        style: TextStyle(
                            color: colors.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // 解锁状态 / 积分价
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isUnlocked)
                  const BadgeWidget(text: '已解锁', variant: BadgeVariant.success)
                else
                  BadgeWidget(text: '${p.pointsCost}积分', variant: BadgeVariant.purple),
                const SizedBox(height: 6),
                Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 解析十六进制颜色字符串到 Color
  List<Color> _parseCoverColors(List<String> hexList) {
    final result = <Color>[];
    for (final hex in hexList) {
      final c = _parseHexColor(hex);
      if (c != null) result.add(c);
    }
    if (result.length < 2) {
      result.addAll([
        const Color(0xFFFF6B35),
        const Color(0xFFFFD700),
      ]);
    }
    return result;
  }

  Color? _parseHexColor(String hex) {
    var h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final value = int.tryParse(h, radix: 16);
    if (value == null) return null;
    return Color(value);
  }

  BadgeVariant _difficultyVariant(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return BadgeVariant.success;
      case 'elementary':
        return BadgeVariant.accent;
      case 'intermediate':
        return BadgeVariant.info;
      case 'advanced':
        return BadgeVariant.purple;
      default:
        return BadgeVariant.accent;
    }
  }
}

class _FilterOption {
  final String value;
  final String label;
  const _FilterOption(this.value, this.label);
}

/// 历史搜索 chip
class _HistoryChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final FitTrackColors colors;

  const _HistoryChip({
    required this.text,
    required this.onTap,
    required this.onLongPress,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderColor),
        ),
        child: Text(text,
            style: TextStyle(color: colors.textSecondary, fontSize: 13)),
      ),
    );
  }
}
