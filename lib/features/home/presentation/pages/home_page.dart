import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/skeleton_box.dart';
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
    // Load real history for the recent section (latest 3 shown).
    context.read<HistoryBloc>().add(const HistoryLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
              // App bar: greeting + mascot
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
                        ? (state.user.name?.split(' ').first ??
                            l.greetingDefaultName)
                        : l.greetingDefaultName;
                    return _GreetingHeader(name: name);
                  },
                ),
                titleSpacing: AppSpacing.base,
                // TODO(notifications): bell icon removed until the feature
                // exists — an inert icon reads as a broken button.
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
                        duration: AppMotion.staggered,
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 24.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          const SizedBox(height: AppSpacing.md),

                          // Hero: camera CTA
                          HeroCameraButton(
                            onTap: () => context.goNamed('camera'),
                            label: l.homeHeroTitle,
                            sublabel: l.homeHeroSubtitle,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Secondary quick actions: type / history
                          _SecondaryActionRow(
                            onTypeQuestion: () => context.goNamed('question'),
                            onViewHistory: () => context.goNamed('history'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Usage indicator (only when authenticated)
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

                          // Study: review + error book + documents
                          AppSectionHeader(title: l.homeStudy),

                          const SizedBox(height: AppSpacing.md),

                          _StudyActionRow(
                            onReview: () =>
                                context.goNamed('flashcard-review'),
                            onErrorBook: () => context.goNamed('errorbook'),
                            onDocuments: () => context.goNamed('documents'),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          // Recent questions
                          AppSectionHeader(
                            title: l.homeRecent,
                            actionLabel: l.viewAll,
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
// Greeting header — time-of-day greeting, mascot on the right
// ----------------------------------------------------------------------------
class _GreetingHeader extends StatelessWidget {
  final String name;
  const _GreetingHeader({required this.name});

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.greetingMorning;
    if (hour < 18) return l.greetingAfternoon;
    return l.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting(l)}，$name',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
              ),
              const SizedBox(height: 1),
              Text(
                l.homeGreetingSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Mascot — Aura the spark. Falls back to nothing if the asset is
        // missing so a broken asset never breaks the header layout.
        SvgPicture.asset(
          'assets/brand/aura_wave.svg',
          width: 44,
          height: 44,
          placeholderBuilder: (_) => const SizedBox(width: 44, height: 44),
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
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _SecondaryActionTile(
            icon: Icons.edit_outlined,
            label: l.homeTextQuestion,
            accent: AppColors.primary,
            onTap: onTypeQuestion,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryActionTile(
            icon: Icons.history_rounded,
            label: l.homeHistory,
            accent: AppColors.primaryViolet,
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
  final Color accent;
  final VoidCallback onTap;

  const _SecondaryActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Study action row: 今日复习 (with due badge) + 错题本 + 我的资料
// Pastel colour-coded: review=indigo, mistakes=amber, materials=green.
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StudyActionTile(
            icon: Icons.school_rounded,
            label: l.homeReview,
            accent: AppColors.primary,
            badge: const _DueBadge(),
            onTap: onReview,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StudyActionTile(
            icon: Icons.menu_book_rounded,
            label: l.homeErrorBook,
            accent: AppColors.warningDark,
            onTap: onErrorBook,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StudyActionTile(
            icon: Icons.folder_open_rounded,
            label: l.homeMyDocuments,
            accent: AppColors.encourageDark,
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
  final Color accent;
  final Widget? badge;
  final VoidCallback onTap;

  const _StudyActionTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.clay(accent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Icon(icon, size: 24, color: accent),
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
// Recent questions section — wired to HistoryBloc (latest 3 items)
// ----------------------------------------------------------------------------
class _RecentQuestionsSection extends StatelessWidget {
  const _RecentQuestionsSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                      : l.historyNoQuestionText,
                  subject: item.subject ?? l.subjectGeneral,
                  time: formatTimeAgo(context, item.createdAt),
                  hasImages:
                      item.imageUrls != null && item.imageUrls!.isNotEmpty,
                  onTap: () => context.go('/history/detail/${item.id}'),
                ),
              );
            }).toList(),
          );
        }

        // Empty (HistoryEmpty, HistoryInitial after load, or error)
        return AppEmptyState(
          illustration: 'assets/illustrations/empty_history.svg',
          title: l.homeEmptyRecentTitle,
          subtitle: l.homeEmptyRecentSubtitle,
        );
      },
    );
  }
}

class _RecentLoadingPlaceholder extends StatelessWidget {
  const _RecentLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: SkeletonBox(height: 88, radius: AppRadius.card),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: SkeletonBox(height: 88, radius: AppRadius.card),
        ),
      ],
    );
  }
}
