import 'package:drift/drift.dart';

/// Authoritative local-first table for imported study documents (Phase C
/// "document import"). Each row is one imported source — a PDF, a photographed
/// page, or a pasted note — whose text has been extracted on-device.
///
/// Import is **context-stuffing, not RAG** (plan §Phase C / Decisions): the
/// extracted [text] is stored verbatim so it can be stuffed into the
/// `/solve` / `/chat` prompt context (subject to the per-tier size cap applied
/// in the feature/domain layer). There is no vector store or embedding column;
/// real retrieval is deferred to v2.
///
/// [charCount] is denormalized from [text] at write time so the UI / size-cap
/// gate can show and enforce "how big is this document" without re-measuring
/// the (potentially large) TEXT blob on every read. [pageCount] is nullable
/// because only paged sources (PDFs) have a meaningful page count — photos and
/// pasted notes leave it `null`.
///
/// [createdAt] is indexed (desc) so the default "newest imports first" listing
/// stays an indexed scan, mirroring the history/flashcard tables.
@DataClassName('DocumentRow')
class Documents extends Table {
  /// Stable id (uuid string).
  TextColumn get id => text()();

  /// Human-readable title (file name / first line / user-edited label).
  TextColumn get title => text().withDefault(const Constant(''))();

  /// Origin of the document: `'pdf'`, `'image'`, or `'text'`. Stored as TEXT so
  /// new source kinds can be added without a schema migration.
  TextColumn get sourceType => text().withDefault(const Constant('text'))();

  /// Full extracted text, ready to be stuffed into model context. Defaults to
  /// `''` so a freshly-created (not-yet-extracted) row is well-formed.
  ///
  /// The Dart getter is [content] (the bare name `text` collides with Drift's
  /// `Table.text()` column builder) but the underlying SQL column is named
  /// `text` via [GeneratedColumn.named], so the on-disk schema matches spec.
  TextColumn get content => text().named('text').withDefault(const Constant(''))();

  /// Character count of [content], denormalized at write time for the size-cap
  /// UI / paid-tier gate.
  IntColumn get charCount => integer().withDefault(const Constant(0))();

  /// Number of pages for paged sources (PDFs). `null` for images / notes.
  IntColumn get pageCount => integer().nullable()();

  /// Import timestamp. Indexed (desc) for the default newest-first listing.
  DateTimeColumn get createdAt => dateTime()();

  /// Last-update timestamp (re-extraction, title edit, ...).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
