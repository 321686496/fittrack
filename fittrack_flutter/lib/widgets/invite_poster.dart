import 'package:flutter/material.dart';
import 'poster_theme.dart';

/// 邀请码海报内容组件（宽度固定 1080，高度随内容自适应）
///
/// 纯渲染组件，外层需用 [RepaintBoundary]（带 [GlobalKey]）包裹以便截图。
/// 使用 [PosterBackground] 跟随用户当前 App 主题。
class InvitePoster extends StatelessWidget {
  final String inviteCode;
  final String deepLink;

  /// 海报主题 ID；为 null 时从全局 Settings 读取当前主题
  final String? themeId;

  const InvitePoster({
    super.key,
    required this.inviteCode,
    required this.deepLink,
    this.themeId,
  });

  static const double posterWidth = 1080.0;

  @override
  Widget build(BuildContext context) {
    final colors = PosterColors.fromThemeId(themeId);
    return PosterBackground(
      colors: colors,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 顶部品牌区 ────────────────────────────
            PosterBrandHeader(colors: colors),
            const SizedBox(height: 72),
            // ── 邀请码卡片（核心视觉焦点）──────────────
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 56, vertical: 48),
                decoration: BoxDecoration(
                  color: colors.cardBg,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: colors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: colors.brand.withOpacity(0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 装饰光点
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.brand.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '我的邀请码',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 邀请码大字
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: colors.brand.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.brand.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        inviteCode,
                        style: TextStyle(
                          color: colors.brand,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '双方均可获得积分奖励',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // ── 副标题 ───────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    '扫码加入',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '一起开启燃力训练之旅',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // ── 底部二维码 ───────────────────────────
            PosterQrFooter(
              colors: colors,
              qrData: deepLink,
              hint: '扫码加入 FitTrack',
            ),
          ],
        ),
      ),
    );
  }
}
