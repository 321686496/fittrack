import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../themes/app_themes.dart';

/// 邀请码海报内容组件（1080×1920 竖版）
///
/// 纯渲染组件，外层需用 [RepaintBoundary]（带 [GlobalKey]）包裹以便截图。
///
/// 结构：
/// - 品牌区：FitTrack 燃力 + 副标题"扫码加入，一起训练"
/// - 邀请码大字高亮（紫色背景圆角容器）
/// - 二维码（编码 `fittrack://invite?code=XXX`）
/// - 渐变背景：accentGlow.withOpacity(0.08) → bgSecondary
class InvitePoster extends StatelessWidget {
  final String inviteCode;
  final String deepLink;

  const InvitePoster({
    super.key,
    required this.inviteCode,
    required this.deepLink,
  });

  static const double posterWidth = 1080.0;
  static const double posterHeight = 1920.0;

  @override
  Widget build(BuildContext context) {
    final ft = Theme.of(context).extension<FitTrackColors>()!;
    return Container(
      width: posterWidth,
      height: posterHeight,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ft.accentGlow.withOpacity(0.08),
            ft.bgSecondary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // 品牌图标
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: ft.purpleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 56,
              color: ft.purpleColor,
            ),
          ),
          const SizedBox(height: 20),
          // 品牌区
          Text(
            'FitTrack 燃力',
            style: TextStyle(
              color: ft.textPrimary,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '扫码加入，一起训练',
            style: TextStyle(
              color: ft.textSecondary,
              fontSize: 28,
            ),
          ),
          const Spacer(),
          // 邀请码（大字高亮）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
            decoration: BoxDecoration(
              color: ft.purpleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: ft.purpleColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '我的邀请码',
                  style: TextStyle(
                    color: ft.textSecondary,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  inviteCode,
                  style: TextStyle(
                    color: ft.purpleColor,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 二维码
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ft.purpleColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: QrImageView(
              data: deepLink,
              version: QrVersions.auto,
              size: 280,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ft.textPrimary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: ft.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '使用 FitTrack 扫码加入',
            style: TextStyle(
              color: ft.textMuted,
              fontSize: 22,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
