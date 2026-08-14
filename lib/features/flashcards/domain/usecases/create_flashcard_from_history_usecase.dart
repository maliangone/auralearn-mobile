import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/flashcard.dart';
import '../repositories/flashcard_repository.dart';

/// Creates a flashcard from a solved question (history item). The front is the
/// recognized problem; the back is the conclusion + steps joined by the data
/// layer. New cards are immediately due (`dueAt = createdAt`) so they appear in
/// the very next review session.
class CreateFlashcardFromHistoryUseCase {
  final FlashcardRepository repository;

  CreateFlashcardFromHistoryUseCase(this.repository);

  Future<Either<Failure, Flashcard>> call(
    CreateFlashcardFromHistoryParams params,
  ) {
    return repository.createFromHistory(
      sourceHistoryId: params.sourceHistoryId,
      front: params.front,
      back: params.back,
      subject: params.subject,
      tags: params.tags,
    );
  }
}

class CreateFlashcardFromHistoryParams {
  final String sourceHistoryId;
  final String front;
  final String back;
  final String? subject;
  final List<String> tags;

  CreateFlashcardFromHistoryParams({
    required this.sourceHistoryId,
    required this.front,
    required this.back,
    this.subject,
    this.tags = const <String>[],
  });
}
