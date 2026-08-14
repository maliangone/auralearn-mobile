import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/document_repository.dart';

/// Deletes a single imported document by id.
class DeleteDocumentUseCase {
  final DocumentRepository repository;

  DeleteDocumentUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteDocumentParams params) {
    return repository.deleteById(params.id);
  }
}

class DeleteDocumentParams {
  final String id;

  DeleteDocumentParams({required this.id});
}
