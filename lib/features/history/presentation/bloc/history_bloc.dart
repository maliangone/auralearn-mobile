import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/delete_history_item_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoryUseCase getHistoryUseCase;
  final DeleteHistoryItemUseCase deleteHistoryItemUseCase;
  /// Direct repository access for Phase-B operations (search, subjects, tags).
  final HistoryRepository repository;

  HistoryBloc({
    required this.getHistoryUseCase,
    required this.deleteHistoryItemUseCase,
    required this.repository,
  }) : super(const HistoryInitial()) {
    on<HistoryLoadRequested>(_onHistoryLoadRequested);
    on<HistoryItemDeleteRequested>(_onHistoryItemDeleteRequested);
    on<HistoryClearRequested>(_onHistoryClearRequested);
    on<HistoryLoadMoreRequested>(_onHistoryLoadMoreRequested);
    on<HistoryFilterChanged>(_onHistoryFilterChanged);
    // Phase-B archive events
    on<HistorySearchChanged>(_onHistorySearchChanged);
    on<HistorySubjectFilterChanged>(_onHistorySubjectFilterChanged);
    on<HistoryTagsEdited>(_onHistoryTagsEdited);
    on<HistoryFiltersCleared>(_onHistoryFiltersCleared);
    on<HistorySubjectsLoadRequested>(_onHistorySubjectsLoadRequested);
  }

  // ---------------------------------------------------------------------------
  // Helpers — current filter state
  // ---------------------------------------------------------------------------

  String get _currentQuery {
    final s = state;
    if (s is HistoryLoaded) return s.currentQuery;
    if (s is HistoryEmpty) return s.currentQuery;
    return '';
  }

  String? get _currentSubject {
    final s = state;
    if (s is HistoryLoaded) return s.currentSubject;
    if (s is HistoryEmpty) return s.subject;
    return null;
  }

  List<String> get _currentSubjects {
    final s = state;
    if (s is HistoryLoaded) return s.subjects;
    if (s is HistoryEmpty) return s.subjects;
    return const [];
  }

  // ---------------------------------------------------------------------------
  // Core load — delegates to search when any filter is active
  // ---------------------------------------------------------------------------

  Future<void> _loadWithFilters(
    Emitter<HistoryState> emit, {
    String? query,
    String? subject,
    List<String>? subjects,
    bool showLoading = false,
  }) async {
    final effectiveQuery = query ?? _currentQuery;
    final effectiveSubject = subject;  // explicit null = "all"
    final effectiveSubjects = subjects ?? _currentSubjects;

    if (showLoading) emit(const HistoryLoading());

    final hasFilter =
        effectiveQuery.trim().isNotEmpty || effectiveSubject != null;

    if (hasFilter) {
      // Use the Phase-B search path.
      final result = await repository.search(
        query: effectiveQuery.trim().isEmpty ? null : effectiveQuery.trim(),
        subject: effectiveSubject,
      );
      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (items) {
          if (items.isEmpty) {
            emit(HistoryEmpty(
              subject: effectiveSubject,
              currentQuery: effectiveQuery,
              subjects: effectiveSubjects,
              isFilteredEmpty: true,
            ));
          } else {
            emit(HistoryLoaded(
              items: items,
              hasMore: false,
              currentPage: 1,
              currentSubject: effectiveSubject,
              currentQuery: effectiveQuery,
              subjects: effectiveSubjects,
            ));
          }
        },
      );
    } else {
      // No filters — use the paginated use-case path (preserves hasMore).
      final result = await getHistoryUseCase(GetHistoryParams(
        page: 1,
        limit: 20,
      ));
      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (items) {
          if (items.isEmpty) {
            emit(HistoryEmpty(
              subjects: effectiveSubjects,
            ));
          } else {
            emit(HistoryLoaded(
              items: items,
              hasMore: items.length == 20,
              currentPage: 1,
              currentSubject: null,
              currentQuery: '',
              subjects: effectiveSubjects,
            ));
          }
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Existing event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onHistoryLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (event.refresh || state is HistoryInitial) {
      emit(const HistoryLoading());
    }

    // Load subjects first so chips are ready.
    final subjectsResult = await repository.getSubjects();
    final subjects = subjectsResult.fold((_) => <String>[], (s) => s);

    final result = await getHistoryUseCase(GetHistoryParams(
      page: event.page,
      limit: event.limit,
      subject: event.subject,
    ));

    result.fold(
      (failure) => emit(HistoryError(message: failure.message)),
      (items) {
        if (items.isEmpty) {
          emit(HistoryEmpty(
            subject: event.subject,
            subjects: subjects,
          ));
        } else {
          emit(HistoryLoaded(
            items: items,
            hasMore: items.length == event.limit,
            currentPage: event.page,
            currentSubject: event.subject,
            subjects: subjects,
          ));
        }
      },
    );
  }

  Future<void> _onHistoryItemDeleteRequested(
    HistoryItemDeleteRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is HistoryLoaded) {
      final currentState = state as HistoryLoaded;
      emit(HistoryItemDeleting(
        items: currentState.items,
        deletingItemId: event.itemId,
      ));

      final result = await deleteHistoryItemUseCase(
        DeleteHistoryItemParams(itemId: event.itemId),
      );

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (_) {
          final updatedItems = currentState.items
              .where((item) => item.id != event.itemId)
              .toList();

          if (updatedItems.isEmpty) {
            emit(HistoryEmpty(
              subject: currentState.currentSubject,
              currentQuery: currentState.currentQuery,
              subjects: currentState.subjects,
              isFilteredEmpty: currentState.currentQuery.isNotEmpty ||
                  currentState.currentSubject != null,
            ));
          } else {
            emit(currentState.copyWith(items: updatedItems));
          }
        },
      );
    }
  }

  Future<void> _onHistoryClearRequested(
    HistoryClearRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryClearing());
    add(const HistoryLoadRequested(refresh: true));
  }

  Future<void> _onHistoryLoadMoreRequested(
    HistoryLoadMoreRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is HistoryLoaded) {
      final currentState = state as HistoryLoaded;

      // Load-more only makes sense when there's no active search filter.
      if (!currentState.hasMore ||
          currentState.currentQuery.isNotEmpty ||
          currentState.currentSubject != null) {
        return;
      }

      emit(HistoryLoadingMore(items: currentState.items));

      final result = await getHistoryUseCase(GetHistoryParams(
        page: currentState.currentPage + 1,
        limit: 20,
      ));

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (newItems) {
          emit(currentState.copyWith(
            items: [...currentState.items, ...newItems],
            hasMore: newItems.length == 20,
            currentPage: currentState.currentPage + 1,
          ));
        },
      );
    }
  }

  Future<void> _onHistoryFilterChanged(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    add(HistoryLoadRequested(subject: event.subject, refresh: true));
  }

  // ---------------------------------------------------------------------------
  // Phase-B archive event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onHistorySearchChanged(
    HistorySearchChanged event,
    Emitter<HistoryState> emit,
  ) async {
    await _loadWithFilters(
      emit,
      query: event.query,
      subject: _currentSubject,
      showLoading: false,
    );
  }

  Future<void> _onHistorySubjectFilterChanged(
    HistorySubjectFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    await _loadWithFilters(
      emit,
      query: _currentQuery,
      subject: event.subject,
      showLoading: false,
    );
  }

  Future<void> _onHistoryTagsEdited(
    HistoryTagsEdited event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await repository.setTags(event.id, event.tags);
    result.fold(
      (failure) {
        // Silently ignore tag-edit failures — the list state is unchanged.
      },
      (_) {
        // Optimistically update the in-memory item so the UI refreshes
        // immediately without a full reload.
        if (state is HistoryLoaded) {
          final currentState = state as HistoryLoaded;
          final updatedItems = currentState.items.map((item) {
            if (item.id == event.id) {
              return item.copyWith(tags: event.tags);
            } else {
              return item;
            }
          }).toList();
          emit(currentState.copyWith(items: updatedItems));
        }
      },
    );
  }

  Future<void> _onHistoryFiltersCleared(
    HistoryFiltersCleared event,
    Emitter<HistoryState> emit,
  ) async {
    await _loadWithFilters(
      emit,
      query: '',
      subject: null,
      showLoading: false,
    );
  }

  Future<void> _onHistorySubjectsLoadRequested(
    HistorySubjectsLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await repository.getSubjects();
    result.fold(
      (_) {},
      (subjects) {
        if (state is HistoryLoaded) {
          emit((state as HistoryLoaded).copyWith(subjects: subjects));
        } else if (state is HistoryEmpty) {
          final s = state as HistoryEmpty;
          emit(HistoryEmpty(
            subject: s.subject,
            currentQuery: s.currentQuery,
            subjects: subjects,
            isFilteredEmpty: s.isFilteredEmpty,
          ));
        }
      },
    );
  }
}
