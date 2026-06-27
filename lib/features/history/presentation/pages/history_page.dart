import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../widgets/history_item_card.dart';
import '../widgets/history_search_bar.dart';
import '../widgets/history_subject_chips.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryLoadRequested(refresh: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryBloc>().add(const HistoryLoadMoreRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          '历史',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          // Resolve filter values from whatever state we're in.
          final String currentQuery;
          final String? currentSubject;
          final List<String> subjects;

          if (state is HistoryLoaded) {
            currentQuery = state.currentQuery;
            currentSubject = state.currentSubject;
            subjects = state.subjects;
          } else if (state is HistoryEmpty) {
            currentQuery = state.currentQuery;
            currentSubject = state.subject;
            subjects = state.subjects;
          } else if (state is HistoryLoadingMore) {
            currentQuery = '';
            currentSubject = null;
            subjects = const [];
          } else {
            currentQuery = '';
            currentSubject = null;
            subjects = const [];
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.xs,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: HistorySearchBar(
                  onChanged: (query) => context
                      .read<HistoryBloc>()
                      .add(HistorySearchChanged(query)),
                  onClear: () => context
                      .read<HistoryBloc>()
                      .add(const HistorySearchChanged('')),
                ),
              ),

              // Subject filter chips (only when subjects are available)
              if (subjects.isNotEmpty) ...[
                HistorySubjectChips(
                  subjects: subjects,
                  selectedSubject: currentSubject,
                  onSubjectSelected: (subject) => context
                      .read<HistoryBloc>()
                      .add(HistorySubjectFilterChanged(subject)),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Body content
              Expanded(child: _buildBody(context, state, currentQuery, currentSubject)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HistoryState state,
    String currentQuery,
    String? currentSubject,
  ) {
    if (state is HistoryLoading || state is HistoryInitial) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state is HistoryError) {
      return _ErrorState(message: state.message);
    }

    // "Filtered empty" — active query/subject returned nothing.
    if (state is HistoryEmpty && state.isFilteredEmpty) {
      return _NoResultsState(
        query: state.currentQuery,
        subject: state.subject,
        onClearFilters: () => context
            .read<HistoryBloc>()
            .add(const HistoryFiltersCleared()),
      );
    }

    // "Truly empty" — database has no history at all.
    if (state is HistoryEmpty) {
      return const _EmptyState();
    }

    // Loaded (or loading-more — show current items while more pages fetch).
    final items = state is HistoryLoaded
        ? state.items
        : (state is HistoryLoadingMore ? state.items : const []);

    if (items.isEmpty) {
      final hasFilter = currentQuery.isNotEmpty || currentSubject != null;
      return hasFilter
          ? _NoResultsState(
              query: currentQuery,
              subject: currentSubject,
              onClearFilters: () => context
                  .read<HistoryBloc>()
                  .add(const HistoryFiltersCleared()),
            )
          : const _EmptyState();
    }

    final deletingId = state is HistoryItemDeleting ? state.deletingItemId : null;
    final isLoadingMore = state is HistoryLoadingMore;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        0,
        AppSpacing.base,
        AppSpacing.xxl,
      ),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Load-more spinner at the bottom.
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: HistoryItemCard(
            item: item,
            isDeleting: deletingId == item.id,
            onTap: () => context.go('/history/detail/${item.id}'),
            onDelete: () => context
                .read<HistoryBloc>()
                .add(HistoryItemDeleteRequested(itemId: item.id)),
            onTagsChanged: (tags) => context
                .read<HistoryBloc>()
                .add(HistoryTagsEdited(id: item.id, tags: tags)),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// State sub-widgets
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
              Icons.menu_book_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '还没有解题记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'AI 家教会一步步教你\n记录会自动保存在本地',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.goNamed('camera'),
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

class _NoResultsState extends StatelessWidget {
  final String query;
  final String? subject;
  final VoidCallback onClearFilters;

  const _NoResultsState({
    required this.query,
    required this.subject,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final filterDesc = [
      if (query.isNotEmpty) '"$query"',
      if (subject != null) subject!,
    ].join(' · ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '没有匹配的记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            if (filterDesc.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                filterDesc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('清除筛选'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<HistoryBloc>()
                  .add(const HistoryLoadRequested(refresh: true)),
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
