import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/document.dart';

/// Maps between the authoritative Drift [DocumentRow] / [DocumentsCompanion]
/// and the domain [Document] entity.
///
/// The only naming subtlety: the extracted text lives on the Dart getter
/// [DocumentRow.content] / [DocumentsCompanion.content] (the SQL column is
/// named `text`). This mapper is the single place that bridges that field to
/// the entity's [Document.content]. Keep it in sync with `document_tables.dart`.
class DocumentDriftMapper {
  const DocumentDriftMapper._();

  /// Build a [Document] entity from a persisted Drift row.
  static Document rowToEntity(DocumentRow row) {
    return Document(
      id: row.id,
      title: row.title,
      sourceType: row.sourceType,
      content: row.content,
      charCount: row.charCount,
      pageCount: row.pageCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Build an upsertable companion from a [Document].
  static DocumentsCompanion entityToCompanion(Document doc) {
    return DocumentsCompanion(
      id: Value(doc.id),
      title: Value(doc.title),
      sourceType: Value(doc.sourceType),
      content: Value(doc.content),
      charCount: Value(doc.charCount),
      pageCount: Value(doc.pageCount),
      createdAt: Value(doc.createdAt),
      updatedAt: Value(doc.updatedAt),
    );
  }
}
