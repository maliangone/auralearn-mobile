import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/flashcard_dao.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/sm2.dart';
import 'flashcard_drift_mapper.dart';

/// Local-first authoritative datasource for the flashcards / 错题本 feature,
/// backed by the Drift [FlashcardDao]. This is the source of truth on-device —
/// reads never hit the network. The reactive variants ([watchDue], [watchAll])
/// emit on every write so the bloc/UI stays in sync.
abstract class FlashcardLocalDataSource {
  /// All cards due at [now] (`dueAt <= now`), oldest-due first.
  Future<List<Flashcard>> getDue(DateTime now);

  /// Reactive stream of cards due at [now], oldest-due first.
  Stream<List<Flashcard>> watchDue(DateTime now);

  /// All cards, newest-first by `createdAt`.
  Future<List<Flashcard>> getAll();

  /// Reactive stream of all cards, newest-first.
  Stream<List<Flashcard>> watchAll();

  /// Insert or replace a card (full upsert).
  Future<void> upsert(Flashcard card);

  /// Persist a recomputed SM-2 schedule for the card [id].
  Future<void> review(String id, SchedulingResult scheduling);

  /// Create + persist a card from a solved history item. Returns the new card.
  Future<Flashcard> createFromHistory({
    required String sourceHistoryId,
    required String front,
    required String back,
    String? subject,
    List<String> tags,
  });

  /// Delete a single card by id.
  Future<void> deleteById(String id);

  /// Number of cards due for review at [now].
  Future<int> countDue(DateTime now);
}

class FlashcardLocalDataSourceImpl implements FlashcardLocalDataSource {
  final AppDatabase database;
  final Uuid _uuid;

  FlashcardLocalDataSourceImpl(this.database, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  FlashcardDao get _dao => database.flashcardDao;

  @override
  Future<List<Flashcard>> getDue(DateTime now) async {
    final rows = await _dao.getDue(now);
    return rows.map(FlashcardDriftMapper.rowToEntity).toList();
  }

  @override
  Stream<List<Flashcard>> watchDue(DateTime now) {
    return _dao
        .watchDue(now)
        .map((rows) => rows.map(FlashcardDriftMapper.rowToEntity).toList());
  }

  @override
  Future<List<Flashcard>> getAll() async {
    final rows = await _dao.getAllOrderedByCreatedAtDesc();
    return rows.map(FlashcardDriftMapper.rowToEntity).toList();
  }

  @override
  Stream<List<Flashcard>> watchAll() {
    return _dao
        .watchAll()
        .map((rows) => rows.map(FlashcardDriftMapper.rowToEntity).toList());
  }

  @override
  Future<void> upsert(Flashcard card) {
    return _dao.upsert(FlashcardDriftMapper.entityToCompanion(card));
  }

  @override
  Future<void> review(String id, SchedulingResult scheduling) {
    return _dao.updateScheduling(
      id: id,
      easeFactor: scheduling.easeFactor,
      intervalDays: scheduling.intervalDays,
      repetitions: scheduling.repetitions,
      lapses: scheduling.lapses,
      dueAt: scheduling.dueAt,
      lastReviewedAt: scheduling.lastReviewedAt,
    );
  }

  @override
  Future<Flashcard> createFromHistory({
    required String sourceHistoryId,
    required String front,
    required String back,
    String? subject,
    List<String> tags = const <String>[],
  }) async {
    final now = DateTime.now();
    // A new card is immediately due so it appears in the next review session.
    final card = Flashcard(
      id: _uuid.v4(),
      front: front,
      back: back,
      sourceHistoryId: sourceHistoryId,
      subject: subject,
      tags: tags,
      dueAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await upsert(card);
    return card;
  }

  @override
  Future<void> deleteById(String id) {
    return _dao.deleteById(id);
  }

  @override
  Future<int> countDue(DateTime now) {
    return _dao.countDue(now);
  }
}
