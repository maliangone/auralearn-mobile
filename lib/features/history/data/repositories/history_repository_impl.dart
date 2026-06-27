import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';

/// Local-first authoritative history repository.
///
/// The Drift-backed [HistoryLocalDataSource] is the single source of truth:
/// every read is served from the local store and is offline-readable. History
/// is fully local — there is no remote datasource (the remote history endpoints
/// were pruned once the Drift read path was verified).
class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDataSource localDataSource;

  HistoryRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<HistoryItem>>> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    try {
      final items = await localDataSource.getHistory(page: page, limit: limit);
      final entities = items
          .map((item) => item.toEntity())
          .where((item) => subject == null || item.subject == subject)
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHistoryItem(String itemId) async {
    try {
      // Authoritative delete from the local store.
      await localDataSource.removeCachedHistoryItem(itemId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory() async {
    try {
      // Authoritative clear of the local store.
      await localDataSource.clearCache();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HistoryItem?>> getHistoryItem(String itemId) async {
    try {
      final cachedItem = await localDataSource.getCachedHistoryItem(itemId);
      return Right(cachedItem?.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Phase-B archive extensions
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<HistoryItem>>> search({
    String? query,
    String? subject,
  }) async {
    try {
      final items = await localDataSource.search(query: query, subject: subject);
      return Right(items.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSubjects() async {
    try {
      final subjects = await localDataSource.getSubjects();
      return Right(subjects);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setTags(String id, List<String> tags) async {
    try {
      await localDataSource.setTags(id, tags);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setSubject(String id, String? subject) async {
    try {
      await localDataSource.setSubject(id, subject);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
