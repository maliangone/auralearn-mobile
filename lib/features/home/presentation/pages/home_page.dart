import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../subscription/presentation/bloc/subscription_bloc.dart';
import '../../../subscription/presentation/bloc/subscription_event.dart';
import '../../../flashcards/domain/repositories/flashcard_repository.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/recent_question_card.dart';
import '../widgets/hero_camera_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(SubscriptionStatusRequested());
    // Load real history for the "最近解题" section (latest 3 shown).
    context.read<HistoryBloc>().add(const HistoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refreshData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ----------------------------------------------------------------
              // App bar: greeting
              // ----------------------------------------------------------------
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: AppColors.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final name = state is AuthAuthenticated
                        ? (state.user.name?.split(' ').first ?? '同学')
                        : '同学';
                    return _GreetingHeader(name: name);
                  },
                ),
                titleSpacing: AppSpacing.base,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 22,
                    ),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      // TODO: notifications
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),

              // ----------------------------------------------------------------
              // Body content
              // ----------------------------------------------------------------
              SliverToBoxAdapter(
                child: AnimationLimiter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 320),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 24.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // --------------------------------------------------
                          // Hero: camera CTA
                          // --------------------------------------------------
                          HeroCameraButton(
                            onTap: () => context.goNamed('camera'),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // --------------------------------------------------
                          // Secondary quick action: type a question
                          // --------------------------------------------------
                          _SecondaryActionRow(
                            onTypeQuestion: () => context.goNamed('question'),
                            onViewHistory: () => context.goNamed('history'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // --------------------------------------------------
                          // Usage indicator (only when authenticated)
                          // --------------------------------------------------
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state is AuthAuthenticated) {
                                return const Column(
                                  children: [
                                    UsageIndicator(),
                                    SizedBox(height: AppSpacing.xxl),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // --------------------------------------------------
                          // Study: review + error book
                          // --------------------------------------------------
                          _SectionHeader(title: AppLocalizations.of(context).homeStudy),

                          const SizedBox(height: AppSpacing.md),

                          _StudyActionRow(
                            onReview: () =>
                                context.goNamed('flashcard-review'),
                            onErrorBook: () => context.goNamed('errorbook'),
                            onDocuments: () => context.goNamed('documents'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // --------------------------------------------------
                          // Recent questions
                          // --------------------------------------------------
                          _SectionHeader(
                            title: AppLocalizations.of(context).homeRecent,
                            action: AppLocalizations.of(context).viewAll,
                            onAction: () => context.goNamed('history'),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          const _RecentQuestionsSection(),

                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ),
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

  Future<void> _refreshData() async {
    context.read<SubscriptionBloc>().add(SubscriptionStatusRequested());
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

// ----------------------------------------------------------------------------
// Greeting header
// ----------------------------------------------------------------------------
class _GreetingHeader extends StatelessWidget {
  final String name;
  const _GreetingHeader({required this.name});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return '早上好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting，$name',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
        ),
        const SizedBox(height: 1),
        Text(
          '有题目不会做？拍一张就懂了',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// Secondary action row: type + history
// ----------------------------------------------------------------------------
class _SecondaryActionRow extends StatelessWidget {
  final VoidCallback onTypeQuestion;
  final VoidCallback onViewHistory;

  const _SecondaryActionRow({
    required this.onTypeQuestion,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionTile(
            icon: Icons.edit_outlined,
            label: '文字提问',
            onTap: onTypeQuestion,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryActionTile(
            icon: Icons.history_rounded,
            label: '历史记录',
            onTap: onViewHistory,
          ),
        ),
      ],
    );
  }
}

class _SecondaryActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Study action row: 今日复习 (with due badge) + 错题本
// ----------------------------------------------------------------------------
class _StudyActionRow extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onErrorBook;
  final VoidCallback onDocuments;

  const _StudyActionRow({
    required this.onReview,
    required this.onErrorBook,
    required this.onDocuments,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _StudyActionTile(
            icon: Icons.school_outlined,
            label: l.homeReview,
            badge: const _DueBadge(),
            onTap: onReview,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StudyActionTile(
            icon: Icons.menu_book_outlined,
            label: l.homeErrorBook,
            onTap: onErrorBook,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StudyActionTile(
            icon: Icons.folder_open_outlined,
            label: l.homeMyDocuments,
            onTap: onDocuments,
          ),
        ),
      ],
    );
  }
}

class _StudyActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? badge;
  final VoidCallback onTap;

  const _StudyActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.base,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          // Vertical layout: icon on top (with optional overlaid badge), a
          // single-line centered label below. Avoids the cramped 3-across
          // horizontal squeeze that wrapped labels mid-word.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, size: 22, color: AppColors.primary),
                  ),
                  if (badge != null)
                    Positioned(right: -6, top: -6, child: badge!),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A due-count badge for 今日复习. Reads `countDue(now)` from the flashcards
/// repository; on any failure (Left or thrown error) it renders nothing, and a
/// zero count is likewise hidden.
class _DueBadge extends StatelessWidget {
  const _DueBadge();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: getIt<FlashcardRepository>()
          .countDue(DateTime.now())
          .then((either) => either.fold((_) => 0, (count) => count)),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            (snapshot.data ?? 0) <= 0) {
          return const SizedBox.shrink();
        }
        final count = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------------
// Section header
// ----------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// Recent questions section — wired to HistoryBloc (latest 3 items)
// ----------------------------------------------------------------------------
class _RecentQuestionsSection extends StatelessWidget {
  const _RecentQuestionsSection();

  /// Formats a DateTime into a human-readable relative string in Chinese.
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        // Loading shimmer
        if (state is HistoryLoading || state is HistoryInitial) {
          return const _RecentLoadingPlaceholder();
        }

        // Populated — show latest 3
        if (state is HistoryLoaded && state.items.isNotEmpty) {
          final recent = state.items.take(3).toList();
          return Column(
            children: recent.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: RecentQuestionCard(
                  question: item.question?.isNotEmpty == true
                      ? item.question!
                      : '（无题目文字）',
                  subject: item.subject ?? '综合',
                  time: _formatTime(item.createdAt),
                  hasImages:
                      item.imageUrls != null && item.imageUrls!.isNotEmpty,
                  onTap: () => context.go('/history/detail/${item.id}'),
                ),
              );
            }).toList(),
          );
        }

        // Empty (HistoryEmpty, HistoryInitial after load, or error)
        return const _RecentEmptyState();
      },
    );
  }
}

class _RecentLoadingPlaceholder extends StatelessWidget {
  const _RecentLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '还没有解题记录',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '拍下第一道题，马上获得分步讲解',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
