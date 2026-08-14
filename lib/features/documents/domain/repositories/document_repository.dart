import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/document.dart';

/// Local-first authoritative contract for the Phase C document-import feature.
///
/// Every read is served from the Drift store and is offline-readable; there is
/// no remote datasource. Imported text is stored verbatim for context-stuffing
/// into `/solve` (no RAG).
abstract class DocumentRepository {
  /// All documents, newest-first by `createdAt`.
  Future<Either<Failure, List<Document>>> getAll();

  /// Reactive stream of all documents, newest-first.
  Stream<List<Document>> watchAll();

  /// Single document by id.
  Future<Either<Failure, Document>> getById(String id);

  /// Insert or replace an (already extracted) document.
  Future<Either<Failure, void>> save(Document document);

  /// Delete a single document by id.
  Future<Either<Failure, void>> deleteById(String id);
}
