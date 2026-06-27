import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/flashcard.dart';
import '../repositories/flashcard_repository.dart';
import '../sm2.dart';

/// Applies the pure SM-2 schedule for a [ReviewRating] to a [Flashcard] and
/// persists the result. Returns the recomputed [SchedulingResult] so the caller
/// (the bloc) can update its in-memory view without a re-read.
class ReviewCardUseCase {
  final FlashcardRepository repository;

  ReviewCardUseCase(this.repository);

  Future<Either<Failure, SchedulingResult>> call(
    ReviewCardParams params,
  ) async {
    final scheduling = applySm2(
      params.card,
      params.rating,
      now: params.now,
    );
    final result = await repository.review(params.card.id, scheduling);
    return result.map((_) => scheduling);
  }
}

class ReviewCardParams {
  final Flashcard card;
  final ReviewRating rating;
  final DateTime? now;

  ReviewCardParams({
    required this.card,
    required this.rating,
    this.now,
  });
}
