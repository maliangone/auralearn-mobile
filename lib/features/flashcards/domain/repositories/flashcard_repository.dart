import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/flashcard.dart';
import '../sm2.dart';

/// Local-first authoritative contract for the flashcards / 错题本 feature.
///
/// Every read is served from the Drift store and is offline-readable; there is
/// no remote datasource. The SM-2 math lives in the domain layer (`applySm2`),
/// so [review] only persists a precomputed [SchedulingResult].
abstract class FlashcardRepository {
  /// All cards due for review at [now] (`dueAt <= now`), oldest-due first.
  Future<Either<Failure, List<Flashcard>>> getDue(DateTime now);

  /// Reactive stream of cards due at [now], oldest-due first.
  Stream<List<Flashcard>> watchDue(DateTime now);

  /// All cards, newest-first by `createdAt`.
  Future<Either<Failure, List<Flashcard>>> getAll();

  /// Reactive stream of all cards, newest-first.
  Stream<List<Flashcard>> watchAll();

  /// Insert or replace a card (full upsert).
  Future<Either<Failure, void>> upsert(Flashcard card);

  /// Persist a recomputed SM-2 schedule for the card [id].
  Future<Either<Failure, void>> review(String id, SchedulingResult scheduling);

  /// Create a card from a solved history item. Returns the created card.
  Future<Either<Failure, Flashcard>> createFromHistory({
    required String sourceHistoryId,
    required String front,
    required String back,
    String? subject,
    List<String> tags,
  });

  /// Delete a single card by id.
  Future<Either<Failure, void>> deleteById(String id);

  /// Number of cards due for review at [now].
  Future<Either<Failure, int>> countDue(DateTime now);
}
