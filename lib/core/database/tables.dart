import 'package:drift/drift.dart';

/// Single authoritative table for BOTH the question Q&A flow and the history
/// feature — they are the same domain (a solved question IS a history item).
///
/// Columns mirror the shared shape of [HistoryItem] / [QuestionResponse]
/// (id, question, answer, explanation, subject, category, imageUrls,
/// confidence, createdAt, updatedAt, metadata) and add Phase-B-ready fields
/// ([tags], [model]) up front so Phase B can layer subject/tag search and
/// archive without a schema-breaking migration.
///
/// JSON-encoded list/map columns ([tags], [imageUrls], [metadata]) are stored
/// as TEXT so they remain queryable-by-LIKE for Phase B's "full-text-ish"
/// search until a dedicated FTS table is introduced (additive, non-breaking).
@DataClassName('HistoryItemRow')
class HistoryItems extends Table {
  /// Stable id (uuid string), shared between the question flow and history.
  TextColumn get id => text()();

  /// Recognized / submitted problem statement.
  TextColumn get question => text().withDefault(const Constant(''))();

  /// Final answer text.
  TextColumn get answer => text().withDefault(const Constant(''))();

  /// Step-by-step explanation (思路 → 步骤 → 结论). Nullable.
  TextColumn get explanation => text().nullable()();

  /// Subject label (e.g. math/physics/chemistry). Indexed for Phase-B archive.
  TextColumn get subject => text().nullable()();

  /// Finer-grained topic/category. Nullable.
  TextColumn get category => text().nullable()();

  /// JSON-encoded `List<String>` of free-text tags (Phase B). Defaults to `[]`.
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// LLM model id that produced the answer (e.g. claude-haiku-4-5). Nullable.
  TextColumn get model => text().nullable()();

  /// JSON-encoded `List<String>` of image urls/paths. Nullable.
  TextColumn get imageUrls => text().nullable()();

  /// Read/answer confidence score, if reported. Nullable.
  RealColumn get confidence => real().nullable()();

  /// JSON-encoded `Map<String, dynamic>` of arbitrary metadata. Nullable.
  TextColumn get metadata => text().nullable()();

  /// Creation timestamp. Indexed (desc) for the default history ordering.
  DateTimeColumn get createdAt => dateTime()();

  /// Last-update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
