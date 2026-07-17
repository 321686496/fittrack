import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../services/points_service.dart';
import '../data/storage.dart';
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('当前积分', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$points', style: TextStyle(color: colors.accentGlow, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: colors.borderColor),
                        Expanded(
                          child: Column(
                            children: [
                              Text('累计获得', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('+$earnedTotal', style: TextStyle(color: colors.successColor, fontSize: 18, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: colors.borderColor),
                        Expanded(
                          child: Column(
                            children: [
                              Text('累计消耗', style: TextStyle(color: colors.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('-$spentTotal', style: TextStyle(color: colors.warningColor, fontSize: 18, fontWeight: FontWeight.w600)),
                            ],
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.borderColor),
                          ),
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
