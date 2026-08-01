import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/tutorial_content.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';

/// 教学库搜索页
///
/// 设计依据：docs/superpowers/specs/2026-08-01-app-optimization-design.md §2.3
/// 搜索维度：name / primaryMuscle / equipment / difficulty / coachName（模糊匹配）
/// 数据源：TutorialLibrary 四个列表全量合并
class TutorialSearchPage extends StatefulWidget {
  const TutorialSearchPage({super.key});

  @override
  State<TutorialSearchPage> createState() => _TutorialSearchPageState();
}

class _TutorialSearchPageState extends State<TutorialSearchPage> {
  static const String _historyKey = 'tutorialSearchHistory';
  static const int _maxHistory = 10;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _history = [];
  List<Tutorial> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // 自动聚焦
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
    if (mounted) {
      setState(() => _history = raw);
    }
  }

  Future<void> _saveHistory(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_history);
    list.remove(trimmed); // 去重
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

  // ── 搜索 ─────────────────────────────────────────────────

  /// 全量数据源
  List<Tutorial> get _allTutorials => [
        ...TutorialLibrary.basicTutorials,
        ...TutorialLibrary.advancedTutorials,
        ...TutorialLibrary.topicTutorials,
        ...TutorialLibrary.masterTutorials,
      ];

  void _doSearch(String keyword) {
    final q = keyword.trim().toLowerCase();
    setState(() {
      _hasSearched = true;
      if (q.isEmpty) {
        _results = [];
        return;
      }
      _results = _allTutorials.where((t) {
        final name = t.name.toLowerCase();
        final muscle = t.primaryMuscle.label.toLowerCase();
        final equipment = (t.equipment ?? '').toLowerCase();
        final difficulty = t.difficulty.label.toLowerCase();
        final coach = t.coachName.toLowerCase();
        return name.contains(q) ||
            muscle.contains(q) ||
            equipment.contains(q) ||
            difficulty.contains(q) ||
            coach.contains(q);
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
            Expanded(
              child: !_hasSearched
                  ? _buildLanding(colors)
                  : (_results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          message: '未找到匹配的教学',
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
                  // 实时清空时不显示结果
                  if (v.trim().isEmpty && _hasSearched) {
                    setState(() {
                      _hasSearched = false;
                      _results = [];
                    });
                  }
                },
                style: TextStyle(color: colors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '搜索动作 / 肌群 / 器械 / 教练',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search,
                      color: colors.textMuted, size: 20),
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

  /// 未搜索时的落地页：历史搜索 + 热门推荐
  Widget _buildLanding(FitTrackColors colors) {
    final hot = _allTutorials.take(6).toList();
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
          children: hot.map((t) => _buildTutorialCard(colors, t)).toList(),
        ),
      ],
    );
  }

  /// 搜索结果列表
  Widget _buildResultList(FitTrackColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildTutorialCard(colors, _results[i]),
    );
  }

  /// 教学卡片：渐变封面 + emoji + 标题 + 难度 Badge + 肌群标签
  Widget _buildTutorialCard(FitTrackColors colors, Tutorial t) {
    return GestureDetector(
      onTap: () => context.push('/tutorial/${t.id}'),
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
            // 渐变封面
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: t.coverColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  t.coverEmoji ?? '🏋️',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 标题 + 元信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
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
                        text: t.difficulty.label,
                        variant: _difficultyVariant(t.difficulty),
                      ),
                      BadgeWidget(
                        text: t.primaryMuscle.label,
                        variant: BadgeVariant.info,
                      ),
                      if (t.equipment != null && t.equipment!.isNotEmpty)
                        BadgeWidget(
                          text: t.equipment!,
                          variant: BadgeVariant.purple,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(t.coachName,
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  BadgeVariant _difficultyVariant(TutorialDifficulty d) {
    switch (d) {
      case TutorialDifficulty.beginner:
        return BadgeVariant.success;
      case TutorialDifficulty.intermediate:
        return BadgeVariant.accent;
      case TutorialDifficulty.advanced:
        return BadgeVariant.purple;
    }
  }
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
