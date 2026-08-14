import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryItem>>> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  });

  Future<Either<Failure, void>> deleteHistoryItem(String itemId);

  Future<Either<Failure, void>> clearHistory();

  Future<Either<Failure, HistoryItem?>> getHistoryItem(String itemId);

  // ---------------------------------------------------------------------------
  // Phase-B archive extensions
  // ---------------------------------------------------------------------------

  /// Full-text-ish search + optional exact-subject filter.
  Future<Either<Failure, List<HistoryItem>>> search({
    String? query,
    String? subject,
  });

  /// All distinct, non-null subject labels, alphabetical.
  Future<Either<Failure, List<String>>> getSubjects();

  /// Replace the tags for item [id].
  Future<Either<Failure, void>> setTags(String id, List<String> tags);

  /// Set (or clear, when [subject] is `null`) the subject for item [id].
  Future<Either<Failure, void>> setSubject(String id, String? subject);
}