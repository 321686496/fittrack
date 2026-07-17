import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/mock_data.dart';
import '../data/storage.dart';
import '../services/user_profile_generator.dart';
import '../services/form_kit_service.dart';
import '../services/points_service.dart';
import '../services/achievement_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';
import '../widgets/custom_time_picker.dart';
import '../utils/platform_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
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

  void _showAchievementDetail(Achievement a) {
    InfoDialog.show(
      context,
      title: a.title,
      content: a.unlocked
          ? '${a.description}\n\n已达成'
          : '进度: ${a.description}',
      icon: a.unlocked ? Icons.emoji_events : Icons.lock_outline,
      iconColor: a.unlocked ? null : Colors.grey,
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
            // v1 获客留存版：全免费策略，不展示 Pro 升级入口
            // Pro/兑换码体系已编码但 v1 不启用，后续版本可通过 isPremiumNotifier 恢复展示
            Icon(Icons.chevron_right, color: colors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(FitTrackColors colors) {
    final points = PointsService.instance.points;
    final earnedTotal = Storage.getSettings()['pointsEarnedTotal'] ?? 0;
    final spentTotal = Storage.getSettings()['pointsSpentTotal'] ?? 0;

    return GestureDetector(
      onTap: () => context.push('/points-detail'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.accentGlow.withOpacity(0.08), colors.accentGlow.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: colors.accentGlow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.stars_rounded, color: colors.accentGlow, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('我的积分', style: TextStyle(
                    color: colors.textMuted, fontSize: 12,
                  )),
                  const SizedBox(height: 4),
                  Text('$points', style: TextStyle(
                    color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 2),
                  Text('累计获得 $earnedTotal · 累计消耗 $spentTotal', style: TextStyle(
                    color: colors.textMuted, fontSize: 11,
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted),
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
                        setState(() {});
                        // 更新卡片数据（训练时间变更）
                        if (isOhos) {
                          FormKitService.instance.pushFormData();
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
    final achievements = AchievementService.instance.getAll();
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final display = unlocked.isNotEmpty ? unlocked.take(6).toList() : achievements.take(3).toList();
    final hasUnlocked = unlocked.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('成就', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.push('/achievements'),
              child: Text('查看全部', style: TextStyle(color: colors.accentGlow, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: display.length,
          itemBuilder: (ctx, i) {
            final a = display[i];
            return GestureDetector(
              onTap: () => _showAchievementDetail(a),
              child: Opacity(
                opacity: a.unlocked ? 1.0 : 0.4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: a.unlocked ? colors.accentGlow.withOpacity(0.3) : colors.borderColor,
                      width: a.unlocked ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _achievementIcon(a.icon),
                        size: 28,
                        color: a.unlocked ? colors.accentGlow : colors.textMuted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
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
                        a.description,
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (!hasUnlocked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('完成训练解锁更多成就', style: TextStyle(color: colors.textMuted, fontSize: 12)),
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

    final items = <Map<String, String>>[];
    for (final config in fieldConfigs) {
      final v = body[config['key']];
      final numValue = v is num
          ? v.toDouble()
          : double.tryParse(v?.toString() ?? '') ?? 0;
      if (numValue > 0) {
        items.add({
          'value': _formatBodyValue(numValue),
          'unit': config['unit'] as String,
          'label': config['label'] as String,
        });
      }
    }

    // 按 4 个一行分组展示
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 4) {
      final end = (i + 4 > items.length) ? items.length : i + 4;
      final rowItems = items.sublist(i, end);
      // 不足 4 个时补齐占位，保持等宽
      while (rowItems.length < 4) {
        rowItems.add({'value': '', 'unit': '', 'label': ''});
      }
      rows.add(Row(
        children: rowItems.map((item) => _buildBodyItem(
              colors,
              item['value']!,
              item['unit']!,
              item['label']!,
            )).toList(),
      ));
      if (i + 4 < items.length) {
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
      {'icon': Icons.sports_gymnastics, 'label': '动作库', 'page': 'exercise'},
      {'icon': Icons.school_outlined, 'label': '动作教学', 'page': 'tutorial'},
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
