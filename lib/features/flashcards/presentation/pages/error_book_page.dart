import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/entities/flashcard.dart';
import '../bloc/error_book_bloc.dart';
import '../bloc/error_book_event.dart';
import '../bloc/error_book_state.dart';

/// 错题本 (error-book) — the full list of saved flashcards.
///
/// Route: `/flashcards/errorbook`. Each row shows the front (problem) with a
/// subject chip and a next-review hint; tapping expands the detail (answer);
/// a trailing button or swipe deletes the card. Covers loading / empty / error.
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '错题本',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined,
                color: AppColors.primary),
            tooltip: '今日复习',
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

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
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
                            card.front.isEmpty ? '（无题目）' : card.front,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textHint),
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
                      tooltip: '删除',
                      onPressed: _delete,
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
                          color: AppColors.encourage.withAlpha(60)),
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
                              '答案',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.encourage,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          card.back.isEmpty ? '（无答案）' : card.back,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
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
    final now = DateTime.now();
    final due = card.dueAt;
    if (!due.isAfter(now)) {
      return '待复习';
    }
    final days = due.difference(now).inDays;
    if (days <= 0) {
      return '明天复习';
    }
    return '$days 天后复习';
  }
}

// ---------------------------------------------------------------------------
// Empty / error
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '错题本还是空的',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "解题后点'加入错题本'",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go('/camera'),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('去拍照解题'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
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
              '加载失败：$message',
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
              label: const Text('重试'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
