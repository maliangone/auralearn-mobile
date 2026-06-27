import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'history_dao.g.dart';

/// Data-access object for the authoritative [HistoryItems] table.
///
/// Backs BOTH the question Q&A persistence and the history feature. All reads
/// are local-first (no network) and the reactive variants ([watchAll],
/// [watchRecent]) emit on every write so BLoC/UI stays in sync.
@DriftAccessor(tables: [HistoryItems])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.db);

  /// Insert a row, replacing any existing row with the same primary key.
  Future<void> upsert(HistoryItemsCompanion entry) {
    return into(historyItems).insertOnConflictUpdate(entry);
  }

  /// Insert a row, failing if the primary key already exists.
  Future<void> insertItem(HistoryItemsCompanion entry) {
    return into(historyItems).insert(entry);
  }

  /// All rows, newest-first by [HistoryItems.createdAt].
  Future<List<HistoryItemRow>> getAllOrderedByCreatedAtDesc() {
    return (select(historyItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Single row by id, or `null` if absent.
  Future<HistoryItemRow?> getById(String id) {
    return (select(historyItems)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Reactive stream of all rows, newest-first. Emits on every write.
  Stream<List<HistoryItemRow>> watchAll() {
    return (select(historyItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Reactive stream of the most recent [limit] rows, newest-first.
  Stream<List<HistoryItemRow>> watchRecent(int limit) {
    return (select(historyItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// Paginated page of rows, newest-first, using [limit]/[offset].
  Future<List<HistoryItemRow>> getPaginated({
    required int limit,
    int offset = 0,
  }) {
    return (select(historyItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Phase-B archive search/filter, newest-first.
  ///
  /// When [query] is non-empty, matches a case-insensitive `LIKE %query%` over
  /// `question`, `answer` and `subject` (the "full-text-ish" search backed by
  /// indexed ordering until a dedicated FTS table lands). When [subject] is
  /// non-empty, additionally requires an exact subject match. Both filters are
  /// optional and combine with AND. Paginated via [limit]/[offset].
  Future<List<HistoryItemRow>> searchAndFilter({
    String? query,
    String? subject,
    int limit = 50,
    int offset = 0,
  }) {
    final statement = select(historyItems)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit, offset: offset);
    _applyArchiveFilters(statement, query: query, subject: subject);
    return statement.get();
  }

  /// Reactive variant of [searchAndFilter] (no pagination). Emits newest-first
  /// on every write so the archive UI stays live as filters change.
  Stream<List<HistoryItemRow>> watchFiltered({String? query, String? subject}) {
    final statement = select(historyItems)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    _applyArchiveFilters(statement, query: query, subject: subject);
    return statement.watch();
  }

  /// Adds the optional `LIKE %query%` and exact-subject `WHERE` clauses shared
  /// by [searchAndFilter] and [watchFiltered]. Empty/blank inputs are ignored.
  void _applyArchiveFilters(
    SimpleSelectStatement<$HistoryItemsTable, HistoryItemRow> statement, {
    String? query,
    String? subject,
  }) {
    final trimmedQuery = query?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      final pattern = '%$trimmedQuery%';
      statement.where(
        (t) =>
            t.question.like(pattern) |
            t.answer.like(pattern) |
            t.subject.like(pattern),
      );
    }
    final trimmedSubject = subject?.trim();
    if (trimmedSubject != null && trimmedSubject.isNotEmpty) {
      statement.where((t) => t.subject.equals(trimmedSubject));
    }
  }

  /// Distinct, non-null subject labels present in the archive, alphabetical.
  /// Backs the subject-grouped archive / subject filter chips.
  Future<List<String>> getDistinctSubjects() async {
    final statement = selectOnly(historyItems, distinct: true)
      ..addColumns([historyItems.subject])
      ..where(historyItems.subject.isNotNull())
      ..orderBy([OrderingTerm.asc(historyItems.subject)]);
    final rows = await statement.get();
    return rows
        .map((r) => r.read(historyItems.subject))
        .whereType<String>()
        .toList();
  }

  /// Replace a row's tags with [tags] (JSON-encoded), stamping `updatedAt`.
  /// Returns the number of rows updated (0 or 1).
  Future<int> updateTags(String id, List<String> tags) {
    return (update(historyItems)..where((t) => t.id.equals(id))).write(
      HistoryItemsCompanion(
        tags: Value(jsonEncode(tags)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Set (or clear, when [subject] is `null`) a row's subject, stamping
  /// `updatedAt`. Returns the number of rows updated (0 or 1).
  Future<int> updateSubject(String id, String? subject) {
    return (update(historyItems)..where((t) => t.id.equals(id))).write(
      HistoryItemsCompanion(
        subject: Value(subject),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Total number of rows.
  Future<int> count() async {
    final countExp = historyItems.id.count();
    final query = selectOnly(historyItems)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Delete a single row by id. Returns the number of rows removed (0 or 1).
  Future<int> deleteById(String id) {
    return (delete(historyItems)..where((t) => t.id.equals(id))).go();
  }

  /// Delete every row. Returns the number of rows removed.
  Future<int> clear() {
    return delete(historyItems).go();
  }
}
