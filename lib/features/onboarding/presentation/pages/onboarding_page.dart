import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/theme/app_theme.dart';
import 'adult_ownership_ack_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Welcome to AuraLearn',
      description: 'Your AI-powered education companion that helps you understand any question instantly.',
      imagePath: 'assets/images/onboarding_1.png',
      color: AppTheme.primary,
    ),
    OnboardingItem(
      title: 'Capture Questions',
      description: 'Take photos of textbooks, homework, or screens. Support up to 3 images per question.',
      imagePath: 'assets/images/onboarding_2.png',
      color: AppTheme.secondary,
    ),
    OnboardingItem(
      title: 'Smart Cropping',
      description: 'Use our advanced crop tool to select exactly the question you need help with.',
      imagePath: 'assets/images/onboarding_3.png',
      color: AppTheme.accent,
    ),
    OnboardingItem(
      title: 'Instant Answers',
      description: 'Get detailed explanations and step-by-step solutions powered by AI.',
      imagePath: 'assets/images/onboarding_4.png',
      color: AppTheme.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _goToAcknowledgment,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
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
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildOnboardingItem(_items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page indicator
            _buildPageIndicator(),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentIndex == _items.length - 1
                          ? _goToAcknowledgment
                          : _nextPage,
                      child: Text(_currentIndex == _items.length - 1
                          ? 'Get Started'
                          : 'Next'),
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

  Widget _buildOnboardingItem(OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getIconForIndex(_currentIndex),
                size: 120,
                color: item.color,
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _items.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentIndex == index ? 32.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? AppTheme.primary
                : AppTheme.border,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.school;
      case 1:
        return Icons.camera_alt;
      case 2:
        return Icons.crop;
      case 3:
        return Icons.lightbulb;
      default:
        return Icons.school;
    }
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AdultOwnershipAckPage(),
      ),
    );
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