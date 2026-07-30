import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/user_profile_generator.dart';
import '../services/platform/platform_services.dart';
import '../services/platform/widget_card_service.dart';
import '../services/points_service.dart';
import '../services/achievement_service.dart';
import '../services/daily_reminder_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/custom_time_picker.dart';
import '../widgets/max_weight_card.dart';
import '../widgets/notification_list_sheet.dart';
import '../widgets/tab_refresh_mixin.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TabRefreshMixin<ProfilePage> {
  // build 内同步 IO 缓存（在 _refreshCache 中预计算）
  Map<String, dynamic> _bodyDataCache = const {};
  Map<String, dynamic> _settingsCache = const {};
  int _streakCache = 0;

  @override
  int get tabIndex => 4;

  @override
  void onTabBecameActive() {
    // 切换到"我的"时刷新积分、成就等数据
    _refreshCache();
    _evaluateAchievements();
  }

  void _refreshCache() {
    _bodyDataCache = Storage.getBodyData();
    _settingsCache = Storage.getSettings();
    _streakCache = _computeCurrentStreak();
    if (mounted) setState(() {});
  }

  Future<void> _onRefresh() async {
    await _evaluateAchievements();
    _refreshCache();
  }

  @override
  void initState() {
    super.initState();
    _refreshCache();
    _evaluateAchievements();
  }

  Future<void> _evaluateAchievements() async {
    await AchievementService.instance.init();
    final newlyUnlocked = await AchievementService.instance.evaluateAchievements();
    if (mounted) setState(() {});
    // 弹出新达成成就的恭喜弹窗
    if (newlyUnlocked.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCongratsSequence(newlyUnlocked, 0);
      });
    }
  }

  void _showCongratsSequence(List<String> achievementIds, int index) {
    if (index >= achievementIds.length || !mounted) return;
    _showCongrats(achievementIds[index], () {
      _showCongratsSequence(achievementIds, index + 1);
    });
  }

  void _showCongrats(String achievementId, [VoidCallback? onDismiss]) {
    final all = AchievementService.instance.getAll();
    Achievement? ach;
    try {
      ach = all.firstWhere((a) => a.id == achievementId);
    } catch (_) {
      ach = null;
    }
    if (ach == null) {
      onDismiss?.call();
      return;
    }
    AchievementDialog.show(
      context,
      icon: _achievementEmoji(ach.icon),
      name: ach.title,
      desc: ach.description,
      onDone: onDismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final body = _bodyDataCache;

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
          child: RefreshIndicator(
            color: colors.accentGlow,
            backgroundColor: colors.bgCard,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(colors),
                  const SizedBox(height: 12),
                  _buildPointsCard(colors),
                  const SizedBox(height: 20),
                  _buildAchievements(colors),
                  const SizedBox(height: 20),
                  const SectionHeader(title: '身体数据'),
                  const SizedBox(height: 10),
                  if (_hasMeaningfulBodyData(body))
                    _buildBodyData(colors, body)
                  else
                    _buildNoBodyDataCard(colors),
                  const SizedBox(height: 12),
                  MaxWeightCard(onTap: () => context.push('/max-weight-detail')),
                  const SizedBox(height: 20),
                  _buildMenuList(colors, context),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    NotificationListSheet.show(context);
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

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.65,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    final settings = _settingsCache;
    final userName = settings['userName'] as String? ?? '用户';
    final gender = settings['gender'] as String? ?? '';
    final goal = settings['fitnessGoal'] as String? ?? '';
    final level = settings['fitnessLevel'] as String? ?? '';
    final avatarEmoji = settings['avatarEmoji'] as String? ?? '💪';
    final avatarBgColor = settings['avatarBgColor'] as int? ?? 0xFFFF6B35;
    final earnedTotal = settings['pointsEarnedTotal'] ?? 0;
    final spentTotal = settings['pointsSpentTotal'] ?? 0;
    final streak = _streakCache;

    // 构建副标题
    final tags = <String>[
      if (gender.isNotEmpty) gender,
      if (level.isNotEmpty) level,
      if (goal.isNotEmpty) goal,
    ];
    final subtitle = tags.isNotEmpty ? tags.join(' · ') : '开始你的健身之旅';

    return GestureDetector(
      onTap: () => _showProfileEditor(colors),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部分：头像 + 用户名 + 副标题
            Row(
              children: [
                UserProfileGenerator.buildAvatarWidget(
                  {'emoji': avatarEmoji, 'bgColor': avatarBgColor},
                  size: 48,
                  borderWidth: 0,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            // 三列数据带
            Row(
              children: [
                _buildStatColumn(colors, '$earnedTotal', '累计获得'),
                _buildVerticalDivider(colors),
                _buildStatColumn(colors, '$spentTotal', '消耗'),
                _buildVerticalDivider(colors),
                _buildStatColumn(colors, '$streak', '连续打卡'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(FitTrackColors colors, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: colors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(FitTrackColors colors) {
    return Container(
      width: 1,
      height: 28,
      color: colors.borderColor,
    );
  }

  /// 积分单独成卡：大数字 + 入口
  Widget _buildPointsCard(FitTrackColors colors) {
    final points = PointsService.instance.points;
    return GestureDetector(
      onTap: () => context.push('/points-detail'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.stars_rounded, color: colors.accentGlow, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '我的积分',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: colors.accentGlow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '查看详情 →',
              style: TextStyle(color: colors.accentGlow, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 计算当前连续打卡天数（与 home_page.dart 中的逻辑一致）
  int _computeCurrentStreak() {
    final records = Storage.getRecords();
    if (records.isEmpty) return 0;

    final dates = <String>{};
    for (final r in records) {
      final ts = r['date'] ?? r['createTime'] ?? r['timestamp'];
      if (ts is int) {
        final d = DateTime.fromMillisecondsSinceEpoch(ts);
        dates.add(
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
    }
    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    int streak = 0;
    if (dates.contains(todayStr)) {
      streak = 1;
      var checkDate = today.subtract(const Duration(days: 1));
      while (dates.contains(
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      if (dates.contains(yesterdayStr)) {
        streak = 1;
        var checkDate = yesterday.subtract(const Duration(days: 1));
        while (dates.contains(
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}')) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
    }
    return streak;
  }

  void _showProfileEditor(FitTrackColors colors) {
    final settings = Storage.getSettings();
    final nameCtrl = TextEditingController(text: settings['userName'] as String? ?? '用户');
    String selectedGender = settings['gender'] as String? ?? '';
    String selectedGoal = settings['fitnessGoal'] as String? ?? '';
    String selectedLevel = settings['fitnessLevel'] as String? ?? '';
    String selectedEmoji = settings['avatarEmoji'] as String? ?? '💪';
    int selectedBgColor = settings['avatarBgColor'] as int? ?? 0xFFFF6B35;
    String trainingTime = settings['trainingTime'] as String? ?? '';

    final allAvatars = UserProfileGenerator.getAllAvatars();

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.85,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('编辑个人信息', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Icon(Icons.close, color: colors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 头像选择
                  Text('选择头像', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allAvatars.map((avatar) {
                      final isSelected = avatar['emoji'] == selectedEmoji && avatar['bgColor'] == selectedBgColor;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedEmoji = avatar['emoji'] as String;
                            selectedBgColor = avatar['bgColor'] as int;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: UserProfileGenerator.buildAvatarWidget(
                            avatar,
                            size: 48,
                            borderWidth: 0,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 用户名
                  Text('用户名', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          style: TextStyle(color: colors.textPrimary, fontSize: 16),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colors.bgCard,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: colors.accentGlow),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          final newName = UserProfileGenerator.generateUserName(
                            gender: selectedGender,
                            fitnessGoal: selectedGoal,
                            fitnessLevel: selectedLevel,
                          );
                          setSheetState(() => nameCtrl.text = newName);
                        },
                        icon: Icon(Icons.casino, color: colors.accentGlow),
                        tooltip: '随机生成',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 性别
                  Text('性别', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['男', '女'].map((g) {
                      final isSelected = selectedGender == g;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedGender = g),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? colors.accentGlow.withOpacity(0.12) : colors.bgCard,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? colors.accentGlow : colors.borderColor,
                              ),
                            ),
                            child: Text(
                              g,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? colors.accentGlow : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 健身目标
                  Text('健身目标', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['增肌', '减脂', '塑形', '保持健康'].map((g) {
                      final isSelected = selectedGoal == g;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedGoal = g),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.12) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 健身水平
                  Text('健身水平', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['新手', '初级', '中级', '高级'].map((l) {
                      final isSelected = selectedLevel == l;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedLevel = l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentGlow.withOpacity(0.12) : colors.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? colors.accentGlow : colors.borderColor,
                            ),
                          ),
                          child: Text(
                            l,
                            style: TextStyle(
                              color: isSelected ? colors.accentGlow : colors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 训练提醒时间
                  Text('每日训练提醒时间', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final initialTime = trainingTime.isNotEmpty
                          ? _parseTimeOfDay(trainingTime)
                          : const TimeOfDay(hour: 18, minute: 0);
                      // 使用自定义时间选择器（FitTrack 暗色主题风格滚轮）
                      final picked = await CustomTimePicker.show(
                        context,
                        initialTime: initialTime,
                      );
                      if (picked != null) {
                        setSheetState(() {
                          trainingTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            trainingTime.isNotEmpty ? trainingTime : '点击设置提醒时间',
                            style: TextStyle(
                              color: trainingTime.isNotEmpty ? colors.accentGlow : colors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(Icons.access_time, color: colors.accentGlow, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final s = Storage.getSettings();
                        s['userName'] = nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : '用户';
                        if (selectedGender.isNotEmpty) s['gender'] = selectedGender;
                        if (selectedGoal.isNotEmpty) s['fitnessGoal'] = selectedGoal;
                        if (selectedLevel.isNotEmpty) s['fitnessLevel'] = selectedLevel;
                        s['avatarEmoji'] = selectedEmoji;
                        s['avatarBgColor'] = selectedBgColor;
                        s['trainingTime'] = trainingTime;
                        Storage.saveSettings(s);
                        Navigator.of(ctx).pop();
                        _refreshCache();
                        // 更新卡片数据（训练时间变更）
                        PlatformServices.widgetCard.pushCardData(
                          const WidgetCardData(mode: WidgetCardMode.idle),
                        );
                        // 训练时间变更后重新调度每日提醒（开关开启时生效）
                        DailyReminderService.instance.reschedule();
                        FitToast.success(context, '个人信息已更新');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentGlow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievements(FitTrackColors colors) {
    final all = AchievementService.instance.getAll();
    final unlocked = all.where((a) => a.unlocked).toList();
    final pct = all.isNotEmpty ? (unlocked.length / all.length * 100).round() : 0;

    return Row(
      children: [
        // 左卡：荣誉墙
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/honor-wall'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 18, color: colors.accentGlow),
                      const SizedBox(width: 6),
                      Text('荣誉墙',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${unlocked.length}/${all.length}',
                      style: TextStyle(
                          color: colors.accentGlow,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // 缩略徽章横滑
                  SizedBox(
                    height: 32,
                    child: unlocked.isEmpty
                        ? Text('尚未解锁',
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 11))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: unlocked.length.clamp(0, 3),
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (ctx, i) {
                              final a = unlocked[i];
                              return Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colors.accentGlow.withOpacity(0.15),
                                ),
                                child: Icon(_achievementIcon(a.icon),
                                    size: 16, color: colors.accentGlow),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 右卡：成就墙
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/achievements'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_turned_in,
                          size: 18, color: colors.accentGlow),
                      const SizedBox(width: 6),
                      Text('成就墙',
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('$pct%',
                          style: TextStyle(
                              color: colors.accentGlow,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          value: all.isNotEmpty ? unlocked.length / all.length : 0,
                          strokeWidth: 3,
                          backgroundColor: colors.borderColor,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentGlow),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('总进度',
                      style: TextStyle(
                          color: colors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _achievementIcon(String iconKey) {
    switch (iconKey) {
      case 'streak':
        return Icons.local_fire_department;
      case 'weight':
        return Icons.fitness_center;
      case 'duration':
        return Icons.timer;
      case 'month':
        return Icons.calendar_month;
      case 'explore':
        return Icons.explore;
      case 'plan':
        return Icons.assignment_turned_in;
      case 'share':
        return Icons.share;
      default:
        return Icons.emoji_events;
    }
  }

  /// AchievementDialog 通过 Text 渲染 icon，需要 emoji 而非 key
  String _achievementEmoji(String iconKey) {
    switch (iconKey) {
      case 'streak':
        return '🔥';
      case 'weight':
        return '💪';
      case 'duration':
        return '⏱️';
      case 'month':
        return '📅';
      case 'explore':
        return '🧭';
      case 'plan':
        return '✅';
      case 'share':
        return '📣';
      default:
        return '🏆';
    }
  }

  Widget _buildBodyData(FitTrackColors colors, Map<String, dynamic> body) {
    // 收集有值的字段（值为 0 或 null 的字段不显示）
    final fieldConfigs = <Map<String, dynamic>>[
      {'key': 'height', 'unit': 'cm', 'label': '身高'},
      {'key': 'weight', 'unit': 'kg', 'label': '体重'},
      {'key': 'bmi', 'unit': '', 'label': 'BMI'},
      {'key': 'bodyFat', 'unit': '%', 'label': '体脂率'},
      {'key': 'chest', 'unit': 'cm', 'label': '胸围'},
      {'key': 'waist', 'unit': 'cm', 'label': '腰围'},
      {'key': 'hip', 'unit': 'cm', 'label': '臀围'},
      {'key': 'armCircumference', 'unit': 'cm', 'label': '上臂围'},
      {'key': 'thighCircumference', 'unit': 'cm', 'label': '大腿围'},
      {'key': 'targetWeight', 'unit': 'kg', 'label': '目标体重'},
      {'key': 'restingHeartRate', 'unit': 'bpm', 'label': '静息心率'},
    ];

    // 取上一次记录作为趋势对比基线
    final history = Storage.getBodyDataHistory();
    final Map<String, dynamic>? prevBody =
        history.isNotEmpty ? history.last : null;

    // 收集需要展示的字段（值为 0 或 null 的字段不显示）
    final items = <_BodyFieldItem>[];
    for (final config in fieldConfigs) {
      final key = config['key'] as String;
      final v = body[key];
      final numValue = v is num
          ? v.toDouble()
          : double.tryParse(v?.toString() ?? '') ?? 0;
      if (numValue > 0) {
        // 趋势对比
        final prevV = prevBody?[key];
        final prevNum = prevV is num
            ? prevV.toDouble()
            : double.tryParse(prevV?.toString() ?? '') ?? 0;
        TrendDirection trend = TrendDirection.none;
        if (prevNum > 0) {
          if (numValue < prevNum) {
            trend = TrendDirection.down;
          } else if (numValue > prevNum) {
            trend = TrendDirection.up;
          }
        }
        items.add(_BodyFieldItem(
          value: _formatBodyValue(numValue),
          unit: config['unit'] as String,
          label: config['label'] as String,
          trend: trend,
        ));
      }
    }

    // 按 3 个一行分组展示
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final end = (i + 3 > items.length) ? items.length : i + 3;
      final rowItems = items.sublist(i, end);
      // 不足 3 个时补齐占位，保持等宽
      while (rowItems.length < 3) {
        rowItems.add(const _BodyFieldItem(value: '', unit: '', label: '', trend: TrendDirection.none));
      }
      rows.add(Row(
        children: rowItems
            .map((item) => _buildBodyItem(colors, item))
            .toList(),
      ));
      if (i + 3 < items.length) {
        rows.add(const SizedBox(height: 12));
        rows.add(const DividerWidget(indent: 0));
        rows.add(const SizedBox(height: 12));
      }
    }

    return CardWidget(
      onTap: () async {
        await context.push('/body-data');
        if (mounted) setState(() {});
      },
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
                '更新于 ${body['lastUpdate'] ?? '刚刚'}',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  /// 格式化身体数据数值：整数去掉 .0
  String _formatBodyValue(double v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  /// 判断是否存在有意义的身体数据（任一字段非 0 且非 null）
  bool _hasMeaningfulBodyData(Map<String, dynamic> body) {
    if (body.isEmpty) return false;
    const keys = [
      'height', 'weight', 'bmi', 'bodyFat', 'chest', 'waist', 'hip',
      'armCircumference', 'thighCircumference', 'targetWeight', 'restingHeartRate',
    ];
    for (final key in keys) {
      final v = body[key];
      final numValue = v is num
          ? v.toDouble()
          : double.tryParse(v?.toString() ?? '') ?? 0;
      if (numValue > 0) return true;
    }
    return false;
  }

  Widget _buildBodyItem(FitTrackColors colors, _BodyFieldItem item) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: item.value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.unit.isNotEmpty)
                  TextSpan(
                    text: item.unit,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // 趋势箭头：下降为正向绿色 ↓、上升为负向红色 ↑
          if (item.trend != TrendDirection.none)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.trend == TrendDirection.down
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    size: 12,
                    color: item.trend == TrendDirection.down
                        ? colors.successColor
                        : colors.warningColor,
                  ),
                ],
              ),
            ),
          Text(
            item.label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBodyDataCard(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        children: [
          Icon(Icons.accessibility_new, size: 48, color: colors.accentGlow),
          const SizedBox(height: 12),
          Text(
            '完善身体数据',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '记录你的身体数据，获取更精准的训练推荐',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await context.push('/body-data');
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('去填写', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(FitTrackColors colors, BuildContext ctx) {
    final menus = [
      {'icon': Icons.card_membership_outlined, 'label': '健身卡', 'page': 'gym-card'},
      {'icon': Icons.history, 'label': '训练记录', 'page': 'records'},
      {'icon': Icons.card_giftcard, 'label': '邀请有礼', 'page': 'invitation'},
      {'icon': Icons.sports_gymnastics, 'label': '动作库', 'page': 'exercise'},
      {'icon': Icons.edit_note, 'label': '训练笔记', 'page': 'note'},
      {'icon': Icons.settings, 'label': '设置', 'page': 'settings'},
      {'icon': Icons.notifications_active_outlined, 'label': '提醒设置', 'page': 'reminder-settings'},
      {'icon': Icons.security_outlined, 'label': '隐私与安全', 'action': 'privacy'},
      {'icon': Icons.help_outline, 'label': '帮助与反馈', 'action': 'help'},
    ];

    return Column(
      children: menus.map((m) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MenuButton(
            icon: m['icon'] as IconData,
            label: m['label'] as String,
            onTap: () {
              final page = m['page'] as String? ?? '';
              final action = m['action'] as String? ?? '';

              if (action == 'privacy') {
                _showPrivacyInfo();
              } else if (action == 'help') {
                _showHelpInfo();
              } else if (page.isNotEmpty) {
                switch (page) {
                  case 'gym-card':
                    context.push('/gym-card');
                    break;
                  case 'records':
                    context.push('/records');
                    break;
                  case 'invitation':
                    context.push('/invitation');
                    break;
                  case 'exercise':
                    context.push('/exercise');
                    break;
                  case 'tutorial':
                    context.push('/tutorial');
                    break;
                  case 'note':
                    context.push('/note');
                    break;
                  case 'settings':
                    context.push('/settings');
                    break;
                  case 'reminder-settings':
                    context.push('/reminder-settings');
                    break;
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }

  void _showPrivacyInfo() {
    InfoDialog.show(
      context,
      title: '隐私与安全',
      content:
        'FitTrack 尊重您的隐私：\n\n'
        '• 所有数据仅存储在本地设备\n'
        '• 不会上传任何个人信息到服务器\n'
        '• 通知权限仅用于训练提醒\n'
        '• 您可以随时在设置中清除所有数据',
      icon: Icons.security_outlined,
    );
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  void _showHelpInfo() {
    InfoDialog.show(
      context,
      title: '帮助与反馈',
      content:
        '使用帮助：\n\n'
        '1. 创建计划：在"计划"页面点击 + 号创建训练计划\n'
        '2. 开始训练：选择计划后点击"开始训练"按钮\n'
        '3. 休息提醒：训练中休息倒计时结束后会振动并通知提醒\n'
        '4. 自定义设置：在"设置"中调整默认休息时间、组数等\n\n'
        '常见问题：\n\n'
        '• 休息提醒未收到？请检查通知权限是否已开启\n'
        '• 后台休息提醒？从后台切回应用时会立即提醒\n'
        '• 数据丢失？数据保存在本地，卸载应用会清除数据\n\n'
        '如有问题或建议，欢迎反馈！',
      icon: Icons.help_outline,
    );
  }
}

/// 身体数据字段趋势方向
enum TrendDirection { none, up, down }

/// 身体数据字段展示项（含趋势）
class _BodyFieldItem {
  final String value;
  final String unit;
  final String label;
  final TrendDirection trend;

  const _BodyFieldItem({
    required this.value,
    required this.unit,
    required this.label,
    required this.trend,
  });
}
