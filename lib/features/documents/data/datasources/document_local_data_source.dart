import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/document_dao.dart';
import '../../domain/entities/document.dart';
import 'document_drift_mapper.dart';

/// Local-first authoritative datasource for the Phase C document-import
/// feature, backed by the Drift [DocumentDao]. This is the source of truth
/// on-device — reads never hit the network. [watchAll] re-emits on every write
/// so the bloc / UI stays in sync.
///
/// The datasource does not extract text or pick files; the import use case
/// supplies an already-built [Document] (with extracted [Document.content] and
/// its [Document.charCount]) to [save].
abstract class DocumentLocalDataSource {
  /// All documents, newest-first by `createdAt`.
  Future<List<Document>> getAll();

  /// Reactive stream of all documents, newest-first.
  Stream<List<Document>> watchAll();

  /// Single document by id, or `null` if absent.
  Future<Document?> getById(String id);

  /// Insert or replace a document (full upsert).
  Future<void> save(Document document);

  /// Delete a single document by id.
  Future<void> deleteById(String id);

  /// Total number of imported documents.
  Future<int> count();
}

class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final AppDatabase database;

  DocumentLocalDataSourceImpl(this.database);

  DocumentDao get _dao => database.documentDao;

  @override
  Future<List<Document>> getAll() async {
    final rows = await _dao.getAllOrderedByCreatedAtDesc();
    return rows.map(DocumentDriftMapper.rowToEntity).toList();
  }

  @override
  Stream<List<Document>> watchAll() {
    return _dao
        .watchAll()
        .map((rows) => rows.map(DocumentDriftMapper.rowToEntity).toList());
  }

  @override
  Future<Document?> getById(String id) async {
    final row = await _dao.getById(id);
    if (row == null) return null;
    return DocumentDriftMapper.rowToEntity(row);
  }

  @override
  Future<void> save(Document document) {
    return _dao.upsert(DocumentDriftMapper.entityToCompanion(document));
  }

  @override
  Future<void> deleteById(String id) {
    return _dao.deleteById(id);
  }

  @override
  Future<int> count() => _dao.count();
}
