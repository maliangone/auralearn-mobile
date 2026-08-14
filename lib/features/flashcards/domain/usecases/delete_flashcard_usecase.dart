import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/flashcard_repository.dart';

/// Deletes a single flashcard by id.
class DeleteFlashcardUseCase {
  final FlashcardRepository repository;

  DeleteFlashcardUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteFlashcardParams params) {
    return repository.deleteById(params.id);
  }
}

class DeleteFlashcardParams {
  final String id;

  DeleteFlashcardParams({required this.id});
}
