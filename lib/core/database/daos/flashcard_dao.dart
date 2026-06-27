import 'package:drift/drift.dart';

import '../app_database.dart';
import '../flashcard_tables.dart';

part 'flashcard_dao.g.dart';

/// Data-access object for the authoritative [Flashcards] table.
///
/// This object ONLY persists scheduling state — it contains no SM-2 math. The
/// domain layer computes the next `easeFactor`/`intervalDays`/`repetitions`/
/// `lapses`/`dueAt`/`lastReviewedAt` from a review grade and hands the result
/// to [updateScheduling]. All reads are local-first (no network) and the
/// reactive variants ([watchAll], [watchDue]) emit on every write so BLoC/UI
/// stays in sync.
@DriftAccessor(tables: [Flashcards])
class FlashcardDao extends DatabaseAccessor<AppDatabase>
    with _$FlashcardDaoMixin {
  FlashcardDao(super.db);

  /// Insert a row, replacing any existing row with the same primary key.
  Future<void> upsert(FlashcardsCompanion entry) {
    return into(flashcards).insertOnConflictUpdate(entry);
  }

  /// Insert a row, failing if the primary key already exists.
  Future<void> insertItem(FlashcardsCompanion entry) {
    return into(flashcards).insert(entry);
  }

  /// Single row by id, or `null` if absent.
  Future<FlashcardRow?> getById(String id) {
    return (select(flashcards)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// All rows, newest-first by [Flashcards.createdAt].
  Future<List<FlashcardRow>> getAllOrderedByCreatedAtDesc() {
    return (select(flashcards)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Reactive stream of all rows, newest-first. Emits on every write.
  Stream<List<FlashcardRow>> watchAll() {
    return (select(flashcards)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// All cards due for review at [now] (`dueAt <= now`), oldest-due first so
  /// the most overdue cards surface at the front of the review session.
  Future<List<FlashcardRow>> getDue(DateTime now) {
    return (select(flashcards)
          ..where((t) => t.dueAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .get();
  }

  /// Reactive stream of cards due at [now], oldest-due first. Emits on writes.
  Stream<List<FlashcardRow>> watchDue(DateTime now) {
    return (select(flashcards)
          ..where((t) => t.dueAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .watch();
  }

  /// Number of cards due for review at [now] (`dueAt <= now`).
  Future<int> countDue(DateTime now) async {
    final countExp = flashcards.id.count();
    final query = selectOnly(flashcards)
      ..addColumns([countExp])
      ..where(flashcards.dueAt.isSmallerOrEqualValue(now));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Total number of rows.
  Future<int> count() async {
    final countExp = flashcards.id.count();
    final query = selectOnly(flashcards)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Persist a recomputed SM-2 schedule for the card [id]. The caller (a domain
  /// use case) is responsible for the math; this method only writes the result
  /// and stamps [updatedAt] to `now`.
  Future<int> updateScheduling({
    required String id,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required int lapses,
    required DateTime dueAt,
    required DateTime lastReviewedAt,
  }) {
    return (update(flashcards)..where((t) => t.id.equals(id))).write(
      FlashcardsCompanion(
        easeFactor: Value(easeFactor),
        intervalDays: Value(intervalDays),
        repetitions: Value(repetitions),
        lapses: Value(lapses),
        dueAt: Value(dueAt),
        lastReviewedAt: Value(lastReviewedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a single row by id. Returns the number of rows removed (0 or 1).
  Future<int> deleteById(String id) {
    return (delete(flashcards)..where((t) => t.id.equals(id))).go();
  }

  /// Delete every row. Returns the number of rows removed.
  Future<int> clear() {
    return delete(flashcards).go();
  }
}
