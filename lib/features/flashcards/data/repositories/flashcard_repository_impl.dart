import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../../domain/sm2.dart';
import '../datasources/flashcard_local_data_source.dart';

/// Local-first authoritative flashcards repository.
///
/// The Drift-backed [FlashcardLocalDataSource] is the single source of truth:
/// every read is served from the local store and is offline-readable. There is
/// no remote datasource. SM-2 math is computed in the domain layer; [review]
/// only persists the precomputed [SchedulingResult].
class FlashcardRepositoryImpl implements FlashcardRepository {
  final FlashcardLocalDataSource localDataSource;

  FlashcardRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Flashcard>>> getDue(DateTime now) async {
    try {
      return Right(await localDataSource.getDue(now));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Flashcard>> watchDue(DateTime now) {
    return localDataSource.watchDue(now);
  }

  @override
  Future<Either<Failure, List<Flashcard>>> getAll() async {
    try {
      return Right(await localDataSource.getAll());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<List<Flashcard>> watchAll() {
    return localDataSource.watchAll();
  }

  @override
  Future<Either<Failure, void>> upsert(Flashcard card) async {
    try {
      await localDataSource.upsert(card);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> review(
    String id,
    SchedulingResult scheduling,
  ) async {
    try {
      await localDataSource.review(id, scheduling);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Flashcard>> createFromHistory({
    required String sourceHistoryId,
    required String front,
    required String back,
    String? subject,
    List<String> tags = const <String>[],
  }) async {
    try {
      final card = await localDataSource.createFromHistory(
        sourceHistoryId: sourceHistoryId,
        front: front,
        back: back,
        subject: subject,
        tags: tags,
      );
      return Right(card);
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

  @override
  Future<Either<Failure, int>> countDue(DateTime now) async {
    try {
      return Right(await localDataSource.countDue(now));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
