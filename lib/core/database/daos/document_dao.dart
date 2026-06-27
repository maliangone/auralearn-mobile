import 'package:drift/drift.dart';

import '../app_database.dart';
import '../document_tables.dart';

part 'document_dao.g.dart';

/// Data-access object for the authoritative [Documents] table (Phase C
/// document import).
///
/// Persists imported study documents whose text was extracted on-device for
/// context-stuffing (no RAG). All reads are local-first (no network) and
/// [watchAll] re-emits on every write so BLoC/UI stays in sync. The DAO does
/// not extract text or compute [Documents.charCount]; the caller (the document
/// import use case) supplies the already-extracted text and its char count in
/// the companion.
@DriftAccessor(tables: [Documents])
class DocumentDao extends DatabaseAccessor<AppDatabase>
    with _$DocumentDaoMixin {
  DocumentDao(super.db);

  /// Insert a row, replacing any existing row with the same primary key.
  Future<void> upsert(DocumentsCompanion entry) {
    return into(documents).insertOnConflictUpdate(entry);
  }

  /// Insert a row, failing if the primary key already exists.
  Future<void> insertItem(DocumentsCompanion entry) {
    return into(documents).insert(entry);
  }

  /// Single row by id, or `null` if absent.
  Future<DocumentRow?> getById(String id) {
    return (select(documents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// All rows, newest-first by [Documents.createdAt].
  Future<List<DocumentRow>> getAllOrderedByCreatedAtDesc() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Reactive stream of all rows, newest-first. Emits on every write.
  Stream<List<DocumentRow>> watchAll() {
    return (select(documents)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Total number of rows.
  Future<int> count() async {
    final countExp = documents.id.count();
    final query = selectOnly(documents)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Delete a single row by id. Returns the number of rows removed (0 or 1).
  Future<int> deleteById(String id) {
    return (delete(documents)..where((t) => t.id.equals(id))).go();
  }

  /// Delete every row. Returns the number of rows removed.
  Future<int> clear() {
    return delete(documents).go();
  }
}
