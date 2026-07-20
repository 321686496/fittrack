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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
    );
  }

  Widget _buildBanner(BannerItem banner) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    final gradient = _gradientFor(banner.type, colors);

    return GestureDetector(
      onTap: () {
        if (banner.route != null) context.push(banner.route!);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
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

  Widget _buildIndicator() {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
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

  LinearGradient _gradientFor(String type, FitTrackColors colors) {
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
