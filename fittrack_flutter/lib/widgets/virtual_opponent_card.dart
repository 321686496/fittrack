import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../data/virtual_opponent.dart';
import 'common_widgets.dart';
import 'opponent/opponent_renderer.dart';

/// v1 首页 PK 卡片 — 虚拟对手本周对比
///
/// 依据：docs/versions/v1-获客留存版/02_功能清单.md §E1 (V1-01-06)
/// UI规格：docs/versions/v1-获客留存版/05_UI设计文档.md §7.1.1
///
/// 展示内容：
/// - 用户本周训练次数 vs 对手本周训练次数
/// - 双方进度条对比
/// - 同水平层超越百分比
///
/// 数据流：
/// 1. 首次加载：按用户训练频率匹配对手层，生成对手并推进本周数据
/// 2. 后续加载：从 Storage 读取对手 JSON，按需推进（周日凌晨）
class VirtualOpponentCard extends StatefulWidget {
  final VoidCallback? onTap;

  const VirtualOpponentCard({super.key, this.onTap});

  @override
  State<VirtualOpponentCard> createState() => _VirtualOpponentCardState();
}

class _VirtualOpponentCardState extends State<VirtualOpponentCard> {
  VirtualOpponent? _opponent;
  int _userWeeklyTrainings = 0;
  int _percentile = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final settings = Storage.getSettings();
    final records = Storage.getRecords();

    // 计算用户本周训练次数
    _userWeeklyTrainings = _computeWeeklyTrainings(records);

    // 获取或创建虚拟对手
    final opponentJson = settings['virtualOpponentData'] as Map<String, dynamic>?;
    if (opponentJson != null) {
      _opponent = VirtualOpponent.fromJson(
        Map<String, dynamic>.from(opponentJson),
      );
      // 检查是否需要推进（周日）
      _maybeAdvanceOpponent(settings);
    } else {
      _matchOpponent(settings);
    }

    // 计算超越百分比
    if (_opponent != null) {
      _percentile = VirtualOpponentEngine.instance.computePercentile(
        _userWeeklyTrainings,
        _opponent!.tier,
      );
    }

    setState(() {});
  }

  int _computeWeeklyTrainings(List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final weekStart = now.subtract(Duration(days: weekday - 1));
    final weekStartMs = DateTime(weekStart.year, weekStart.month, weekStart.day).millisecondsSinceEpoch;

    int count = 0;
    for (final r in records) {
      final ts = r['date'] as int? ?? r['createTime'] as int?;
      if (ts != null && ts >= weekStartMs) {
        count++;
      }
    }
    return count;
  }

  void _matchOpponent(Map<String, dynamic> settings) {
    // 根据用户历史训练频率匹配对手层
    final records = Storage.getRecords();
    final tier = _inferTier(records);

    final opponent = VirtualOpponentEngine.instance.generateOne(
      'vo_matched_${DateTime.now().millisecondsSinceEpoch}',
      tier,
    );
    VirtualOpponentEngine.instance.advanceWeekly(opponent);

    _opponent = opponent;

    // 持久化
    settings['virtualOpponentMatched'] = true;
    settings['virtualOpponentTier'] = tier.name;
    settings['virtualOpponentLastAdvance'] = DateTime.now().millisecondsSinceEpoch;
    settings['virtualOpponentData'] = opponent.toJson();
    Storage.saveSettings(settings);
  }

  OpponentTier _inferTier(List<Map<String, dynamic>> records) {
    // 根据近4周平均训练频率推断水平层
    if (records.isEmpty) return OpponentTier.casual;

    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final fourWeeksAgoMs = DateTime(fourWeeksAgo.year, fourWeeksAgo.month, fourWeeksAgo.day).millisecondsSinceEpoch;

    int recentCount = 0;
    for (final r in records) {
      final ts = r['date'] as int? ?? r['createTime'] as int?;
      if (ts != null && ts >= fourWeeksAgoMs) {
        recentCount++;
      }
    }

    // 近4周训练次数 → 每周平均
    final weeklyAvg = recentCount / 4;
    if (weeklyAvg >= 4) return OpponentTier.hardcore;
    if (weeklyAvg >= 3) return OpponentTier.active;
    if (weeklyAvg >= 2) return OpponentTier.regular;
    return OpponentTier.casual;
  }

  void _maybeAdvanceOpponent(Map<String, dynamic> settings) {
    if (_opponent == null) return;

    final lastAdvanceMs = settings['virtualOpponentLastAdvance'] as int?;
    if (lastAdvanceMs == null) {
      VirtualOpponentEngine.instance.advanceWeekly(_opponent!);
      settings['virtualOpponentLastAdvance'] = DateTime.now().millisecondsSinceEpoch;
      settings['virtualOpponentData'] = _opponent!.toJson();
      Storage.saveSettings(settings);
      return;
    }

    final lastAdvance = DateTime.fromMillisecondsSinceEpoch(lastAdvanceMs);
    final now = DateTime.now();

    // 如果上次推进在上周或更早，则推进
    if (_isLastWeekOrEarlier(lastAdvance, now)) {
      VirtualOpponentEngine.instance.advanceWeekly(_opponent!);
      settings['virtualOpponentLastAdvance'] = now.millisecondsSinceEpoch;
      settings['virtualOpponentData'] = _opponent!.toJson();
      Storage.saveSettings(settings);
    }
  }

  bool _isLastWeekOrEarlier(DateTime lastAdvance, DateTime now) {
    // 计算上周一的日期
    final thisWeekMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return lastAdvance.isBefore(thisWeekMonday);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    if (_opponent == null) {
      return const SizedBox.shrink();
    }

    final opponentTrainings = _opponent!.weeklyTrainings;
    final maxCount = (_userWeeklyTrainings > opponentTrainings
            ? _userWeeklyTrainings
            : opponentTrainings)
        .clamp(1, 7); // 每周最多7次

    return GestureDetector(
      onTap: widget.onTap ?? () => context.push('/opponent-detail'),
      child: CardWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OpponentRenderer(
                    skinId: _opponent!.appliedSkinId,
                    size: const Size(48, 48),
                    autoTrain: false,
                    showAura: false,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '本周 PK',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _opponent!.tier.label,
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // VS 对比区
            Row(
              children: [
                // 用户方
                Expanded(
                  child: _buildSide(
                    colors,
                    label: '你',
                    count: _userWeeklyTrainings,
                    maxCount: maxCount,
                    isUser: true,
                  ),
                ),
                // VS
                Container(
                  width: 36,
                  alignment: Alignment.center,
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                // 对手方
                Expanded(
                  child: _buildSide(
                    colors,
                    label: _opponent!.nickname,
                    count: opponentTrainings,
                    maxCount: maxCount,
                    isUser: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 对手动态（如果有）
            if (_opponent!.currentStatus != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 14, color: colors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_opponent!.nickname}：${_opponent!.currentStatus}',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            // 激励文案
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _buildIncentiveText(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSide(
    LiftTrackColors colors, {
    required String label,
    required int count,
    required int maxCount,
    required bool isUser,
  }) {
    final progress = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
    final sideColor = isUser ? colors.accentGlow : colors.textMuted;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: sideColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '$count 次',
          style: TextStyle(
            color: sideColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.bgSecondary,
            valueColor: AlwaysStoppedAnimation(sideColor),
          ),
        ),
      ],
    );
  }

  String _buildIncentiveText() {
    if (_userWeeklyTrainings == 0) {
      return '本周还未训练，开始第一次吧！';
    }

    final opponentTrainings = _opponent!.weeklyTrainings;
    if (_userWeeklyTrainings > opponentTrainings) {
      return '本周训练 $_userWeeklyTrainings 次，超越 $_percentile% 同水平用户';
    } else if (_userWeeklyTrainings == opponentTrainings) {
      return '与对手打平！再来一次拉开差距';
    } else {
      return '对手领先 ${opponentTrainings - _userWeeklyTrainings} 次，追上他！';
    }
  }
}
