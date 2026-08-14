import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/flashcard.dart';
import '../bloc/error_book_bloc.dart';
import '../bloc/error_book_event.dart';
import '../bloc/error_book_state.dart';

/// 错题本 (error-book) — the full list of saved flashcards.
///
/// Route: `/flashcards/errorbook`. Each row shows the front (problem) with a
/// subject chip and a next-review hint; tapping expands the detail (answer);
/// a trailing button or swipe deletes the card (both behind a confirmation).
/// Covers loading / empty / error.
class ErrorBookPage extends StatefulWidget {
  const ErrorBookPage({super.key});

  @override
  State<ErrorBookPage> createState() => _ErrorBookPageState();
}

class _ErrorBookPageState extends State<ErrorBookPage> {
  @override
  void initState() {
    super.initState();
    context.read<ErrorBookBloc>().add(const ErrorBookLoadRequested());
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
          l.errorBookTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined,
                color: AppColors.primary),
            tooltip: l.reviewTitle,
            onPressed: () => context.go('/flashcards/review'),
          ),
        ],
      ),
      body: BlocBuilder<ErrorBookBloc, ErrorBookState>(
        builder: (context, state) {
          if (state is ErrorBookLoading || state is ErrorBookInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          if (state is ErrorBookError) {
            return _ErrorView(message: state.message);
          }

          if (state is ErrorBookEmpty) {
            return const _EmptyState();
          }

          if (state is ErrorBookLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              itemCount: state.cards.length,
              itemBuilder: (context, index) {
                final card = state.cards[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CardTile(card: card),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card tile (tap to expand front/back; swipe or button to delete)
// ---------------------------------------------------------------------------
class _CardTile extends StatefulWidget {
  final Flashcard card;
  const _CardTile({required this.card});

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  bool _expanded = false;

  void _delete() {
    context
        .read<ErrorBookBloc>()
        .add(ErrorBookDeleteRequested(id: widget.card.id));
  }

  /// Confirmation gate shared by swipe-to-delete and the delete icon.
  Future<bool> _confirmDelete() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l.commonDelete),
        content: Text(l.errorBookDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _onDeleteTap() async {
    if (await _confirmDelete() && mounted) {
      _delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final card = widget.card;
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => _delete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.style_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.front.isEmpty
                                ? l.historyNoQuestionText
                                : card.front,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              if (card.subject != null &&
                                  card.subject!.isNotEmpty) ...[
                                _SubjectChip(subject: card.subject!),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Flexible(
                                child: Text(
                                  _dueHint(card),
                                  style: textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textHint),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.textHint),
                      tooltip: l.commonDelete,
                      onPressed: _onDeleteTap,
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.encourageLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                          color:
                              AppColors.encourage.withValues(alpha: 60 / 255)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline,
                                size: 16, color: AppColors.encourage),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l.reviewAnswer,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.encourage,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          card.back.isEmpty ? l.questionNoAnswer : card.back,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Human-friendly next-review hint based on [Flashcard.dueAt].
  String _dueHint(Flashcard card) {
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final due = card.dueAt;
    if (!due.isAfter(now)) {
      return l.reviewDue;
    }
    final days = due.difference(now).inDays;
    if (days <= 0) {
      return l.reviewTomorrow;
    }
    return l.reviewInDays(days);
  }
}

// ---------------------------------------------------------------------------
// Empty / error
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AppEmptyState(
      illustration: 'assets/illustrations/empty_errorbook.svg',
      title: l.errorBookEmpty,
      subtitle: l.errorBookEmptySubtitle,
      ctaLabel: l.homeGoSolve,
      onCta: () => context.go('/camera'),
      inline: true,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

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
              onPressed: () => context
                  .read<ErrorBookBloc>()
                  .add(const ErrorBookLoadRequested()),
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
