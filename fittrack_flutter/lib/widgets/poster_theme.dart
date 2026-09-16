import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/storage.dart';

import '../l10n/i18n.dart';
/// 海报基准尺寸（与 design/share_posters_gallery.html 保持一致）
const double kPosterW = 1080.0;
const double kPosterH = 1920.0;

/// HTML 设计稿以 304px 宽预览，等比缩放自 1080 宽；此处换算比例
const double kP = kPosterW / 304.0; // ≈ 3.553

/// 将 HTML 设计稿（304 基准）的 px 换算为 1080 宽海报的 Flutter 逻辑像素
double px(double htmlPx) => htmlPx * kP;

/// 海报配色（跟随用户当前 App 主题）
///
/// 通过 [PosterColors.fromThemeId] 工厂根据 themeId 解析对应主题色，
/// 保证分享海报与应用内主题视觉一致。每个主题包含：
/// 背景渐变 + 品牌主色/副色 + 三档文字色 + 卡片底色/边框色。
class PosterColors {
  final Color bgTop;
  final Color bgBottom;
  final Color brand;
  final Color brandSecondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color success;
  final Color warning;
  final bool isDark;

  PosterColors({
    required this.bgTop,
    required this.bgBottom,
    required this.brand,
    required this.brandSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.success,
    required this.warning,
    required this.isDark,
  });

  /// 根据主题 ID 解析海报配色。
  /// - themeId 为 null：从全局 Settings 读取当前用户主题
  /// - 未知 themeId：回退到活力运动
  factory PosterColors.fromThemeId(String? themeId) {
    // null 表示由调用方读取当前用户设置
    if (themeId == null) {
      final settingsTheme = Storage.getSettings()['theme'] as String?;
      return PosterColors.fromThemeId(settingsTheme ?? 'vitality-sport');
    }
    switch (themeId) {
      case 'vitality-sport':
        return PosterColors(
          bgTop: const Color(0xFFF5EDE8),
          bgBottom: const Color(0xFFF1E3DB),
          brand: const Color(0xFFC4705A),
          brandSecondary: const Color(0xFFD6906F),
          textPrimary: const Color(0xFF3E3733),
          textSecondary: const Color(0xFF6E655E),
          textMuted: const Color(0xFFA79D94),
          cardBg: const Color(0x1AC4705A),
          cardBorder: const Color(0x2EC4705A),
          success: const Color(0xFF8FB6A8),
          warning: const Color(0xFFD9B48A),
          isDark: false,
        );
      case 'blossom':
        return PosterColors(
          bgTop: const Color(0xFFF6ECEF),
          bgBottom: const Color(0xFFF1E1E7),
          brand: const Color(0xFFC68B96),
          brandSecondary: const Color(0xFFD6A1AC),
          textPrimary: const Color(0xFF3D3036),
          textSecondary: const Color(0xFF6E5A62),
          textMuted: const Color(0xFFA8949B),
          cardBg: const Color(0x1AC68B96),
          cardBorder: const Color(0x33C68B96),
          success: const Color(0xFF8FB0A0),
          warning: const Color(0xFFD6B58A),
          isDark: false,
        );
      case 'silver-care':
        return PosterColors(
          bgTop: const Color(0xFFEFF3EE),
          bgBottom: const Color(0xFFE5EDE3),
          brand: const Color(0xFF7FA08A),
          brandSecondary: const Color(0xFF93B09B),
          textPrimary: const Color(0xFF2E362F),
          textSecondary: const Color(0xFF5C685E),
          textMuted: const Color(0xFF97A099),
          cardBg: const Color(0x1F7FA08A),
          cardBorder: const Color(0x387FA08A),
          success: const Color(0xFF7FA08A),
          warning: const Color(0xFFD0A868),
          isDark: false,
        );
      case 'fresh-minimal':
        return PosterColors(
          bgTop: const Color(0xFFEDF1F5),
          bgBottom: const Color(0xFFE2EBF0),
          brand: const Color(0xFF7E9DAE),
          brandSecondary: const Color(0xFF96B4C3),
          textPrimary: const Color(0xFF2F3940),
          textSecondary: const Color(0xFF5B6A72),
          textMuted: const Color(0xFF96A4AC),
          cardBg: const Color(0x1F7E9DAE),
          cardBorder: const Color(0x387E9DAE),
          success: const Color(0xFF7FA08A),
          warning: const Color(0xFFD0A868),
          isDark: false,
        );
      case 'iron-forge':
        return PosterColors(
          bgTop: const Color(0xFF1D1516),
          bgBottom: const Color(0xFF241C1B),
          brand: const Color(0xFFC08478),
          brandSecondary: const Color(0xFFD09A8C),
          textPrimary: const Color(0xFFF4ECE9),
          textSecondary: const Color(0xFFBBA79F),
          textMuted: const Color(0xFF6E5E5A),
          cardBg: const Color(0x24C08478),
          cardBorder: const Color(0x47C08478),
          success: const Color(0xFF8FB6A8),
          warning: const Color(0xFFD9B48A),
          isDark: true,
        );
      case 'neon-cyber':
        return PosterColors(
          bgTop: const Color(0xFF1B1720),
          bgBottom: const Color(0xFF221C2C),
          brand: const Color(0xFFA695B8),
          brandSecondary: const Color(0xFFB9A9CC),
          textPrimary: const Color(0xFFF1EBF5),
          textSecondary: const Color(0xFFB9AEC4),
          textMuted: const Color(0xFF6E6280),
          cardBg: const Color(0x24A695B8),
          cardBorder: const Color(0x47A695B8),
          success: const Color(0xFF8FB0A0),
          warning: const Color(0xFFD6B58A),
          isDark: true,
        );
      case 'black-gold':
        return PosterColors(
          bgTop: const Color(0xFF171512),
          bgBottom: const Color(0xFF201B15),
          brand: const Color(0xFFC9A96A),
          brandSecondary: const Color(0xFFDEBF7A),
          textPrimary: const Color(0xFFF4EFDF),
          textSecondary: const Color(0xFFB9AE93),
          textMuted: const Color(0xFF6E6252),
          cardBg: const Color(0x24C9A96A),
          cardBorder: const Color(0x4DC9A96A),
          success: const Color(0xFF8FB0A0),
          warning: const Color(0xFFDEBF7A),
          isDark: true,
        );
      default:
        return PosterColors.fromThemeId('vitality-sport');
    }
  }

  /// 从全局 Settings 读取当前主题并返回对应海报配色
  factory PosterColors.fromCurrentSettings() {
    final themeId = Storage.getSettings()['theme'] as String?;
    return PosterColors.fromThemeId(themeId);
  }
}

/// 海报统一渐变背景 + 装饰光晕（对应 HTML `.poster` + `::before/::after`）
///
/// 内部已包含 HTML 海报的内边距（竖直 22px、水平 26px → 换算 1080）。
class PosterBackground extends StatelessWidget {
  final Widget child;
  final PosterColors colors;

  const PosterBackground({
    super.key,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // 说明：内容区使用【非定位】的 Padding 作为 Stack 的唯一非定位子组件，
    // 以便 Stack 在"无界高度（海报截图/可变高度海报）"约束下能按内容高度
    // 自适应撑开；在"固定高度"约束下，因外层约束有界而填满。
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(px(26)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.bgTop, colors.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // 右上角品牌色光晕（HTML .poster::before）
          Positioned(
            top: -px(60),
            right: -px(40),
            child: Container(
              width: px(180),
              height: px(180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.brand.withOpacity(colors.isDark ? 0.14 : 0.34),
                    colors.brand.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // 左下角副色光晕（HTML .poster::after）
          Positioned(
            bottom: -px(50),
            left: -px(40),
            child: Container(
              width: px(150),
              height: px(150),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.brandSecondary
                        .withOpacity(colors.isDark ? 0.10 : 0.24),
                    colors.brandSecondary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // 内容区（含内边距）—— 非定位，使高度随内容自适应
          Padding(
            padding: EdgeInsets.fromLTRB(
              px(26),
              px(22),
              px(26),
              px(22),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 海报统一品牌头部（对应 HTML `.brand` + `.brand-line`）
///
/// 小尺寸：26px 白色 logo 盒 + “LiftTrack” 主名 + 英文小副标 + 渐变装饰线。
/// 可选 [trailing] 置于最右侧（如“精选 / 胸肌 / 月卡·通用”徽标）。
class PosterBrandHeader extends StatelessWidget {
  final String subtitle;
  final PosterColors colors;
  final Widget? trailing;

  const PosterBrandHeader({
    super.key,
    required this.colors,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // logo 盒
            Container(
              width: px(26),
              height: px(26),
              padding: EdgeInsets.all(px(26) * 0.12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(px(9)),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withOpacity(colors.isDark ? 0.35 : 0.20),
                    blurRadius: px(10),
                    offset: Offset(0, px(4)),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(px(4)),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: px(26) * 0.76,
                    height: px(26) * 0.76,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(width: px(10)),
            // 品牌名 + 英文副标
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LiftTrack',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: px(15),
                    fontWeight: FontWeight.w800,
                    letterSpacing: px(1),
                    height: 1,
                  ),
                ),
                SizedBox(height: px(3)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: px(9),
                    letterSpacing: px(2),
                    height: 1,
                  ),
                ),
              ],
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ],
        ),
        // 渐变装饰线
        Container(
          width: px(42),
          height: px(3),
          margin: EdgeInsets.only(top: px(7)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.brand, colors.brandSecondary],
            ),
            borderRadius: BorderRadius.circular(px(2)),
          ),
        ),
      ],
    );
  }
}

/// 通用徽标（对应 HTML `.badge`）
class PostBadge extends StatelessWidget {
  final String text;
  final PosterColors colors;

  const PostBadge({
    super.key,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: px(10),
        vertical: px(3),
      ),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.brand,
          fontSize: px(10),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 海报统一底部二维码区（对应 HTML `.qrf`）
class PosterQrFooter extends StatelessWidget {
  final String qrData;
  final String hint;
  final String sub;
  final PosterColors colors;

  const PosterQrFooter({
    super.key,
    required this.qrData,
    required this.hint,
    required this.colors,
    this.sub = 'LiftTrack · 训练',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 二维码
        Container(
          width: px(50),
          height: px(50),
          padding: EdgeInsets.all(px(3)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(px(11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: px(10),
                offset: Offset(0, px(4)),
              ),
            ],
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            gapless: true,
            backgroundColor: Colors.white,
            // 二维码用近黑色高对比绘制，避免使用主题 textPrimary（部分浅色主题
            // 下颜色太浅，整体缩小后几乎看不清，也影响扫码）。
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1C1C1E),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1C1C1E),
            ),
            // 兜底：数据过长无法编码时，避免渲染成白底空容器
            errorStateBuilder: (context, error) => Center(
              child: Icon(Icons.qr_code, size: px(9), color: colors.textMuted),
            ),
          ),
        ),
        SizedBox(width: px(11)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hint,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: px(12),
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: px(5)),
              Text(
                sub,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: px(9),
                  letterSpacing: px(1),
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 海报底部应用市场下载引导（源自邀请海报 #2 底部）
///
/// 展示一句"去哪下载"情绪文案 + 华为应用市场 / App Store 两个下载渠道。
/// 用于无有效二维码海报的底部填充，与邀请海报共用同一套视觉与文案模板。
/// [headline] 不传时，从 [kPosterEmotionalSlogans] 中随机选一条情感文案。
class PosterDownloadFooter extends StatelessWidget {
  final PosterColors colors;

  /// 顶部"去哪下载"情绪文案；不传则每次随机展示一条情感文案
  final String? headline;

  const PosterDownloadFooter({
    super.key,
    required this.colors,
    this.headline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          headline ?? randomEmotionalSlogan(),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: px(11),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: px(7)),
        // 防英文门店名较长时水平溢出：放得下就原比例，放不下自动等比缩小
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _downloadPill(
                  colors, Icons.grid_view_rounded, tr(context, '华为应用市场 · LiftTrack')),
              SizedBox(width: px(6)),
              _downloadPill(colors, Icons.apple, 'App Store · LiftTrack'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _downloadPill(PosterColors colors, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: px(10), vertical: px(4)),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: px(10), color: colors.brand),
          SizedBox(width: px(4)),
          Text(
            text,
            style: TextStyle(
              color: colors.brand,
              fontSize: px(8.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 海报底部下载引导的情绪化文案池（每次分享随机展示一条）
List<String> kPosterEmotionalSlogans = [
  trn( '别辜负每一次想练的冲动'),
  trn( '每一滴汗水，都算数'),
  trn( '坚持，是对自己最好的礼物'),
  trn( '想练就练，别等明天'),
  trn( '别让它只是想想而已'),
];

/// 从 [kPosterEmotionalSlogans] 随机选取一条情感文案
String randomEmotionalSlogan() {
  return kPosterEmotionalSlogans[Random().nextInt(kPosterEmotionalSlogans.length)];
}