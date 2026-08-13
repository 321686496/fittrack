import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../widgets/page_header.dart';

/// 风格主题设置页面
/// 支持"跟随系统"模式，可分别选择日间/夜间主题
class ThemeSettingsPage extends StatefulWidget {
  final String currentThemeId;
  final bool followSystem;
  final String lightThemeId;
  final String darkThemeId;
  final void Function(String themeId, {bool? followSystem, String? lightThemeId, String? darkThemeId}) onThemeChanged;

  const ThemeSettingsPage({
    super.key,
    required this.currentThemeId,
    required this.followSystem,
    required this.lightThemeId,
    required this.darkThemeId,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late PageController _pageController;
  int _currentPage = 0;
  late String _selectedThemeId;
  late bool _followSystem;
  late String _lightThemeId;
  late String _darkThemeId;

  @override
  void initState() {
    super.initState();
    _selectedThemeId = widget.currentThemeId;
    _followSystem = widget.followSystem;
    _lightThemeId = widget.lightThemeId;
    _darkThemeId = widget.darkThemeId;
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
    if (themeId == _selectedThemeId && !_followSystem) return;
    setState(() => _selectedThemeId = themeId);
    if (_followSystem) {
      _saveAndNotify();
    } else {
      final settings = Storage.getSettings();
      settings['theme'] = themeId;
      Storage.saveSettings(settings);
      widget.onThemeChanged(themeId);
    }
  }

  void _toggleFollowSystem(bool value) {
    setState(() => _followSystem = value);
    _saveAndNotify();
  }

  void _setLightTheme(String themeId) {
    setState(() => _lightThemeId = themeId);
    _saveAndNotify();
  }

  void _setDarkTheme(String themeId) {
    setState(() => _darkThemeId = themeId);
    _saveAndNotify();
  }

  void _saveAndNotify() {
    final settings = Storage.getSettings();
    settings['followSystem'] = _followSystem;
    settings['lightThemeId'] = _lightThemeId;
    settings['darkThemeId'] = _darkThemeId;
    settings['theme'] = _selectedThemeId;
    Storage.saveSettings(settings);
    widget.onThemeChanged(
      _selectedThemeId,
      followSystem: _followSystem,
      lightThemeId: _lightThemeId,
      darkThemeId: _darkThemeId,
    );
  }

  LiftTrackColors _getThemeColors(String themeId) {
    final themeData = AppTheme.getTheme(themeId);
    return themeData.extension<LiftTrackColors>()!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      backgroundColor: colors.bgSecondary,
      body: Column(
        children: [
          PageHeader(
            onBack: () => context.pop(),
            title: '风格主题',
          ),
          // ---- 跟随系统开关 ----
          _buildFollowSystemToggle(colors),
          // ---- 内容区 ----
          Expanded(
            child: _followSystem ? _buildFollowSystemContent(colors) : _buildThemePickerContent(colors),
          ),
        ],
      ),
    );
  }

  // ============ 跟随系统开关 ============

  Widget _buildFollowSystemToggle(LiftTrackColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.brightness_auto, color: _followSystem ? colors.accentGlow : colors.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('跟随系统', style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                Text('自动切换日间/夜间模式', style: TextStyle(color: colors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _followSystem,
            onChanged: _toggleFollowSystem,
            activeColor: colors.accentGlow,
          ),
        ],
      ),
    );
  }

  // ============ 跟随系统模式：分别选择日间/夜间主题 ============

  Widget _buildFollowSystemContent(LiftTrackColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('日间主题', Icons.wb_sunny, colors),
          const SizedBox(height: 8),
          _buildThemeChipGroup(
            allThemeIds: LiftTrackTheme.lightThemeIds,
            selectedId: _lightThemeId,
            onSelect: _setLightTheme,
            colors: colors,
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('夜间主题', Icons.nightlight_round, colors),
          const SizedBox(height: 8),
          _buildThemeChipGroup(
            allThemeIds: LiftTrackTheme.darkThemeIds,
            selectedId: _darkThemeId,
            onSelect: _setDarkTheme,
            colors: colors,
          ),
          const SizedBox(height: 32),
          // 预览区
          _buildDualPreview(colors),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, LiftTrackColors colors) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.accentGlow),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildThemeChipGroup({
    required List<String> allThemeIds,
    required String selectedId,
    required void Function(String) onSelect,
    required LiftTrackColors colors,
  }) {
    final themes = AppTheme.themes;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allThemeIds.map((id) {
        final theme = themes.firstWhere((t) => t['id'] == id);
        final isSelected = id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentGlow.withOpacity(0.12) : colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colors.accentGlow : colors.borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(theme['icon'] as String, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  theme['name'] as String,
                  style: TextStyle(
                    color: isSelected ? colors.accentGlow : colors.textPrimary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDualPreview(LiftTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('预览效果', Icons.preview, colors),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniPreview(_lightThemeId, '日间', colors),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniPreview(_darkThemeId, '夜间', colors),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniPreview(String themeId, String label, LiftTrackColors parentColors) {
    final tc = _getThemeColors(themeId);
    return Column(
      children: [
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: tc.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: parentColors.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _buildMiniPreviewContent(tc),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: parentColors.textMuted, fontSize: 12)),
      ],
    );
  }

  Widget _buildMiniPreviewContent(LiftTrackColors tc) {
    return Column(
      children: [
        // header
        Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: tc.bgSecondary,
            border: Border(bottom: BorderSide(color: tc.borderColor, width: 0.5)),
          ),
          child: Row(
            children: [
              Container(width: 40, height: 8, decoration: BoxDecoration(color: tc.textPrimary, borderRadius: BorderRadius.circular(2))),
              const Spacer(),
              Container(width: 14, height: 14, decoration: BoxDecoration(border: Border.all(color: tc.borderColor, width: 0.5), borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 4),
              Container(width: 14, height: 14, decoration: BoxDecoration(border: Border.all(color: tc.borderColor, width: 0.5), borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
        // body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // card
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tc.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tc.borderColor, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: tc.accentGlow, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 4),
                            Container(width: 30, height: 6, decoration: BoxDecoration(color: tc.textPrimary, borderRadius: BorderRadius.circular(1))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(width: 40, height: 8, decoration: BoxDecoration(color: tc.textPrimary, borderRadius: BorderRadius.circular(1))),
                        const SizedBox(height: 4),
                        Container(width: 50, height: 5, decoration: BoxDecoration(color: tc.textMuted, borderRadius: BorderRadius.circular(1))),
                        const SizedBox(height: 6),
                        Container(width: 30, height: 10, decoration: BoxDecoration(color: tc.accentGlow, borderRadius: BorderRadius.circular(5))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // bottom row
                Expanded(
                  flex: 2,
                  child: Row(
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: tc.bgCard,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: tc.borderColor, width: 0.5),
                          ),
                          child: Center(
                            child: Container(width: 12, height: 6, decoration: BoxDecoration(color: [tc.accentGlow, tc.infoColor, tc.warningColor, tc.successColor][i], borderRadius: BorderRadius.circular(1))),
                          ),
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

  // ============ 不跟随系统：原有 PageView 主题选择 ============

  Widget _buildThemePickerContent(LiftTrackColors colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('滑动选择你喜欢的主题', style: TextStyle(color: colors.textMuted, fontSize: 13)),
          ),
        ),
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
    );
  }

  Widget _buildThemeCard(Map<String, dynamic> theme, LiftTrackColors colors) {
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
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Expanded(child: _buildThemePreview(themeId, themeColors)),
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
                          style: TextStyle(color: colors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
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
                              style: TextStyle(color: colors.accentGlow, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(theme['desc'] as String, style: TextStyle(color: colors.textMuted, fontSize: 13)),
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

  Widget _buildThemePreview(String themeId, LiftTrackColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final maxW = constraints.maxWidth;
        double previewW;
        double previewH;
        if (maxH * 9.0 / 16.0 <= maxW) {
          previewH = maxH;
          previewW = maxH * 9.0 / 16.0;
        } else {
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

  Widget _buildPreviewContent(LiftTrackColors colors, double w, double h) {
    final scale = h / 600.0;
    final padH = 12.0 * scale;
    final padV = 8.0 * scale;
    final gap = 6.0 * scale;
    final cardRadius = 8.0 * scale;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            border: Border(bottom: BorderSide(color: colors.borderColor, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: w * 0.35, height: 14 * scale,
                      decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2)),
                    ),
                    SizedBox(height: 4 * scale),
                    Container(
                      width: w * 0.22, height: 9 * scale,
                      decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24 * scale, height: 24 * scale,
                decoration: BoxDecoration(border: Border.all(color: colors.borderColor, width: 0.5), borderRadius: BorderRadius.circular(6 * scale)),
              ),
              SizedBox(width: 6 * scale),
              Container(
                width: 24 * scale, height: 24 * scale,
                decoration: BoxDecoration(border: Border.all(color: colors.borderColor, width: 0.5), borderRadius: BorderRadius.circular(6 * scale)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(padH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        Row(
                          children: [
                            Container(width: 16 * scale, height: 16 * scale, decoration: BoxDecoration(color: colors.accentGlow, borderRadius: BorderRadius.circular(4 * scale))),
                            SizedBox(width: 6 * scale),
                            Container(width: w * 0.2, height: 9 * scale, decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2))),
                            const Spacer(),
                            Container(width: 24 * scale, height: 9 * scale, decoration: BoxDecoration(color: colors.infoColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4 * scale))),
                          ],
                        ),
                        SizedBox(height: 8 * scale),
                        Container(width: w * 0.3, height: 12 * scale, decoration: BoxDecoration(color: colors.textPrimary, borderRadius: BorderRadius.circular(2))),
                        SizedBox(height: 4 * scale),
                        Container(width: w * 0.42, height: 8 * scale, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2))),
                        SizedBox(height: 8 * scale),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(value: 0.6, backgroundColor: colors.bgSecondary, valueColor: AlwaysStoppedAnimation(colors.accentGlow), minHeight: 5 * scale),
                        ),
                        SizedBox(height: 8 * scale),
                        Container(width: w * 0.22, height: 14 * scale, decoration: BoxDecoration(color: colors.accentGlow, borderRadius: BorderRadius.circular(7 * scale))),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gap),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
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
                            Container(width: cellW * 0.4, height: 6 * scale, decoration: BoxDecoration(color: isToday ? colors.accentGlow : colors.textMuted, borderRadius: BorderRadius.circular(1))),
                            SizedBox(height: 4 * scale),
                            Container(width: 6 * scale, height: 6 * scale, decoration: BoxDecoration(color: isToday ? colors.accentGlow : colors.textMuted.withOpacity(0.4), shape: BoxShape.circle)),
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

  Widget _buildMiniStatCard(LiftTrackColors colors, double scale, double parentW, Color accentColor) {
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
          Container(width: 16 * scale, height: 6 * scale, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(1))),
          SizedBox(height: 4 * scale),
          Container(width: parentW * 0.1, height: 8 * scale, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(LiftTrackColors colors) {
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

  Widget _buildApplyButton(LiftTrackColors colors) {
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