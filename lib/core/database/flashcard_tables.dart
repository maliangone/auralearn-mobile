import 'package:drift/drift.dart';

/// Authoritative local-first table for the flashcards / error-book feature
/// (Phase B). Each row is one spaced-repetition card with its SM-2 scheduling
/// state.
///
/// The SM-2 *math* lives in the domain layer (a use case computes the next
/// `easeFactor`/`intervalDays`/`repetitions`/`lapses`/`dueAt` from a review
/// grade); this table and [FlashcardDao] only PERSIST the resulting scheduling
/// state. Keeping the algorithm out of the data layer keeps it unit-testable
/// without a database and lets the schedule be recomputed deterministically.
///
/// `dueAt` is indexed so the "cards due now" query (the hot path of every
/// review session) stays an indexed range scan; `subject` is indexed so the
/// error-book can group/filter by subject cheaply (mirrors the history table).
///
/// JSON-encoded list columns ([tags]) are stored as TEXT (default `'[]'`) so
/// they stay LIKE-searchable until a dedicated tag table/FTS is introduced
/// (additive, non-breaking).
@DataClassName('FlashcardRow')
class Flashcards extends Table {
  /// Stable id (uuid string).
  TextColumn get id => text()();

  /// Prompt side of the card (question / term).
  TextColumn get front => text().withDefault(const Constant(''))();

  /// Answer side of the card (solution / definition).
  TextColumn get back => text().withDefault(const Constant(''))();

  /// Id of the [HistoryItems] row this card was generated from, if any.
  /// Nullable — cards can also be authored standalone.
  TextColumn get sourceHistoryId => text().nullable()();

  /// Subject label (e.g. math/physics/chemistry). Indexed for the error-book.
  TextColumn get subject => text().nullable()();

  /// JSON-encoded `List<String>` of free-text tags. Defaults to `[]`.
  TextColumn get tags => text().withDefault(const Constant('[]'))();

  /// SM-2 ease factor. Starts at 2.5 and is clamped to >= 1.3 by the algorithm.
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();

  /// Current inter-repetition interval in whole days. 0 for a brand-new card.
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();

  /// Number of consecutive successful repetitions (SM-2 `n`).
  IntColumn get repetitions => integer().withDefault(const Constant(0))();

  /// Number of times the card has lapsed (failed and reset).
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// When the card next becomes due for review. Indexed for the due-card query.
  DateTimeColumn get dueAt => dateTime()();

  /// Timestamp of the most recent review, or `null` if never reviewed.
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last-update timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
