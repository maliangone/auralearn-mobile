import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  List<OnboardingItem> _items(AppLocalizations l) => [
        OnboardingItem(
          title: l.onboarding1Title,
          description: l.onboarding1Desc,
          imagePath: 'assets/onboarding/onboarding_capture.svg',
          color: AppColors.primary,
        ),
        OnboardingItem(
          title: l.onboarding2Title,
          description: l.onboarding2Desc,
          imagePath: 'assets/onboarding/onboarding_explain.svg',
          color: AppColors.encourage,
        ),
        OnboardingItem(
          title: l.onboarding3Title,
          description: l.onboarding3Desc,
          imagePath: 'assets/onboarding/onboarding_review.svg',
          color: AppColors.warning,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = _items(l);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: TextButton(
                  onPressed: _goToAcknowledgment,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  child: Text(
                    l.onboardingSkip,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildOnboardingItem(items[index], index),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            _buildPageIndicator(items.length),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: Text(l.onboardingPrevious),
                      ),
                    ),
                  if (_currentIndex > 0)
                    const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentIndex == items.length - 1
                          ? _goToAcknowledgment
                          : _nextPage,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: Text(_currentIndex == items.length - 1
                          ? l.onboardingGetStarted
                          : l.onboardingNext),
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

  Widget _buildOnboardingItem(OnboardingItem item, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive illustration: cap at 300 but shrink on short screens.
        final circleSize = math.min(300.0, constraints.maxHeight * 0.42);
        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration — brand SVG inside a soft pastel circle.
                Container(
                  height: circleSize,
                  width: circleSize,
                  padding: EdgeInsets.all(circleSize * 0.14),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(item.imagePath),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Title
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.base),

                // Description
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          height: 8.0,
          width: _currentIndex == index ? 32.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? AppColors.primary
                : AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Routes to the mandatory parent/teacher ownership acknowledgment.
  ///
  /// Both "Skip" and the final "Get Started" funnel through here, so the
  /// age-gate cannot be bypassed even when the carousel is skipped. The
  /// onboarding-completed + adult-ownership flags are persisted there, not
  /// here, ensuring onboarding only completes after acknowledgment.
  void _goToAcknowledgment() {
    context.push('/onboarding/adult-ack');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String imagePath;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.color,
  });
}
