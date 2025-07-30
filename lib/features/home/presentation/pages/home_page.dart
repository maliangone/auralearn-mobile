import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_question_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Load subscription status and recent questions
    context.read<SubscriptionBloc>().add(SubscriptionStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.surface,
                elevation: 0,
                leading: null,
                automaticallyImplyLeading: false,
                title: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${state.user.name ?? 'Student'}! 👋',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'What would you like to learn today?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }
                    return const Text('AuraLearn');
                  },
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Implement notifications
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder: (widget) => SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // Usage indicator
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: UsageIndicator(),
                        ),

                        // Quick actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Actions',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: QuickActionCard(
                                      icon: Icons.camera_alt,
                                      title: 'Take Photo',
                                      subtitle: 'Capture question',
                                      color: AppTheme.primary,
                                      onTap: () => context.go('/camera'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: QuickActionCard(
                                      icon: Icons.edit,
                                      title: 'Type Question',
                                      subtitle: 'Write manually',
                                      color: AppTheme.secondary,
                                      onTap: () => context.go('/question'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Recent questions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Questions',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/history'),
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildRecentQuestions(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Features section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Features',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFeaturesList(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentQuestions() {
    // Mock data for recent questions
    final recentQuestions = [
      {
        'id': '1',
        'question': 'What is the derivative of x²?',
        'subject': 'Mathematics',
        'time': '2 hours ago',
        'hasImages': false,
      },
      {
        'id': '2',
        'question': 'Explain photosynthesis process',
        'subject': 'Biology',
        'time': '1 day ago',
        'hasImages': true,
      },
      {
        'id': '3',
        'question': 'How to solve quadratic equations?',
        'subject': 'Algebra',
        'time': '2 days ago',
        'hasImages': false,
      },
    ];

    if (recentQuestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No questions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by asking your first question!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentQuestions.map((question) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: RecentQuestionCard(
            question: question['question'] as String,
            subject: question['subject'] as String,
            time: question['time'] as String,
            hasImages: question['hasImages'] as bool,
            onTap: () {
              context.go('/history/detail/${question['id']}');
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.photo_camera,
        'title': 'Multi-Image Capture',
        'description': 'Upload up to 3 images per question for comprehensive answers',
      },
      {
        'icon': Icons.crop,
        'title': 'Smart Cropping',
        'description': 'Precisely select question areas with our advanced crop tool',
      },
      {
        'icon': Icons.psychology,
        'title': 'AI-Powered Explanations',
        'description': 'Get detailed step-by-step solutions and explanations',
      },
      {
        'icon': Icons.category,
        'title': 'Auto-Categorization',
        'description': 'Questions are automatically organized by subject and topic',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _refreshData() async {
    // Refresh subscription status and recent questions
    context.read<SubscriptionBloc>().add(SubscriptionStatusRequested());
    // TODO: Refresh recent questions
    await Future.delayed(const Duration(seconds: 1));
  }
} 