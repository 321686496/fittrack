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
  bool _showAll = false;
  String _filterSource = 'all';

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

  List<Map<String, dynamic>> get _filteredList {
    if (_filterSource == 'all') return _log;
    return _log.where((item) {
      final source = item['source'] as String? ?? '';
      return _matchSource(source, _filterSource);
    }).toList();
  }

  List<Map<String, dynamic>> get _displayList {
    final list = _filteredList;
    if (_showAll) return list;
    return list.take(5).toList();
  }

  bool _matchSource(String source, String filter) {
    switch (filter) {
      case 'checkIn':
        return source == 'daily_check_in' || source == 'checkIn';
      case 'ad':
        return source == 'ad_watched' || source == 'ad';
      case 'invite':
        return source == 'invite';
      case 'course':
        return source == 'course_learn';
      case 'achievement':
        return source == 'achievement';
      default:
        return true;
    }
  }

  String _formatTime(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _sourceLabel(String source) {
    const map = {
      'daily_check_in': '每日签到',
      'ad_watched': '观看广告',
      'ad': '观看广告',
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
        case 'ad':
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

  /// 执行每日签到
  Future<void> _doCheckIn() async {
    final success = await PointsService.instance.dailyCheckIn();
    if (!mounted) return;
    if (success) {
      FitToast.success(context, '签到成功，获得 ${PointsService.checkInPoints} 积分！');
      _loadLog();
      setState(() {});
    } else {
      FitToast.warning(context, '今日已签到，明天再来吧');
    }
  }

  /// 观看广告获取积分
  Future<void> _watchAd() async {
    final canWatch = await PointsService.instance.canWatchAd();
    if (!canWatch) {
      if (mounted) FitToast.warning(context, '今日观看次数已达上限');
      return;
    }
    final adResult = await AdService.instance.showRewardedVideo();
    if (adResult == AdResult.success || adResult == AdResult.notAvailable) {
      await PointsService.instance.recordAdWatched();
      if (mounted) {
        FitToast.success(context, '获得 ${PointsService.adPoints} 积分！');
        _loadLog();
        setState(() {});
      }
    }
  }

  /// 跳转到对应获取页面
  void _navigateToGet(String type) async {
    switch (type) {
      case 'checkIn':
        await _doCheckIn();
        break;
      case 'ad':
        await _watchAd();
        break;
      case 'invite':
        context.push('/invitation');
        break;
      case 'course':
        context.push('/course');
        break;
      case 'achievement':
        context.push('/achievements');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    final points = PointsService.instance.points;
    final earnedTotal = Storage.getSettings()['pointsEarnedTotal'] ?? 0;
    final spentTotal = Storage.getSettings()['pointsSpentTotal'] ?? 0;
    const adsEnabled = AdService.adsEnabled;

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
                        // 仅在广告功能开启时显示看广告加积分按钮
                        if (adsEnabled) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _watchAd,
                              icon: const Icon(Icons.ondemand_video, size: 16),
                              label: const Text('看广告 +${PointsService.adPoints} 积分'),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 积分明细列表 - 标题 + 筛选
                  Row(
                    children: [
                      Text('积分明细', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_log.length > 5)
                        TextButton(
                          onPressed: () => setState(() => _showAll = !_showAll),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _showAll ? '收起' : '查看全部 (${_log.length})',
                            style: TextStyle(color: colors.accentGlow, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 筛选标签
                  if (_log.isNotEmpty) _buildFilterChips(colors),
                  if (_log.isNotEmpty) const SizedBox(height: 12),
                  if (_displayList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          _filterSource == 'all' ? '暂无积分记录' : '暂无该类型记录',
                          style: TextStyle(color: colors.textMuted, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ..._displayList.map((item) => _buildLogItem(colors, item)),
                  if (_showAll && _filteredList.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          '共 ${_filteredList.length} 条记录',
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // 积分获取途径
                  Text('积分获取途径', style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildWayItem(colors, Icons.check_circle_outline, '每日签到', '每天首次签到 +${PointsService.checkInPoints} 积分', 'checkIn'),
                  if (adsEnabled)
                    _buildWayItem(colors, Icons.ondemand_video, '观看广告', '观看完整广告 +${PointsService.adPoints} 积分', 'ad'),
                  _buildWayItem(colors, Icons.card_giftcard, '邀请好友', '好友首次训练 +${PointsService.invitePoints} 积分，里程碑额外奖励', 'invite'),
                  _buildWayItem(colors, Icons.school, '课程学习', '完成课程章节 +${PointsService.trainingPoints} 积分', 'course'),
                  _buildWayItem(colors, Icons.emoji_events, '成就解锁', '解锁成就获得变量积分', 'achievement'),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterChips(LiftTrackColors colors) {
    // 使用 Map 保持顺序并避免使用 Records 语法（Dart 2.19 不支持 Records）
    const chips = <MapEntry<String, String>>[
      MapEntry('all', '全部'),
      MapEntry('checkIn', '签到'),
      MapEntry('ad', '广告'),
      MapEntry('invite', '邀请'),
      MapEntry('course', '课程'),
      MapEntry('achievement', '成就'),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final chip = chips[index];
          final isSelected = _filterSource == chip.key;
          return GestureDetector(
            onTap: () => setState(() => _filterSource = chip.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? colors.accentGlow : colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? colors.accentGlow : colors.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  chip.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建单条积分记录
  Widget _buildLogItem(LiftTrackColors colors, Map<String, dynamic> item) {
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
  }

  /// 构建获取途径项，带"去获取"按钮
  Widget _buildWayItem(LiftTrackColors colors, IconData icon, String title, String desc, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _navigateToGet(type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.accentGlow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '去获取',
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
