import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';

/// Loads every imported document, newest-first. Backs the 我的资料 list.
class GetDocumentsUseCase {
  final DocumentRepository repository;

  GetDocumentsUseCase(this.repository);

  Future<Either<Failure, List<Document>>> call() {
    return repository.getAll();
  }
}
