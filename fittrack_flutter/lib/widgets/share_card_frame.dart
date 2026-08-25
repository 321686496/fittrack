import 'package:flutter/material.dart';
import 'poster_theme.dart';

/// 训练记录分享海报（宽度固定 1080，高度随内容自适应）
///
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
/// record 支持字段：
/// - name/dayLabel：训练名称（计划名）+ 训练日标签（副标题）
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

  /// 海报宽度常量（高度随内容自适应）
  static const double posterWidth = 1080.0;

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
    final durationStr = '${(duration / 60).floor()}分钟';
    final ratePct = (completionRate * 100).round();

    return PosterBackground(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            PosterBrandHeader(
              colors: colors,
              subtitle: '今日训练成就',
            ),
            const SizedBox(height: 56),
            // ── 训练名称（核心标题）──────────────────────
            Text(
              name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 54,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            // 日期 + 训练日标签（副标题行）
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 22, color: colors.textMuted),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(color: colors.textMuted, fontSize: 24),
                ),
                if (dayLabel != null && dayLabel.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cardBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Text(
                      dayLabel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 48),
            // ── Hero 卡片：完成率环 + 总重量基因数字 ──────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 40, vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.brand, colors.brandSecondary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 完成率环形进度
                  SizedBox(
                    width: 148,
                    height: 148,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 148,
                          height: 148,
                          child: CircularProgressIndicator(
                            value: completionRate.clamp(0.0, 1.0),
                            strokeWidth: 13,
                            backgroundColor: Colors.white.withOpacity(0.22),
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.white),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$ratePct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '完成率',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                  // 总重量大数字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalWeight',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '总重量 (KG)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // ── 数据卡网格：时长 + 平均重量 ───────────────
            Row(
              children: [
                _buildStatCard(
                  Icons.timer_outlined,
                  durationStr,
                  '训练时长',
                  colors,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  Icons.insights_rounded,
                  _avgWeight(totalWeight, totalSets),
                  '平均重量',
                  colors,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  Icons.repeat_rounded,
                  '$totalSets',
                  '总组数',
                  colors,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  Icons.sports_gymnastics,
                  '$exerciseCount',
                  '动作数',
                  colors,
                ),
              ],
            ),
            // ── PK 横幅（有对手数据时展示） ───────────────
            if (pk != null) ...[
              const SizedBox(height: 36),
              _buildPkBanner(colors, pk),
            ],
            const SizedBox(height: 48),
            // ── slogan ──────────────────────────────
            Center(
              child: Text(
                'LiftTrack · 记录每一组',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // ── 底部二维码 ───────────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: 'fittrack://share',
              hint: '扫码开始训练',
            ),
          ],
        ),
      ),
    );
  }

  String _avgWeight(int totalWeight, int totalSets) {
    if (totalSets <= 0) return '-';
    final avg = totalWeight / totalSets;
    return avg < 10
        ? avg.toStringAsFixed(1)
        : avg.round().toString();
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, PosterColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.brand, size: 32),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 本周对阵虚拟对手的横幅
  Widget _buildPkBanner(PosterColors colors, Map<String, dynamic> pk) {
    final nickname = pk['nickname'] as String? ?? '对手';
    final userWon = pk['userWon'] as bool? ?? false;
    final userTimes = pk['userWeeklyTrainings'] as int? ?? 0;
    final oppoTimes = pk['opponentWeeklyTrainings'] as int? ?? 0;
    final percentile = pk['percentile'] as int? ?? 0;
    final statusColor = userWon ? colors.success : colors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: 26, color: colors.brand),
              const SizedBox(width: 10),
              Text(
                '本周PK · vs $nickname',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  userWon ? '领先' : '追赶中',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // 双方次数对比
          _buildPkBar(
            colors,
            '我',
            userTimes,
            _scoreFor(userTimes, oppoTimes),
            colors.brand,
          ),
          const SizedBox(height: 10),
          _buildPkBar(
            colors,
            nickname,
            oppoTimes,
            1 - _scoreFor(userTimes, oppoTimes),
            colors.textMuted,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.trending_up, size: 22, color: colors.brand),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '超越同水平 $percentile% 用户',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 双方训练次数 → 进度条占比（合理避免全 0）
  double _scoreFor(int mine, int oppo) {
    final total = mine + oppo;
    if (total <= 0) return 0.5;
    return mine / total;
  }

  Widget _buildPkBar(PosterColors colors, String label, int times,
      double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.15),
              color: color,
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            '$times次',
            style: TextStyle(color: colors.textSecondary, fontSize: 18),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}