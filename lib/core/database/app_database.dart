import 'package:drift/drift.dart';

import 'daos/document_dao.dart';
import 'daos/flashcard_dao.dart';
import 'daos/history_dao.dart';
import 'document_tables.dart';
import 'flashcard_tables.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// The local-first authoritative SQLite store (Drift).
///
/// This is the single source of truth on-device for question Q&A history and
/// the history feature (same domain). Identity/subscription/metering remain
/// server-authoritative and are NOT stored here.
///
/// Open it via `openAppDatabase()` (see `connection.dart`) in app code
/// (file-backed, app sandbox) or construct directly with a [QueryExecutor]
/// (e.g. `NativeDatabase.memory()`) in tests.
///
/// Indexes (declared in the table schema below) back Phase-B archive/search:
///   - `idx_history_created_at` on `created_at DESC` (default history ordering)
///   - `idx_history_subject` on `subject` (subject archive / filter)
///   - `idx_flashcards_due_at` on `flashcards.due_at` (due-card review query)
///   - `idx_flashcards_subject` on `flashcards.subject` (error-book grouping)
///   - `idx_documents_created_at` on `documents.created_at DESC` (Phase-C
///     document-import default newest-first listing)
@DriftDatabase(
  tables: [HistoryItems, Flashcards, Documents],
  daos: [HistoryDao, FlashcardDao, DocumentDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Bump this when changing the schema; pair every bump with a `from`/`to`
  /// branch in [migration] so existing on-device data survives upgrades.
  ///
  /// v1: history_items (+ its indexes).
  /// v2: flashcards table (+ due_at / subject indexes) for Phase B SRS.
  /// v3: documents table (+ created_at index) for Phase C document import.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          // Fresh installs get the full current schema (all tables) plus every
          // index in one shot — onUpgrade only runs for pre-existing DBs.
          await m.createAll();
          // history_items indexes — back Phase-B archive/search.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_history_created_at '
            'ON history_items (created_at DESC);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_history_subject '
            'ON history_items (subject);',
          );
          // flashcards indexes — back the SRS due-card query + error-book.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_due_at '
            'ON flashcards (due_at);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_flashcards_subject '
            'ON flashcards (subject);',
          );
          // documents index — back the Phase-C newest-first import listing.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_documents_created_at '
            'ON documents (created_at DESC);',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1 -> v2: add the Phase-B flashcards table + its indexes. Purely
          // additive; never drops/rewrites columns Phase B relies on.
          if (from < 2) {
            await m.createTable(flashcards);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_flashcards_due_at '
              'ON flashcards (due_at);',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_flashcards_subject '
              'ON flashcards (subject);',
            );
          }
          // v2 -> v3: add the Phase-C documents table + its created_at index.
          // Purely additive; leaves history/flashcards untouched.
          if (from < 3) {
            await m.createTable(documents);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_documents_created_at '
              'ON documents (created_at DESC);',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  HistoryDao get historyDaoInstance => historyDao;

  FlashcardDao get flashcardDaoInstance => flashcardDao;

  DocumentDao get documentDaoInstance => documentDao;
}
