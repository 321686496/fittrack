import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/recommendation_service.dart';
import '../themes/app_themes.dart';

class RecommendationBanner extends StatefulWidget {
  const RecommendationBanner({super.key});

  @override
  State<RecommendationBanner> createState() => _RecommendationBannerState();
}

class _RecommendationBannerState extends State<RecommendationBanner> {
  final _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;
  List<BannerItem> _banners = [];

  @override
  void initState() {
    super.initState();
    _banners = RecommendationService.generateBanners();
    if (_banners.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_controller.hasClients) {
          final next = (_currentPage + 1) % _banners.length;
          _controller.animateToPage(next,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _banners.length,
            itemBuilder: (ctx, i) => _buildBanner(_banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        _buildIndicator(),
      ],
    );
  }

  Widget _buildBanner(BannerItem banner) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    if (banner.type == 'invitation') {
      return _buildInvitationBanner(colors, banner);
    }
    final gradient = _gradientFor(banner.type, colors);

    return GestureDetector(
      onTap: () {
        if (banner.route != null) context.push(banner.route!);
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // 装饰几何：右上圆形光晕
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // 装饰几何：左下小圆
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '立即查看 →',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  /// 邀请有礼专属卡片：动态进度 + 进度条 + 动态 CTA
  Widget _buildInvitationBanner(LiftTrackColors colors, BannerItem banner) {
    final totalReferrals =
        (banner.extra?['totalReferrals'] as num?)?.toInt() ?? 0;
    final nextMilestone = (banner.extra?['nextMilestone'] as num?)?.toInt() ?? 1;
    final isAmbassador = banner.extra?['isAmbassador'] == true;
    final remaining = nextMilestone - totalReferrals;
    final progress = (totalReferrals / nextMilestone).clamp(0.0, 1.0).toDouble();

    final String ctaText;
    if (totalReferrals == 0) {
      ctaText = '邀请好友，双方得积分 →';
    } else if (remaining > 0) {
      ctaText = '还差 $remaining 人解锁奖励 →';
    } else {
      ctaText = '查看全部奖励 →';
    }

    return GestureDetector(
      onTap: () {
        if (banner.route != null) context.push(banner.route!);
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          gradient: _gradientFor('invitation', colors),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // 装饰几何：右上圆形光晕
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            // 装饰几何：左下小圆
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头部：礼物图标 + 标题 + 大使角标
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (isAmbassador)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '大使',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  // 进度文案
                  Text(
                    isAmbassador
                        ? '已邀请 $totalReferrals 人 · 大使'
                        : '已邀请 $totalReferrals / $nextMilestone 人',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 进度条
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: Colors.white.withOpacity(0.25),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 动态 CTA
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildIndicator() {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (i) {
        final isCurrent = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isCurrent ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isCurrent
                ? colors.accentGlow
                : colors.borderColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  LinearGradient _gradientFor(String type, LiftTrackColors colors) {
    switch (type) {
      case 'premium':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.warningColor,
            colors.warningColor.withOpacity(0.6),
          ],
        );
      case 'invitation':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.successColor,
            colors.successColor.withOpacity(0.6),
          ],
        );
      case 'achievement':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.purpleColor,
            colors.purpleColor.withOpacity(0.6),
          ],
        );
      case 'plan':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.purpleColor,
            colors.purpleColor.withOpacity(0.6),
          ],
        );
      default: // teaching
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accentGlow,
            colors.accentGlow.withOpacity(0.6),
          ],
        );
    }
  }
}
