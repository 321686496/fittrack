import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/achievement_service.dart';
import '../themes/app_themes.dart';
import '../widgets/common_widgets.dart';
import '../widgets/page_header.dart';

class HonorWallPage extends StatefulWidget {
  const HonorWallPage({super.key});

  @override
  State<HonorWallPage> createState() => _HonorWallPageState();
}

class _HonorWallPageState extends State<HonorWallPage> {
  List<Achievement> _all = [];
  List<Achievement> _unlocked = [];
  List<Achievement> _locked = [];

  @override
  void initState() {
    super.initState();
    _all = AchievementService.instance.getAll();
    _unlocked = _all.where((a) => a.unlocked).toList()
      ..sort((a, b) => (b.unlockedAt ?? 0).compareTo(a.unlockedAt ?? 0));
    _locked = _all.where((a) => !a.unlocked).toList();
  }

  String _formatDate(int? ts) {
    if (ts == null) return '已解锁';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.year}/${d.month}/${d.day}';
  }

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'streak': return Icons.local_fire_department;
      case 'weight': return Icons.fitness_center;
      case 'duration': return Icons.timer;
      case 'month': return Icons.calendar_month;
      case 'explore': return Icons.explore;
      case 'plan': return Icons.assignment_turned_in;
      case 'share': return Icons.share;
      default: return Icons.emoji_events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final total = _all.length;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            title: '荣誉墙',
            isTabPage: false,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部统计
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.accentGlow.withOpacity(0.1),
                          colors.accentGlow.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('已解锁',
                                  style: TextStyle(
                                      color: colors.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${_unlocked.length}',
                                  style: TextStyle(
                                      color: colors.accentGlow,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: colors.borderColor),
                        Expanded(
                          child: Column(
                            children: [
                              Text('总徽章',
                                  style: TextStyle(
                                      color: colors.textMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$total',
                                  style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 最近解锁大展示
                  if (_unlocked.isNotEmpty) ...[
                    const SectionHeader(title: '最近解锁'),
                    const SizedBox(height: 12),
                    _buildRecentHonor(colors, _unlocked.first),
                    const SizedBox(height: 24),
                  ],
                  // 荣誉墙网格
                  const SectionHeader(title: '荣誉墙'),
                  const SizedBox(height: 12),
                  _buildHonorGrid(colors),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHonor(FitTrackColors colors, Achievement ach) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accentGlow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colors.accentGlow.withOpacity(0.3),
                  colors.accentGlow.withOpacity(0.1),
                ],
              ),
              border: Border.all(color: colors.accentGlow.withOpacity(0.5), width: 2),
            ),
            child: Icon(_iconFor(ach.icon),
                size: 40, color: colors.accentGlow),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ach.title,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ach.description,
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text('解锁于 ${_formatDate(ach.unlockedAt)}',
                    style: TextStyle(
                        color: colors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHonorGrid(FitTrackColors colors) {
    if (_all.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 64, color: colors.textMuted.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('暂无徽章',
                  style: TextStyle(color: colors.textMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }
    // 排序：已解锁按 unlockedAt 倒序在前，未解锁按原始顺序在后
    final gridItems = <Achievement>[
      ..._unlocked,
      ..._locked,
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: gridItems.length,
      itemBuilder: (ctx, i) {
        final ach = gridItems[i];
        return _buildHonorCell(colors, ach);
      },
    );
  }

  Widget _buildHonorCell(FitTrackColors colors, Achievement ach) {
    if (ach.unlocked) {
      return GestureDetector(
        onTap: () => InfoDialog.show(
          context,
          title: ach.title,
          content: '${ach.description}\n\n解锁于 ${_formatDate(ach.unlockedAt)}',
          icon: _iconFor(ach.icon),
          iconColor: colors.accentGlow,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.accentGlow.withOpacity(0.25),
                      colors.accentGlow.withOpacity(0.08),
                    ],
                  ),
                ),
                child: Icon(_iconFor(ach.icon),
                    size: 32, color: colors.accentGlow),
              ),
              const SizedBox(height: 12),
              Text(
                ach.title,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(ach.unlockedAt),
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    // 未解锁：灰度显示 + lock 覆盖图标，点击弹解锁条件
    return GestureDetector(
      onTap: () => InfoDialog.show(
        context,
        title: ach.title,
        content: '未解锁\n\n解锁条件：${ach.description}',
        icon: Icons.lock_outline,
        iconColor: colors.textMuted,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor.withOpacity(0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      0.4, 0,
                  ]),
                  child: Opacity(
                    opacity: 0.4,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.textMuted.withOpacity(0.2),
                      ),
                      child: Icon(_iconFor(ach.icon),
                          size: 32, color: colors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ach.title,
                  style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '未解锁',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ],
            ),
            // 锁图标覆盖在徽章右上
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(Icons.lock,
                    size: 14, color: colors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
