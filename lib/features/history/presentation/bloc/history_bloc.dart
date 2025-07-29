import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/delete_history_item_usecase.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoryUseCase getHistoryUseCase;
  final DeleteHistoryItemUseCase deleteHistoryItemUseCase;

  HistoryBloc({
    required this.getHistoryUseCase,
    required this.deleteHistoryItemUseCase,
  }) : super(const HistoryInitial()) {
    on<HistoryLoadRequested>(_onHistoryLoadRequested);
    on<HistoryItemDeleteRequested>(_onHistoryItemDeleteRequested);
    on<HistoryClearRequested>(_onHistoryClearRequested);
    on<HistoryLoadMoreRequested>(_onHistoryLoadMoreRequested);
    on<HistoryFilterChanged>(_onHistoryFilterChanged);
  }

  Future<void> _onHistoryLoadRequested(
    HistoryLoadRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (event.refresh || state is HistoryInitial) {
      emit(const HistoryLoading());
    }

    final result = await getHistoryUseCase(GetHistoryParams(
      page: event.page,
      limit: event.limit,
      subject: event.subject,
    ));

    result.fold(
      (failure) => emit(HistoryError(message: failure.message)),
      (items) {
        if (items.isEmpty) {
          emit(HistoryEmpty(subject: event.subject));
        } else {
          emit(HistoryLoaded(
            items: items,
            hasMore: items.length == event.limit,
            currentPage: event.page,
            currentSubject: event.subject,
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
            emit(HistoryEmpty(subject: currentState.currentSubject));
          } else {
            emit(HistoryLoaded(
              items: updatedItems,
              hasMore: currentState.hasMore,
              currentPage: currentState.currentPage,
              currentSubject: currentState.currentSubject,
            ));
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
    
    // Note: This would require a clear history use case
    // For now, just reload to show empty state
    add(const HistoryLoadRequested(refresh: true));
  }

  Future<void> _onHistoryLoadMoreRequested(
    HistoryLoadMoreRequested event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is HistoryLoaded) {
      final currentState = state as HistoryLoaded;
      
      if (!currentState.hasMore) return;

      emit(HistoryLoadingMore(items: currentState.items));

      final result = await getHistoryUseCase(GetHistoryParams(
        page: currentState.currentPage + 1,
        limit: 20,
        subject: currentState.currentSubject,
      ));

      result.fold(
        (failure) => emit(HistoryError(message: failure.message)),
        (newItems) {
          emit(HistoryLoaded(
            items: [...currentState.items, ...newItems],
            hasMore: newItems.length == 20,
            currentPage: currentState.currentPage + 1,
            currentSubject: currentState.currentSubject,
          ));
        },
      );
    }
  }

  Future<void> _onHistoryFilterChanged(
    HistoryFilterChanged event,
    Emitter<HistoryState> emit,
  ) async {
    add(HistoryLoadRequested(
      subject: event.subject,
      refresh: true,
    ));
  }
} 