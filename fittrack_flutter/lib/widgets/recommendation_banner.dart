import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../themes/app_themes.dart';
import '../services/recommendation_service.dart';

class RecommendationBanner extends StatefulWidget {
  final List<BannerItem> items;
  const RecommendationBanner({super.key, required this.items});

  @override
  State<RecommendationBanner> createState() => _RecommendationBannerState();
}

class _RecommendationBannerState extends State<RecommendationBanner> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final next = (_current + 1) % widget.items.length;
        _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _bgColor(FitTrackColors colors, String type) {
    switch (type) {
      case 'teaching':
        return colors.accentGlow;
      case 'premium':
        return colors.warningColor;
      case 'invitation':
        return colors.successColor;
      case 'achievement':
        return Colors.purple;
      default:
        return colors.accentGlow;
    }
  }

  IconData _iconData(String? name) {
    const map = {
      'school': Icons.school,
      'lock': Icons.lock,
      'card_giftcard': Icons.card_giftcard,
      'emoji_events': Icons.emoji_events,
    };
    return map[name] ?? Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) {
              final item = widget.items[i];
              final bg = _bgColor(colors, item.type);
              return GestureDetector(
                onTap: () {
                  if (item.route != null) context.push(item.route!);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bg.withOpacity(0.15), bg.withOpacity(0.05)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: bg.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: bg.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconData(item.icon), color: bg, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.title, style: TextStyle(
                              color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(item.subtitle, style: TextStyle(
                              color: colors.textMuted, fontSize: 12,
                            ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.items.length, (i) {
            final active = i == _current;
            return Container(
              width: active ? 16 : 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? colors.accentGlow : colors.borderColor,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
