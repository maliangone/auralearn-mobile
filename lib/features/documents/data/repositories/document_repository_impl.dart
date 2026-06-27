import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';
import '../datasources/document_local_data_source.dart';

/// Local-first authoritative document-import repository.
///
/// The Drift-backed [DocumentLocalDataSource] is the single source of truth:
/// every read is served from the local store and is offline-readable. There is
/// no remote datasource. Stored text is consumed by the document-chat flow as
/// context-stuffing (no RAG).
class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDataSource localDataSource;

  DocumentRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Document>>> getAll() async {
    try {
      return Right(await localDataSource.getAll());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Document>> watchAll() {
    return localDataSource.watchAll();
  }

  @override
  Future<Either<Failure, Document>> getById(String id) async {
    try {
      final doc = await localDataSource.getById(id);
      if (doc == null) {
        return const Left(CacheFailure('未找到该资料'));
      }
      return Right(doc);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> save(Document document) async {
    try {
      await localDataSource.save(document);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteById(String id) async {
    try {
      await localDataSource.deleteById(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
