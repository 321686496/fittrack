import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../services/permission_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ProfilePage extends StatefulWidget {
  final void Function(String page, {Map<String, dynamic>? params}) onNavigate;

  const ProfilePage({super.key, required this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> _achievements = [];

  @override
  void initState() {
    super.initState();
    _evaluateAchievements();
  }

  /// 根据真实训练数据判定成就是否达成
  void _evaluateAchievements() {
    final records = Storage.getRecords();
    final stats = Storage.getStats();
    final totalTrainings = (stats['totalTrainings'] as num?)?.toInt() ?? records.length;
    final totalWeight = (stats['totalWeight'] as num?)?.toDouble() ?? 0.0;
    final totalDuration = (stats['totalDuration'] as num?)?.toDouble() ?? 0.0;

    // 计算连续打卡天数
    int currentStreak = 0;
    if (records.isNotEmpty) {
      final dates = <String>{};
      for (final r in records) {
        final ts = r['date'] ?? r['createTime'];
        if (ts is int) {
          final d = DateTime.fromMillisecondsSinceEpoch(ts);
          dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        }
      }
      var checkDate = DateTime.now();
      while (dates.contains('${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // 计算总动作次数
    int totalReps = 0;
    for (final r in records) {
      final setRecords = r['setRecords'];
      if (setRecords is Map) {
        for (final entry in setRecords.values) {
          if (entry is List) {
            for (final s in entry) {
              if (s is Map) {
                totalReps += (s['reps'] as num?)?.toInt() ?? 0;
              }
            }
          }
        }
      }
    }

    // 读取之前已解锁的成就列表
    final settings = Storage.getSettings();
    final previouslyUnlocked = <String>{};
    final saved = settings['unlockedAchievements'];
    if (saved is List) {
      for (final s in saved) {
        previouslyUnlocked.add(s.toString());
      }
    }

    // 新达成的成就列表
    final newlyUnlocked = <Map<String, dynamic>>[];

    // 判定各成就
    _achievements = MockData.achievements.map((a) {
      final map = Map<String, dynamic>.from(a);
      final id = a['id'] as String;
      bool unlocked = false;
      String? progressText;

      switch (id) {
        case 'a1': // 初出茅庐 - 完成第一次训练
          unlocked = totalTrainings >= 1;
          progressText = '$totalTrainings/1';
          break;
        case 'a2': // 铁人意志 - 连续打卡7天
          unlocked = currentStreak >= 7;
          progressText = '$currentStreak/7天';
          break;
        case 'a3': // 百吨俱乐部 - 累计举起100吨
          unlocked = totalWeight >= 100000;
          progressText = '${(totalWeight / 1000).toStringAsFixed(1)}/100吨';
          break;
        case 'a4': // 马拉松选手 - 累计训练100小时
          unlocked = totalDuration >= 6000; // 分钟
          progressText = '${(totalDuration / 60).toStringAsFixed(1)}/100小时';
          break;
        case 'a5': // 千次达人 - 累计完成1000次动作
          unlocked = totalReps >= 1000;
          progressText = '$totalReps/1000次';
          break;
        case 'a6': // 不倒翁 - 连续打卡30天
          unlocked = currentStreak >= 30;
          progressText = '$currentStreak/30天';
          break;
      }

      map['unlocked'] = unlocked;
      map['progressText'] = progressText;

      // 检测新达成的成就（之前未解锁，现在解锁了）
      if (unlocked && !previouslyUnlocked.contains(id)) {
        newlyUnlocked.add(map);
      }

      return map;
    }).toList();

    // 保存当前已解锁的成就到 Storage
    final currentUnlocked = _achievements
        .where((a) => a['unlocked'] == true)
        .map((a) => a['id'] as String)
        .toList();
    Storage.saveSettings({...settings, 'unlockedAchievements': currentUnlocked});

    // 延迟弹出新达成成就的恭喜弹窗
    if (newlyUnlocked.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCongratsSequence(newlyUnlocked, 0);
      });
    }
  }

  void _showCongratsSequence(List<Map<String, dynamic>> achievements, int index) {
    if (index >= achievements.length || !mounted) return;
    _showCongrats(achievements[index], () {
      _showCongratsSequence(achievements, index + 1);
    });
  }

  void _showCongrats(Map<String, dynamic> achievement, [VoidCallback? onDismiss]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final colors = Theme.of(context).extension<FitTrackColors>()!;
        return AlertDialog(
          backgroundColor: colors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.accentGlow, width: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                achievement['icon'] as String,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 16),
              Text(
                '恭喜达成成就！',
                style: TextStyle(
                  color: colors.accentGlow,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement['name'] as String,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievement['desc'] as String,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onDismiss?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: colors.bgCard,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('太棒了！', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementDetail(Map<String, dynamic> achievement) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final unlocked = achievement['unlocked'] as bool;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: unlocked ? colors.accentGlow : colors.borderColor,
              width: unlocked ? 2 : 1,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Opacity(
                opacity: unlocked ? 1.0 : 0.5,
                child: Text(
                  achievement['icon'] as String,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                achievement['name'] as String,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievement['desc'] as String,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (achievement['progressText'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (unlocked ? colors.successColor : colors.accentGlow).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unlocked ? '已达成' : '进度: ${achievement['progressText']}',
                    style: TextStyle(
                      color: unlocked ? colors.successColor : colors.accentGlow,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final body = MockData.bodyData;

    return Column(
      children: [
        PageHeader(
          title: '我的',
          subtitle: '个人中心',
          isTabPage: true,
          onBellTap: () => _showNotifications(context),
          onCalendarTap: () => _showCalendar(context),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(colors),
                const SizedBox(height: 20),
                SectionHeader(title: '成就'),
                const SizedBox(height: 10),
                _buildAchievements(colors),
                const SizedBox(height: 20),
                SectionHeader(title: '身体数据'),
                const SizedBox(height: 10),
                _buildBodyData(colors, body),
                const SizedBox(height: 20),
                _buildMenuList(colors, context),
                const SizedBox(height: 16),
                _buildLogoutButton(colors, context),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) async {
    // 先请求通知权限
    final granted = await PermissionService.requestNotification();
    if (!granted && mounted) {
      PermissionService.showPermissionDeniedDialog(
        context,
        permissionName: '通知',
        reason: '需要通知权限才能向您推送训练提醒和每日贴士，请在设置中开启通知权限。',
      );
      return;
    }

    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final records = Storage.getRecords();
    final recentCount = records.length > 5 ? 5 : records.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('通知', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(Icons.close, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none, size: 48, color: colors.textMuted),
                            const SizedBox(height: 8),
                            Text('暂无通知', style: TextStyle(color: colors.textMuted, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildNotificationItem(colors, Icons.celebration, '欢迎使用 FitTrack', '开始你的健身之旅吧！'),
                          if (recentCount > 0)
                            _buildNotificationItem(colors, Icons.fitness_center, '训练提醒', '你已完成 $recentCount 次训练，继续加油！'),
                          _buildNotificationItem(colors, Icons.tips_and_updates, '每日贴士', MockData.dailyTip['text'] as String? ?? '坚持就是胜利'),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(FitTrackColors colors, IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: colors.accentGlow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: colors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendar(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final records = Storage.getRecords();
    final now = DateTime.now();

    // 统计本月训练天数
    final trainedDays = <int>{};
    for (final r in records) {
      final ts = r['date'] ?? r['createTime'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        if (d.year == now.year && d.month == now.month) {
          trainedDays.add(d.day);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('${now.year}年${now.month}月', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(Icons.close, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['一', '二', '三', '四', '五', '六', '日'].map((d) =>
                    Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCalendarGrid(colors, now, trainedDays),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentGlow, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('已训练 ${trainedDays.length} 天', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 16),
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors.accentGlow.withOpacity(0.3), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('今天', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarGrid(FitTrackColors colors, DateTime now, Set<int> trainedDays) {
    final firstDay = DateTime(now.year, now.month, 1);
    var startWeekday = firstDay.weekday - 1; // 0=Mon
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final cells = <Widget>[];
    // 空白填充
    for (var i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox());
    }
    // 日期
    for (var day = 1; day <= daysInMonth; day++) {
      final isToday = day == now.day;
      final isTrained = trainedDays.contains(day);
      cells.add(
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: isToday
                ? colors.accentGlow.withOpacity(0.3)
                : isTrained
                    ? colors.accentGlow.withOpacity(0.1)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                color: isToday
                    ? colors.accentGlow
                    : isTrained
                        ? colors.textPrimary
                        : colors.textMuted,
                fontSize: 13,
                fontWeight: isToday || isTrained ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 0,
      runSpacing: 2,
      children: cells.map((c) => SizedBox(width: (MediaQuery.of(context).size.width - 48) / 7, child: c)).toList(),
    );
  }

  Widget _buildProfileHeader(FitTrackColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: colors.accentGlow, width: 2),
            ),
            child: Icon(Icons.person, size: 32, color: colors.accentGlow),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockData.user['name'] as String,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'fittrack@example.com',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colors.textMuted, size: 22),
        ],
      ),
    );
  }

  Widget _buildAchievements(FitTrackColors colors) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: _achievements.map<Widget>((a) {
        final unlocked = a['unlocked'] as bool;
        return GestureDetector(
          onTap: () => _showAchievementDetail(a),
          child: Opacity(
            opacity: unlocked ? 1.0 : 0.4,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: unlocked ? colors.accentGlow.withOpacity(0.3) : colors.borderColor,
                  width: unlocked ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    a['icon'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a['name'] as String,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a['desc'] as String,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!unlocked && a['progressText'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      a['progressText'] as String,
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBodyData(FitTrackColors colors, Map<String, dynamic> body) {
    return CardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '身体数据',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '更新于 ${body['lastUpdate']}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildBodyItem(colors, '${body['height']}', 'cm', '身高'),
              _buildBodyItem(colors, '${body['weight']}', 'kg', '体重'),
              _buildBodyItem(colors, '${body['bmi']}', '', 'BMI'),
              _buildBodyItem(colors, '${body['bodyFat']}', '%', '体脂率'),
            ],
          ),
          const SizedBox(height: 12),
          DividerWidget(indent: 0),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBodyItem(colors, '${body['chest']}', 'cm', '胸围'),
              _buildBodyItem(colors, '${body['waist']}', 'cm', '腰围'),
              _buildBodyItem(colors, '${body['hip']}', 'cm', '臀围'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyItem(FitTrackColors colors, String value, String unit, String label) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(FitTrackColors colors, BuildContext ctx) {
    final menus = [
      {'icon': Icons.history, 'label': '训练记录', 'page': 'records'},
      {'icon': Icons.sports_gymnastics, 'label': '动作库', 'page': 'exercise'},
      {'icon': Icons.settings, 'label': '设置', 'page': 'settings'},
      {'icon': Icons.notifications_active_outlined, 'label': '提醒设置', 'page': ''},
      {'icon': Icons.watch_outlined, 'label': '设备连接', 'page': ''},
      {'icon': Icons.security_outlined, 'label': '隐私与安全', 'page': ''},
      {'icon': Icons.help_outline, 'label': '帮助与反馈', 'page': ''},
    ];

    return Column(
      children: menus.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MenuButton(
            icon: m['icon'] as IconData,
            label: m['label'] as String,
            onTap: () {
              final page = m['page'] as String;
              if (page.isNotEmpty) {
                widget.onNavigate(page);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton(FitTrackColors colors, BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('已退出登录'),
              backgroundColor: colors.warningColor,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.warningColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          '退出登录',
          style: TextStyle(
            color: colors.warningColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
