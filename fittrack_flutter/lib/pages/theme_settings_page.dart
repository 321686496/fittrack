import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/page_header.dart';

/// 风格主题设置页面
/// 使用 PageView 滑动卡片方式展示所有可选主题
class ThemeSettingsPage extends StatefulWidget {
  final String currentThemeId;
  final void Function(String themeId) onThemeChanged;

  const ThemeSettingsPage({
    super.key,
    required this.currentThemeId,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late PageController _pageController;
  int _currentPage = 0;
  late String _selectedThemeId;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.currentThemeId;
    _pageController = PageController(viewportFraction: 0.92);
    final initialPage = AppTheme.themes.indexWhere((t) => t['id'] == widget.currentThemeId);
    _currentPage = initialPage >= 0 ? initialPage : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageController.jumpToPage(_currentPage);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTheme(String themeId) {
    if (themeId == _selectedThemeId) return;
    // Restrict to 2 themes for non-Pro users
    const freeThemes = {'vitality-sport', 'fresh-minimal'};
    if (!freeThemes.contains(themeId) && !Storage.isPremiumNotifier.value) {
      // Show upgrade prompt
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('升级 Pro'),
          content: const Text('解锁全部 7 套主题、高级统计、数据导出等权益'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/redeem');
              },
              child: const Text('去兑换'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => _selectedThemeId = themeId);
    final settings = Storage.getSettings();
    settings['theme'] = themeId;
    Storage.saveSettings(settings);
    widget.onThemeChanged(themeId);
  }

  FitTrackColors _getThemeColors(String themeId) {
    final themeData = AppTheme.getTheme(themeId);
    return themeData.extension<FitTrackColors>()!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '风格主题',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '滑动选择你喜欢的主题',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ),
          ),
          // PageView 占满中间区域
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: AppTheme.themes.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildThemeCard(AppTheme.themes[index], colors);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: _buildPageIndicator(colors),
          ),
          _buildApplyButton(colors),
        ],
      ),
    );
  }

  /// 构建单个主题卡片 — 撑满 PageView 可用高度
  Widget _buildThemeCard(Map<String, dynamic> theme, FitTrackColors colors) {
    final themeId = theme['id'] as String;
    final isSelected = themeId == _selectedThemeId;
    final themeColors = _getThemeColors(themeId);
    final palette = (theme['colors'] as List).map((c) => Color(c as int)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colors.accentGlow : colors.borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        // 卡片整体撑满 PageView 高度
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              // 预览图：占满除主题信息外的所有空间
              Expanded(child: _buildThemePreview(themeId, themeColors)),
            // 主题信息：固定在底部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(theme['icon'] as String, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        theme['name'] as String,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.accentGlow.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '当前主题',
                            style: TextStyle(
                              color: colors.accentGlow,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    theme['desc'] as String,
                    style: TextStyle(color: colors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: palette
                        .map((c) => Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  /// 预览图：9:16 手机比例，居中显示，占满分配空间
  Widget _buildThemePreview(String themeId, FitTrackColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 可用高度
        final maxH = constraints.maxHeight;
        // 可用宽度
        final maxW = constraints.maxWidth;
        // 9:16 比例：高度固定为可用高度，宽度 = 高度 * 9/16
        // 如果计算出的宽度超过可用宽度，则用宽度反推高度
        double previewW;
        double previewH;
        if (maxH * 9.0 / 16.0 <= maxW) {
          // 高度优先，宽度按比例
          previewH = maxH;
          previewW = maxH * 9.0 / 16.0;
        } else {
          // 宽度优先，高度按比例
          previewW = maxW;
          previewH = maxW * 16.0 / 9.0;
        }

        return Center(
          child: Container(
            width: previewW,
            height: previewH,
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: _buildPreviewContent(colors, previewW, previewH),
            ),
          ),
        );
      },
    );
  }

  /// 预览图内容：模拟首页布局，所有尺寸按预览区域比例计算
  Widget _buildPreviewContent(FitTrackColors colors, double w, double h) {
    // 比例系数
    final scale = h / 600.0; // 以 600 高度为基准缩放
    final padH = 12.0 * scale;
    final padV = 8.0 * scale;
    final gap = 6.0 * scale;
    final cardRadius = 8.0 * scale;

    return Column(
      children: [
        // ── 模拟 PageHeader ──
        Container(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            border: Border(
              bottom: BorderSide(color: colors.borderColor, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题
                    Container(
                      width: w * 0.35,
                      height: 14 * scale,
                      decoration: BoxDecoration(
                        color: colors.textPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    // 副标题
                    Container(
                      width: w * 0.22,
                      height: 9 * scale,
                      decoration: BoxDecoration(
                        color: colors.textMuted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              // 铃铛图标
              Container(
                width: 24 * scale,
                height: 24 * scale,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
              ),
              SizedBox(width: 6 * scale),
              // 日历图标
              Container(
                width: 24 * scale,
                height: 24 * scale,
                decoration: BoxDecoration(
                  border: Border.all(color: colors.borderColor, width: 0.5),
                  borderRadius: BorderRadius.circular(6 * scale),
                ),
              ),
            ],
          ),
        ),
        // ── 内容区 ──
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(padH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 今日训练卡片 ──（用 Expanded 占满上半部分）
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(padH),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: colors.borderColor, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 标题行
                        Row(
                          children: [
                            Container(
                              width: 16 * scale,
                              height: 16 * scale,
                              decoration: BoxDecoration(
                                color: colors.accentGlow,
                                borderRadius: BorderRadius.circular(4 * scale),
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            Container(
                              width: w * 0.2,
                              height: 9 * scale,
                              decoration: BoxDecoration(
                                color: colors.textPrimary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 24 * scale,
                              height: 9 * scale,
                              decoration: BoxDecoration(
                                color: colors.infoColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4 * scale),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8 * scale),
                        // 大标题
                        Container(
                          width: w * 0.3,
                          height: 12 * scale,
                          decoration: BoxDecoration(
                            color: colors.textPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        // 副标题
                        Container(
                          width: w * 0.42,
                          height: 8 * scale,
                          decoration: BoxDecoration(
                            color: colors.textMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        // 进度条
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: 0.6,
                            backgroundColor: colors.bgSecondary,
                            valueColor: AlwaysStoppedAnimation(colors.accentGlow),
                            minHeight: 5 * scale,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        // 按钮
                        Container(
                          width: w * 0.22,
                          height: 14 * scale,
                          decoration: BoxDecoration(
                            color: colors.accentGlow,
                            borderRadius: BorderRadius.circular(7 * scale),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gap),
                // ── 本周统计 2x2（两行各占 flex）──
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // 第一行
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildMiniStatCard(colors, scale, w, colors.accentGlow)),
                            SizedBox(width: gap),
                            Expanded(child: _buildMiniStatCard(colors, scale, w, colors.infoColor)),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      // 第二行
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildMiniStatCard(colors, scale, w, colors.warningColor)),
                            SizedBox(width: gap),
                            Expanded(child: _buildMiniStatCard(colors, scale, w, colors.successColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                // ── 本周日历 7 列 ──
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isToday = i == 1;
                      final cellW = (w - padH * 2 - gap * 6) / 7;
                      return Container(
                        width: cellW,
                        decoration: BoxDecoration(
                          color: isToday ? colors.accentGlow.withOpacity(0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4 * scale),
                          border: isToday ? Border.all(color: colors.accentGlow, width: 1) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: cellW * 0.4,
                              height: 6 * scale,
                              decoration: BoxDecoration(
                                color: isToday ? colors.accentGlow : colors.textMuted,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Container(
                              width: 6 * scale,
                              height: 6 * scale,
                              decoration: BoxDecoration(
                                color: isToday ? colors.accentGlow : colors.textMuted.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建预览图中的小统计卡片
  Widget _buildMiniStatCard(FitTrackColors colors, double scale, double parentW, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(6 * scale),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: colors.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16 * scale,
            height: 6 * scale,
            decoration: BoxDecoration(
              color: colors.textMuted,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          SizedBox(height: 4 * scale),
          Container(
            width: parentW * 0.1,
            height: 8 * scale,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(FitTrackColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AppTheme.themes.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? colors.accentGlow : colors.borderColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildApplyButton(FitTrackColors colors) {
    final currentTheme = AppTheme.themes[_currentPage];
    final isApplied = currentTheme['id'] == _selectedThemeId;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isApplied ? null : () => _selectTheme(currentTheme['id'] as String),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentGlow,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? colors.textPrimary : Colors.white,
              disabledBackgroundColor: colors.bgSecondary,
              disabledForegroundColor: colors.textMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isApplied ? '已应用' : '应用此主题',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
