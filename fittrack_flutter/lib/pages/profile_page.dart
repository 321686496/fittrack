import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../services/user_profile_generator.dart';
import '../services/form_kit_service.dart';
import '../services/ohos_reminder_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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
    AchievementDialog.show(
      context,
      icon: achievement['icon'] as String,
      name: achievement['name'] as String,
      desc: achievement['desc'] as String,
      onDone: onDismiss,
    );
  }

  void _showAchievementDetail(Map<String, dynamic> achievement) {
    final unlocked = achievement['unlocked'] as bool;
    InfoDialog.show(
      context,
      title: achievement['name'] as String,
      content: unlocked
          ? '${achievement['desc']}\n\n已达成'
          : '进度: ${achievement['progressText'] ?? achievement['desc']}',
      icon: unlocked ? Icons.emoji_events : Icons.lock_outline,
      iconColor: unlocked ? null : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final body = Storage.getBodyData();

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
                if (body.isEmpty)
                  _buildNoBodyDataCard(colors)
                else
                  _buildBodyData(colors, body),
                const SizedBox(height: 20),
                _buildMenuList(colors, context),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final records = Storage.getRecords();
    final recentCount = records.length > 5 ? 5 : records.length;

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.6,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        _buildNotificationItem(colors, Icons.tips_and_updates, '每日贴士', MockData.dailyTip['text'] as String),
                      ],
                    ),
            ),
          ],
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
    final settings = Storage.getSettings();
    final userName = settings['userName'] as String? ?? '用户';
    final gender = settings['gender'] as String? ?? '';
    final goal = settings['fitnessGoal'] as String? ?? '';
    final level = settings['fitnessLevel'] as String? ?? '';
    final avatarEmoji = settings['avatarEmoji'] as String? ?? '💪';
    final avatarBgColor = settings['avatarBgColor'] as int? ?? 0xFFFF6B35;

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
        child: Row(
          children: [
            UserProfileGenerator.buildAvatarWidget(
              {'emoji': avatarEmoji, 'bgColor': avatarBgColor},
              size: 60,
              borderColor: Color(avatarBgColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
      ),
    );
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
                      final now = TimeOfDay.now();
                      final initialTime = trainingTime.isNotEmpty
                          ? _parseTimeOfDay(trainingTime)
                          : const TimeOfDay(hour: 18, minute: 0);
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: initialTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: colors.bgCard,
                                hourMinuteTextColor: colors.textPrimary,
                                dialHandColor: colors.accentGlow,
                                dialBackgroundColor: colors.bgSecondary,
                                entryModeIconColor: colors.accentGlow,
                              ),
                            ),
                            child: child!,
                          );
                        },
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
                        setState(() {});
                        // 更新卡片数据（训练时间变更）
                        if (Platform.isOhos) {
                          FormKitService.instance.pushFormData();
                          // 重新发布训练提醒
                          if (trainingTime.isNotEmpty) {
                            OhosReminderService.instance.scheduleTrainingReminder(
                              title: '训练时间到',
                              content: '你设定的训练时间已到，开始今天的训练吧！',
                              timeStr: trainingTime,
                            );
                          } else {
                            OhosReminderService.instance.cancelTrainingReminder();
                          }
                        }
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

  Widget _buildNoBodyDataCard(FitTrackColors colors) {
    return CardWidget(
      child: Column(
        children: [
          Icon(Icons.accessibility_new_outlined, size: 40, color: colors.textMuted),
          const SizedBox(height: 10),
          Text('暂未录入身体数据', style: TextStyle(color: colors.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showBodyDataEditor(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentGlow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('录入数据', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBodyDataEditor(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final body = Storage.getBodyData();
    final heightCtrl = TextEditingController(text: body['height']?.toString() ?? '');
    final weightCtrl = TextEditingController(text: body['weight']?.toString() ?? '');
    final bmiCtrl = TextEditingController(text: body['bmi']?.toString() ?? '');
    final bodyFatCtrl = TextEditingController(text: body['bodyFat']?.toString() ?? '');
    final chestCtrl = TextEditingController(text: body['chest']?.toString() ?? '');
    final waistCtrl = TextEditingController(text: body['waist']?.toString() ?? '');
    final hipCtrl = TextEditingController(text: body['hip']?.toString() ?? '');

    FitBottomSheet.show(
      context: context,
      maxHeightRatio: 0.8,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('录入身体数据', style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildBodyInputField(colors, '身高 (cm)', heightCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, '体重 (kg)', weightCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, 'BMI', bmiCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, '体脂率 (%)', bodyFatCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, '胸围 (cm)', chestCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, '腰围 (cm)', waistCtrl),
              const SizedBox(height: 12),
              _buildBodyInputField(colors, '臀围 (cm)', hipCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final w = double.tryParse(weightCtrl.text) ?? 0;
                    final h = double.tryParse(heightCtrl.text) ?? 0;
                    final bmi = h > 0 ? (w / ((h / 100) * (h / 100))).toStringAsFixed(1) : '';
                    Storage.saveBodyData({
                      'height': double.tryParse(heightCtrl.text) ?? 0,
                      'weight': w,
                      'bmi': bmiCtrl.text.isNotEmpty ? double.tryParse(bmiCtrl.text) : (bmi.isNotEmpty ? double.tryParse(bmi) : 0),
                      'bodyFat': double.tryParse(bodyFatCtrl.text) ?? 0,
                      'chest': double.tryParse(chestCtrl.text) ?? 0,
                      'waist': double.tryParse(waistCtrl.text) ?? 0,
                      'hip': double.tryParse(hipCtrl.text) ?? 0,
                      'lastUpdate': '刚刚',
                    });
                    Navigator.of(ctx).pop();
                    setState(() {});
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
  }

  Widget _buildBodyInputField(FitTrackColors colors, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colors.accentGlow)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(FitTrackColors colors, BuildContext ctx) {
    final menus = [
      {'icon': Icons.card_membership_outlined, 'label': '健身卡', 'page': 'gym-card'},
      {'icon': Icons.history, 'label': '训练记录', 'page': 'records'},
      {'icon': Icons.sports_gymnastics, 'label': '动作库', 'page': 'exercise'},
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
                    context.go('/records');
                    break;
                  case 'exercise':
                    context.push('/exercise');
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
