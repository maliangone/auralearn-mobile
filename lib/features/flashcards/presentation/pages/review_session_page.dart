import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/sm2.dart';
import '../bloc/review_bloc.dart';
import '../bloc/review_event.dart';
import '../bloc/review_state.dart';

/// Today's review — the spaced-repetition review session.
///
/// Route: `/flashcards/review`. Shows one due card at a time: the front
/// (problem / prompt), tap to flip to the back (answer / explanation), then one
/// of four rating buttons (again / hard / good / easy) drives SM-2 and
/// advances. Covers empty and done states.
class ReviewSessionPage extends StatefulWidget {
  const ReviewSessionPage({super.key});

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReviewBloc>().add(const LoadDue());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.reviewTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocBuilder<ReviewBloc, ReviewState>(
        builder: (context, state) {
          if (state is ReviewLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          if (state is ReviewError) {
            return _ReviewError(message: state.message);
          }

          if (state is ReviewEmpty) {
            return const _ReviewEmpty();
          }

          if (state is ReviewDone) {
            return _ReviewDone(reviewed: state.reviewed);
          }

          if (state is ReviewInProgress) {
            return _ReviewBody(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// In-progress body: progress + flip card + rating buttons
// ---------------------------------------------------------------------------
class _ReviewBody extends StatelessWidget {
  final ReviewInProgress state;
  const _ReviewBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final card = state.current;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            _ProgressBar(position: state.position, total: state.total),
            const SizedBox(height: AppSpacing.base),
            Expanded(
              child: _FlipCard(
                card: card,
                flipped: state.flipped,
                onTap: () =>
                    context.read<ReviewBloc>().add(const FlipCard()),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            if (state.flipped)
              const _RatingButtons()
            else
              const _FlipHint(),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int position;
  final int total;
  const _ProgressBar({required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : position / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$position / $total',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _FlipCard extends StatelessWidget {
  final Flashcard card;
  final bool flipped;
  final VoidCallback onTap;

  const _FlipCard({
    required this.card,
    required this.flipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isBack = flipped;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: isBack ? AppColors.encourageLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isBack
                  ? AppColors.encourage.withValues(alpha: 80 / 255)
                  : AppColors.border,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isBack
                          ? Icons.lightbulb_outline
                          : Icons.help_outline_rounded,
                      size: 18,
                      color: isBack
                          ? AppColors.encourage
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isBack ? l.reviewAnswer : l.reviewQuestion,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: isBack
                                    ? AppColors.encourage
                                    : AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const Spacer(),
                    if (card.subject != null && card.subject!.isNotEmpty)
                      _SubjectChip(subject: card.subject!),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  isBack
                      ? (card.back.isEmpty ? l.questionNoAnswer : card.back)
                      : (card.front.isEmpty
                          ? l.historyNoQuestionText
                          : card.front),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipHint extends StatelessWidget {
  const _FlipHint();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 18, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.reviewTapToFlip,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

class _RatingButtons extends StatelessWidget {
  const _RatingButtons();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        _RatingButton(
          rating: ReviewRating.again,
          label: l.reviewAgain,
          color: AppColors.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        _RatingButton(
          rating: ReviewRating.hard,
          label: l.reviewHard,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        _RatingButton(
          rating: ReviewRating.good,
          label: l.reviewGood,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        _RatingButton(
          rating: ReviewRating.easy,
          label: l.reviewEasy,
          color: AppColors.encourage,
        ),
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final ReviewRating rating;
  final String label;
  final Color color;

  const _RatingButton({
    required this.rating,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FilledButton(
        onPressed: () =>
            context.read<ReviewBloc>().add(RateCard(rating)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.textOnPrimary,
          // 16 * 2 + label height keeps the target comfortably ≥44px.
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textOnPrimary,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / done / error
// ---------------------------------------------------------------------------
class _ReviewEmpty extends StatelessWidget {
  const _ReviewEmpty();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppEmptyState(
      illustration: 'assets/illustrations/empty_review.svg',
      title: l.reviewNoneToday,
      ctaLabel: l.homeGoSolve,
      onCta: () => context.go('/camera'),
      inline: true,
    );
  }
}

class _ReviewDone extends StatelessWidget {
  final int reviewed;
  const _ReviewDone({required this.reviewed});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration_outlined,
                size: 64, color: AppColors.encourage),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.reviewDoneTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.reviewDoneSummary(reviewed),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => context.go('/flashcards/errorbook'),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: Text(l.reviewViewErrorBook),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewError extends StatelessWidget {
  final String message;
  const _ReviewError({required this.message});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l.commonErrorWithMessage(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<ReviewBloc>().add(const LoadDue()),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.commonRetry),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared subject chip
// ---------------------------------------------------------------------------
class _SubjectChip extends StatelessWidget {
  final String subject;
  const _SubjectChip({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        subject,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
