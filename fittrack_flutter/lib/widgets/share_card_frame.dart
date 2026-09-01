import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'poster_theme.dart';

/// 训练成果分享卡（海报1，对应 HTML #1）
///
/// 宽度 1080、高度 1920 固定（9:16）。使用 [PosterBackground] 跟随主题。
/// record 支持字段：
/// - name/dayLabel：训练名称（计划名）+ 训练日标签
/// - totalWeight/totalSets/duration/exerciseCount：今日核心数据
/// - completionRate：训练完成率（0-1，计划训练才有效）
/// - pk：（可选）本周虚拟对手 PK 结果，决定是否展示 PK 横幅
class ShareCardFrame extends StatelessWidget {
  final Map<String, dynamic> record;
  final Size size;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const ShareCardFrame({
    required this.record,
    this.size = const Size(1080, 1920),
    this.themeId,
    super.key,
  });

  /// 海报宽度 / 高度常量
  static const double posterWidth = 1080.0;
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    final name = record['name'] as String? ?? '训练完成';
    final dayLabel = record['dayLabel'] as String?;
    final totalWeight = record['totalWeight'] as int? ?? 0;
    final totalSets = record['totalSets'] as int? ?? 0;
    final exerciseCount = record['exerciseCount'] as int? ?? 0;
    final completionRate = (record['completionRate'] as num?)?.toDouble() ?? 0;
    final duration = record['duration'] as int? ?? 0;
    final dateTs = record['date'] as int? ?? 0;
    final pk = record['pk'] as Map<String, dynamic>?;
    final date = dateTs > 0
        ? DateTime.fromMillisecondsSinceEpoch(dateTs)
        : DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final durationStr = '${(duration / 60).floor()}';
    final ratePct = (completionRate * 100).round();
    final avgWeight = _avgWeight(totalWeight, totalSets);

    return SizedBox(
      width: posterWidth,
      height: posterHeight,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            PosterBrandHeader(
              colors: colors,
              subtitle: "TODAY'S ACHIEVEMENT",
            ),
            // ── 标题 ──────────────────────────────
            SizedBox(height: px(16)),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: px(22),
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            SizedBox(height: px(6)),
            // 日期 + 训练日标签
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: px(11), color: colors.textMuted),
                SizedBox(width: px(8)),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: px(10),
                    letterSpacing: 0.5,
                  ),
                ),
                if (dayLabel != null && dayLabel.isNotEmpty) ...[
                  SizedBox(width: px(8)),
                  PostBadge(text: dayLabel, colors: colors),
                ],
              ],
            ),
            // ── Hero：完成率环 + 总重量 ────────────
            SizedBox(height: px(16)),
            _buildHero(colors, ratePct.toDouble(), totalWeight),
            // ── 四数据卡 ──────────────────────────
            SizedBox(height: px(12)),
            Row(
              children: [
                _buildStat('$durationStr 分钟', colors),
                SizedBox(width: px(9)),
                _buildStat('$avgWeight kg', colors),
              ],
            ),
            SizedBox(height: px(9)),
            Row(
              children: [
                _buildStat('$totalSets 组', colors),
                SizedBox(width: px(9)),
                _buildStat('$exerciseCount 个', colors),
              ],
            ),
            // ── PK 横幅 ───────────────────────────
            if (pk != null) ...[
              SizedBox(height: px(12)),
              _buildPkBanner(colors, pk),
            ],
            // ── 底部二维码 ─────────────────────────
            const Spacer(),
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://share',
              hint: '扫码开始训练',
              sub: 'LiftTrack · 训练',
            ),
          ],
        ),
      ),
    );
  }

  String _avgWeight(int totalWeight, int totalSets) {
    if (totalSets <= 0) return '-';
    final avg = totalWeight / totalSets;
    return avg < 10 ? avg.toStringAsFixed(1) : avg.round().toString();
  }

  /// Hero 卡片：左侧完成率环 + 右侧总重量大数字
  Widget _buildHero(PosterColors colors, double rate, int totalWeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: px(18), vertical: px(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.brand, colors.brandSecondary],
        ),
        borderRadius: BorderRadius.circular(px(18)),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withOpacity(0.28),
            blurRadius: px(22),
            offset: Offset(0, px(8)),
          ),
        ],
      ),
      child: Row(
        children: [
          // 完成率环
          SizedBox(
            width: px(70),
            height: px(70),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: px(70),
                  height: px(70),
                  child: Transform.rotate(
                    angle: -math.pi / 2,
                    child: CircularProgressIndicator(
                      value: (rate / 100).clamp(0.0, 1.0),
                      strokeWidth: px(6),
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                Text(
                  '${rate.round()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: px(18),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: px(16)),
          // 总重量
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalWeight',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: px(52),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                SizedBox(height: px(4)),
                Text(
                  '总重量 (KG)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: px(10),
                    letterSpacing: px(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 单个数据卡（分钟/平均重量/组数/动作数）
  Widget _buildStat(String value, PosterColors colors) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: px(12), vertical: px(11)),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(px(16)),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(9)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: px(18),
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: px(8)),
            Text(
              _labelFor(value),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: px(9),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(String value) {
    if (value.contains('分钟')) return '训练时长';
    if (value.contains('kg')) return '平均重量';
    if (value.contains('组')) return '总组数';
    return '动作数';
  }

  /// 本周对阵虚拟对手的横幅
  Widget _buildPkBanner(PosterColors colors, Map<String, dynamic> pk) {
    final nickname = pk['nickname'] as String? ?? '对手';
    final userWon = pk['userWon'] as bool? ?? false;
    final userTimes = pk['userWeeklyTrainings'] as int? ?? 0;
    final oppoTimes = pk['opponentWeeklyTrainings'] as int? ?? 0;
    final statusColor = userWon ? colors.success : colors.warning;

    // 进度条占比（避免全 0）
    final total = userTimes + oppoTimes;
    final myFactor = (total > 0 ? userTimes / total : 0.5).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: px(14), vertical: px(11)),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(px(16)),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(9)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star, size: px(13), color: colors.brand),
              SizedBox(width: px(6)),
              Text(
                '本周PK',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: px(12),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: px(8), vertical: px(2)),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  userWon ? '领先' : '追赶中',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: px(9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: px(8)),
              Text(
                '我 $userTimes次 | $nickname $oppoTimes次',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: px(10),
                ),
              ),
            ],
          ),
          SizedBox(height: px(8)),
          // 合并进度条：我(brand) + 对手(textMuted)
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: px(6),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: myFactor,
                    alignment: Alignment.centerLeft,
                    child: Container(color: colors.brand),
                  ),
                  FractionallySizedBox(
                    widthFactor: (1 - myFactor),
                    alignment: Alignment.centerRight,
                    child: Container(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}