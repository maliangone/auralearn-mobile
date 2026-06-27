import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/flashcard.dart';
import '../repositories/flashcard_repository.dart';

/// Loads the cards due for review at the given instant (defaults to now),
/// oldest-due first so the review session surfaces the most overdue cards.
class GetDueCardsUseCase {
  final FlashcardRepository repository;

  GetDueCardsUseCase(this.repository);

  Future<Either<Failure, List<Flashcard>>> call({DateTime? now}) {
    return repository.getDue(now ?? DateTime.now());
  }
}
