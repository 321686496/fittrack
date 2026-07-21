import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../services/points_service.dart';
import '../services/ad_service.dart';
import '../data/storage.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class PointsDetailPage extends StatefulWidget {
  const PointsDetailPage({super.key});

  @override
  State<PointsDetailPage> createState() => _PointsDetailPageState();
}

class _PointsDetailPageState extends State<PointsDetailPage> {
  List<Map<String, dynamic>> _log = [];

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  void _loadLog() {
    setState(() {
      _log = PointsService.instance.getPointsLog();
    });
  }

  String _formatTime(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _sourceLabel(String source) {
    const map = {
      'daily_check_in': '每日签到',
      'ad_watched': '观看广告',
      'invite': '邀请好友',
      'feature_unlock': '解锁功能',
      'course_learn': '课程学习',
      'achievement': '成就解锁',
      'checkIn': '每日签到',
    };
    return map[source] ?? source;
  }

  IconData _sourceIcon(String source, bool isIncome) {
    if (isIncome) {
      switch (source) {
        case 'daily_check_in':
        case 'checkIn':
          return Icons.check_circle_outline;
        case 'ad_watched':
          return Icons.ondemand_video;
        case 'invite':
          return Icons.card_giftcard;
        case 'course_learn':
          return Icons.school;
        case 'achievement':
          return Icons.emoji_events;
        default:
          return Icons.add_circle_outline;
      }
    }
    return Icons.lock_outline;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final points = PointsService.instance.points;
    final earnedTotal = Storage.getSettings()['pointsEarnedTotal'] ?? 0;
    final spentTotal = Storage.getSettings()['pointsSpentTotal'] ?? 0;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '积分明细',
            isTabPage: false,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部摘要卡片
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.accentGlow.withOpacity(0.1), colors.accentGlow.withOpacity(0.05)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Column(
                      children: [
                        // 大数字 + 当前积分
                        Text('$points',
                            style: TextStyle(
                                color: colors.accentGlow,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('当前积分',
                            style: TextStyle(color: colors.textMuted, fontSize: 12)),
                        const SizedBox(height: 16),
                        // 分隔线
                        Container(width: double.infinity, height: 1, color: colors.borderColor),
                        const SizedBox(height: 16),
                        // 累计获得 / 累计消耗
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('+$earnedTotal',
                                      style: TextStyle(
                                          color: colors.successColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('累计获得',
                                      style: TextStyle(color: colors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: colors.borderColor),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('-$spentTotal',
                                      style: TextStyle(
                                          color: colors.warningColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text('累计消耗',
                                      style: TextStyle(color: colors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 看广告加积分按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final adResult = await AdService.instance.showRewardedVideo();
                              if (adResult == AdResult.success || adResult == AdResult.notAvailable) {
                                await PointsService.instance.addPoints(5, 'ad_watched');
                                if (mounted) {
                                  FitToast.success(context, '获得 5 积分！');
                                  _loadLog();
                                  setState(() {});
                                }
                              }
                            },
                            icon: const Icon(Icons.ondemand_video, size: 16),
                            label: const Text('看广告 +5 积分'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.accentGlow,
                              side: BorderSide(color: colors.accentGlow.withOpacity(0.3)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 积分明细列表
                  Text('积分明细', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_log.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('暂无积分记录', style: TextStyle(color: colors.textMuted, fontSize: 14)),
                      ),
                    )
                  else
                    ..._log.map((item) {
                      final delta = item['delta'] as int? ?? 0;
                      final isIncome = delta >= 0;
                      final source = item['source'] as String? ?? '';
                      final balance = item['balance'] as int? ?? 0;
                      final time = item['time'] as int? ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                // 左侧 4px 色条
                                Container(
                                  width: 4,
                                  decoration: BoxDecoration(
                                    color: isIncome ? colors.successColor : colors.warningColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                // 原有内容
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36, height: 36,
                                          decoration: BoxDecoration(
                                            color: (isIncome ? colors.successColor : colors.warningColor).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            _sourceIcon(source, isIncome),
                                            size: 18,
                                            color: isIncome ? colors.successColor : colors.warningColor,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_sourceLabel(source), style: TextStyle(
                                                color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500,
                                              )),
                                              Text(_formatTime(time), style: TextStyle(
                                                color: colors.textMuted, fontSize: 11,
                                              )),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${isIncome ? '+' : ''}$delta',
                                              style: TextStyle(
                                                color: isIncome ? colors.successColor : colors.warningColor,
                                                fontSize: 16, fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text('余额 $balance', style: TextStyle(
                                              color: colors.textMuted, fontSize: 10,
                                            )),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  // 积分获取途径
                  Text('积分获取途径', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildWayItem(colors, Icons.check_circle_outline, '每日签到', '每天首次打开 App +5 积分'),
                  _buildWayItem(colors, Icons.ondemand_video, '观看广告', '观看完整广告 +5 积分'),
                  _buildWayItem(colors, Icons.card_giftcard, '邀请好友', '好友首次训练 +50 积分，里程碑额外奖励'),
                  _buildWayItem(colors, Icons.school, '课程学习', '完成课程章节 +10 积分'),
                  _buildWayItem(colors, Icons.emoji_events, '成就解锁', '解锁成就获得变量积分'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWayItem(FitTrackColors colors, IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.accentGlow),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(desc, style: TextStyle(color: colors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
