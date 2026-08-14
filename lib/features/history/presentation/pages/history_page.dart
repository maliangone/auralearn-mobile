import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../l10n/app_localizations.dart';
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

  /// Owned here (not inside the search bar) so "clear filters" can also clear
  /// the visible query text.
  final _searchController = TextEditingController();

  // Last-known filter values — HistoryLoadingMore (and the delete-transient
  // states) carry no filter info, so the chips/search highlight would vanish
  // during pagination without these.
  String _lastQuery = '';
  String? _lastSubject;
  List<String> _lastSubjects = const [];

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

  void _clearFilters() {
    _searchController.clear();
    context.read<HistoryBloc>().add(const HistoryFiltersCleared());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
          l.historyTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
        ),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          // Resolve filter values from whatever state we're in, refreshing the
          // last-known cache whenever a state actually carries them.
          if (state is HistoryLoaded) {
            _lastQuery = state.currentQuery;
            _lastSubject = state.currentSubject;
            _lastSubjects = state.subjects;
          } else if (state is HistoryEmpty) {
            _lastQuery = state.currentQuery;
            _lastSubject = state.subject;
            _lastSubjects = state.subjects;
          }

          final currentQuery = _lastQuery;
          final currentSubject = _lastSubject;
          final subjects = _lastSubjects;

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
                  controller: _searchController,
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
              Expanded(
                child:
                    _buildBody(context, state, currentQuery, currentSubject),
              ),
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
        onClearFilters: _clearFilters,
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
              onClearFilters: _clearFilters,
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
    final l = AppLocalizations.of(context);
    return AppEmptyState(
      illustration: 'assets/illustrations/empty_history.svg',
      title: l.historyEmptyTitle,
      subtitle: l.historyEmptySubtitle,
      ctaLabel: l.homeGoSolve,
      onCta: () => context.goNamed('camera'),
      inline: true,
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
    final l = AppLocalizations.of(context);
    final filterDesc = [
      if (query.isNotEmpty) '"$query"',
      if (subject != null) subject!,
    ].join(' · ');

    return AppEmptyState(
      illustration: 'assets/illustrations/no_results.svg',
      title: l.historyNoResults,
      subtitle: filterDesc.isEmpty ? null : filterDesc,
      ctaLabel: l.historyClearFilters,
      onCta: onClearFilters,
      inline: true,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

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
