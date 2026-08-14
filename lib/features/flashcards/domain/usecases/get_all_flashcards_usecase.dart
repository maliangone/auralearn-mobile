import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/flashcard.dart';
import '../repositories/flashcard_repository.dart';

/// Loads every flashcard, newest-first. Backs the 错题本 (error-book) list.
class GetAllFlashcardsUseCase {
  final FlashcardRepository repository;

  GetAllFlashcardsUseCase(this.repository);

  Future<Either<Failure, List<Flashcard>>> call() {
    return repository.getAll();
  }
}
