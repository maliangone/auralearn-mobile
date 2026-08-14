import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_flashcard_usecase.dart';
import '../../domain/usecases/get_all_flashcards_usecase.dart';
import 'error_book_event.dart';
import 'error_book_state.dart';

/// Backs the 错题本 (error-book) list: loads every flashcard newest-first and
/// supports deleting individual cards.
class ErrorBookBloc extends Bloc<ErrorBookEvent, ErrorBookState> {
  final GetAllFlashcardsUseCase getAllFlashcardsUseCase;
  final DeleteFlashcardUseCase deleteFlashcardUseCase;

  ErrorBookBloc({
    required this.getAllFlashcardsUseCase,
    required this.deleteFlashcardUseCase,
  }) : super(const ErrorBookInitial()) {
    on<ErrorBookLoadRequested>(_onLoadRequested);
    on<ErrorBookDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onLoadRequested(
    ErrorBookLoadRequested event,
    Emitter<ErrorBookState> emit,
  ) async {
    emit(const ErrorBookLoading());
    final result = await getAllFlashcardsUseCase();
    result.fold(
      (failure) => emit(ErrorBookError(message: failure.message)),
      (cards) {
        if (cards.isEmpty) {
          emit(const ErrorBookEmpty());
        } else {
          emit(ErrorBookLoaded(cards: cards));
        }
      },
    );
  }

  Future<void> _onDeleteRequested(
    ErrorBookDeleteRequested event,
    Emitter<ErrorBookState> emit,
  ) async {
    final s = state;
    final result =
        await deleteFlashcardUseCase(DeleteFlashcardParams(id: event.id));

    await result.fold(
      (failure) async => emit(ErrorBookError(message: failure.message)),
      (_) async {
        if (s is ErrorBookLoaded) {
          final remaining =
              s.cards.where((c) => c.id != event.id).toList();
          if (remaining.isEmpty) {
            emit(const ErrorBookEmpty());
          } else {
            emit(ErrorBookLoaded(cards: remaining));
          }
        } else {
          add(const ErrorBookLoadRequested());
        }
      },
    );
  }
}
