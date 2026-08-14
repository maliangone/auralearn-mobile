import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/flashcard.dart';
import '../../domain/usecases/get_due_cards_usecase.dart';
import '../../domain/usecases/review_card_usecase.dart';
import 'review_event.dart';
import 'review_state.dart';

/// Drives a spaced-repetition review session: loads the due queue, shows one
/// card at a time (front -> tap to flip -> back), applies SM-2 on a rating,
/// persists it, and advances. Surfaces empty / done / error states.
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final GetDueCardsUseCase getDueCardsUseCase;
  final ReviewCardUseCase reviewCardUseCase;

  ReviewBloc({
    required this.getDueCardsUseCase,
    required this.reviewCardUseCase,
  }) : super(const ReviewLoading()) {
    on<LoadDue>(_onLoadDue);
    on<FlipCard>(_onFlipCard);
    on<RateCard>(_onRateCard);
    on<Finish>(_onFinish);
  }

  Future<void> _onLoadDue(LoadDue event, Emitter<ReviewState> emit) async {
    emit(const ReviewLoading());
    final result = await getDueCardsUseCase();
    result.fold(
      (failure) => emit(ReviewError(message: failure.message)),
      (cards) {
        if (cards.isEmpty) {
          emit(const ReviewEmpty());
        } else {
          emit(ReviewInProgress(
            queue: cards,
            flipped: false,
            completed: 0,
            total: cards.length,
          ));
        }
      },
    );
  }

  void _onFlipCard(FlipCard event, Emitter<ReviewState> emit) {
    final s = state;
    if (s is ReviewInProgress) {
      emit(s.copyWith(flipped: !s.flipped));
    }
  }

  Future<void> _onRateCard(RateCard event, Emitter<ReviewState> emit) async {
    final s = state;
    if (s is! ReviewInProgress) return;

    final Flashcard current = s.current;

    final result = await reviewCardUseCase(ReviewCardParams(
      card: current,
      rating: event.rating,
    ));

    await result.fold(
      (failure) async => emit(ReviewError(message: failure.message)),
      (_) async {
        final remaining = s.queue.sublist(1);
        final completed = s.completed + 1;
        if (remaining.isEmpty) {
          emit(ReviewDone(reviewed: completed));
        } else {
          emit(ReviewInProgress(
            queue: remaining,
            flipped: false,
            completed: completed,
            total: s.total,
          ));
        }
      },
    );
  }

  void _onFinish(Finish event, Emitter<ReviewState> emit) {
    final s = state;
    final reviewed = s is ReviewInProgress ? s.completed : 0;
    emit(ReviewDone(reviewed: reviewed));
  }
}
