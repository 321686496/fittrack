import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'poster_theme.dart';

/// 邀请码海报（海报2，对应 HTML #2，含底部下载引导）
///
/// 宽度 1080 固定、高度随内容自适应（不限定固定高度，避免内容竖向溢出；
/// 由捕获层 Path B 按内容实际高度渲染）。使用 [PosterBackground] 跟随主题。
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
    return SizedBox(
      width: posterWidth,
      child: PosterBackground(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PosterBrandHeader(colors: colors, subtitle: 'INVITE'),
            SizedBox(height: px(11)),
            // ── 主题语 ────────────────────────────
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '好友邀你 ',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(22),
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: '一起变强',
                    style: TextStyle(
                      fontSize: px(22),
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ).createShader(
                          const Rect.fromLTWH(0, 0, 400, 80),
                        ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: px(4)),
            Text(
              '激活邀请 · 领新人礼包，马上开练',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: px(11),
              ),
            ),
            SizedBox(height: px(11)),
            // ── 新人礼包 · 独立大幅主视觉 ──────────
            _buildGiftCard(colors),
            SizedBox(height: px(8)),
            // ── 它解决你训练的痛点 ─────────────────
            _buildSectionTitle(colors, '它解决你训练的痛点'),
            SizedBox(height: px(7)),
            Row(
              children: [
                _buildPainCard(
                    colors, Icons.view_stream_rounded, '实时训练', '组数一目了然'),
                SizedBox(width: px(6)),
                _buildPainCard(
                    colors, Icons.schedule_rounded, '休息提醒', '掌控休息节奏'),
                SizedBox(width: px(6)),
                _buildPainCard(
                    colors, Icons.location_on_outlined, '练哪提醒', '今天该练哪'),
              ],
            ),
            SizedBox(height: px(8)),
            // ── 带你体验完整训练 ───────────────────
            _buildSectionTitle(colors, '带你体验完整训练'),
            SizedBox(height: px(7)),
            Row(
              children: [
                _buildModCard(
                    colors, Icons.format_list_bulleted, '训练计划', '分阶段照着练'),
                SizedBox(width: px(7)),
                _buildModCard(
                    colors, Icons.compare_arrows_rounded, '虚拟对手PK', '积分兑限定皮肤'),
              ],
            ),
            SizedBox(height: px(7)),
            Row(
              children: [
                _buildModCard(colors, Icons.menu_book_outlined, '动作教学', '图文分步教学'),
                SizedBox(width: px(7)),
                _buildModCard(
                    colors, Icons.confirmation_number_outlined, '健身卡', '到期次数提醒'),
              ],
            ),
            SizedBox(height: px(7)),
            Row(
              children: [
                _buildModCard(colors, Icons.trending_up_rounded, '数据统计', '进步曲线记录'),
                SizedBox(width: px(7)),
                _buildModCard(
                    colors, Icons.workspace_premium_outlined, '成就徽章', '积分兑徽章称号'),
              ],
            ),
            SizedBox(height: px(11)),
            // ── 邀请码小卡 ────────────────────────
            _buildInviteCard(colors),
            SizedBox(height: px(14)),
            // ── 底部情绪文案 + 下载引导 ────────────
            _buildDownloadFooter(colors),
          ],
        ),
      ),
    );
  }

  /// 新人礼包主视觉
  Widget _buildGiftCard(PosterColors colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: px(14), vertical: px(10)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.brand, colors.brandSecondary],
        ),
        borderRadius: BorderRadius.circular(px(20)),
        boxShadow: [
          BoxShadow(
            color: colors.brand.withOpacity(0.30),
            blurRadius: px(32),
            offset: Offset(0, px(16)),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 装饰光圈
          Positioned(
            top: -px(40),
            right: -px(30),
            child: Container(
              width: px(140),
              height: px(140),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -px(48),
            left: -px(28),
            child: Container(
              width: px(120),
              height: px(120),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.11),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, size: px(15), color: Colors.white),
                  SizedBox(width: px(6)),
                  Text(
                    '新人礼包 · 激活即得',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: px(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: px(1),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: px(13), vertical: px(5)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.24),
                          blurRadius: px(18),
                          offset: Offset(0, px(8)),
                        ),
                      ],
                    ),
                    child: Text(
                      '领新人礼',
                      style: TextStyle(
                        color: colors.brand,
                        fontSize: px(11),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: px(4)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+50',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: px(34),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: px(6)),
                    child: Text(
                      '积分',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: px(15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: px(7)),
                    child: Text(
                      '激活即到账 · 直接兑换',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: px(9.5),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: px(7)),
              Row(
                children: [
                  _ptag('限定皮肤'),
                  SizedBox(width: px(5)),
                  _ptag('成就徽章'),
                  SizedBox(width: px(5)),
                  _ptag('头像框'),
                  SizedBox(width: px(5)),
                  _ptag('专属称号'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ptag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: px(8), vertical: px(2)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: px(8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 小节标题（短渐变条 + 文字）
  Widget _buildSectionTitle(PosterColors colors, String text) {
    return Row(
      children: [
        Container(
          width: px(14),
          height: px(3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.brand, colors.brandSecondary],
            ),
            borderRadius: BorderRadius.circular(px(2)),
          ),
        ),
        SizedBox(width: px(6)),
        Text(
          text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: px(10),
            fontWeight: FontWeight.w700,
            letterSpacing: px(1),
          ),
        ),
      ],
    );
  }

  /// 痛点三卡
  Widget _buildPainCard(
      PosterColors colors, IconData icon, String title, String sub) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: px(6), vertical: px(8)),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(px(16)),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(7)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: px(13), color: colors.brand),
            SizedBox(height: px(4)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: px(10),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: px(2)),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: px(9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// “带你体验完整训练”模块卡
  Widget _buildModCard(PosterColors colors, IconData icon, String title,
      String sub) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: px(9), vertical: px(7)),
        decoration: BoxDecoration(
          color: colors.cardBg,
          borderRadius: BorderRadius.circular(px(12)),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(color: colors.brand.withOpacity(0.10), blurRadius: px(7)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: px(14), color: colors.brand),
            SizedBox(width: px(6)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: px(10),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: px(2)),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: px(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 邀请码小卡（二维码 + 代码输入）
  Widget _buildInviteCard(PosterColors colors) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: px(13), vertical: px(9)),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(px(16)),
        border: Border.all(color: colors.cardBorder, width: px(1.5)),
      ),
      child: Row(
        children: [
          // 二维码
          Container(
            width: px(56),
            height: px(56),
            padding: EdgeInsets.all(px(5)),
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
              data: deepLink,
              version: QrVersions.auto,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: colors.textPrimary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: colors.textPrimary,
              ),
              // 兜底：数据过长无法编码时，避免渲染成白底空容器
              errorStateBuilder: (context, error) => Center(
                child: Icon(Icons.qr_code, size: px(10), color: colors.textMuted),
              ),
            ),
          ),
          SizedBox(width: px(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '扫码 或 输入好友邀请码',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: px(10),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: px(3)),
                Text(
                  inviteCode,
                  style: TextStyle(
                    color: colors.brand,
                    fontSize: px(14),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: px(2)),
                Text(
                  '激活即领新人礼包 · 双方都有奖励',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: px(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 底部情绪文案 + 下载引导
  Widget _buildDownloadFooter(PosterColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '别辜负每一次想练的冲动 · 扫码现在开始',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: px(11),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.4,
          ),
        ),
        SizedBox(height: px(7)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _downloadPill(
                colors, Icons.grid_view_rounded, '华为应用市场 · LiftTrack'),
            SizedBox(width: px(6)),
            _downloadPill(colors, Icons.apple, 'App Store · LiftTrack'),
          ],
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