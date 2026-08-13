import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final void Function(Map<String, dynamic> profileData) onQuestionnaireComplete;

  const OnboardingPage({
    super.key,
    required this.onComplete,
    required this.onQuestionnaireComplete,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.assignment_outlined,
      'title': '智能训练计划',
      'desc': '根据你的目标定制专属训练方案',
    },
    {
      'icon': Icons.fitness_center,
      'title': '详细动作指导',
      'desc': '每个动作都有详细步骤和要点说明',
    },
    {
      'icon': Icons.bar_chart,
      'title': '数据追踪分析',
      'desc': '全面记录训练数据，见证每一次进步',
    },
  ];

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      widget.onQuestionnaireComplete({});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiftTrackColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: widget.onComplete,
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(colors, slide);
                },
              ),
            ),
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? colors.accentGlow : colors.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? colors.textPrimary
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _slides.length - 1 ? '下一步' : '开始问卷',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(LiftTrackColors colors, Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colors.accentGlow.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              slide['icon'] as IconData,
              size: 64,
              color: colors.accentGlow,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide['title'] as String,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide['desc'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
