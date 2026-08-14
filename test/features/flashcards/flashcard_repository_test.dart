import 'package:auralearn/core/database/app_database.dart';
import 'package:auralearn/features/flashcards/data/datasources/flashcard_local_data_source.dart';
import 'package:auralearn/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:auralearn/features/flashcards/domain/sm2.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FlashcardLocalDataSourceImpl local;
  late FlashcardRepositoryImpl repository;

  final now = DateTime.utc(2026, 1, 10, 8);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = FlashcardLocalDataSourceImpl(db);
    repository = FlashcardRepositoryImpl(localDataSource: local);
  });

  tearDown(() async {
    await db.close();
  });

  group('FlashcardRepositoryImpl (local-first, Drift-backed)', () {
    test('createFromHistory persists a due card mapped back to an entity',
        () async {
      final created = await repository.createFromHistory(
        sourceHistoryId: 'h1',
        front: 'What is 2+2?',
        back: '结论：4',
        subject: 'math',
        tags: const ['algebra', '考试'],
      );

      expect(created.isRight(), isTrue);
      final card = created.getOrElse(() => throw 'expected Right');
      expect(card.front, 'What is 2+2?');
      expect(card.back, '结论：4');
      expect(card.subject, 'math');
      expect(card.tags, ['algebra', '考试']);
      expect(card.sourceHistoryId, 'h1');

      // It is immediately due (dueAt == createdAt) and round-trips through the
      // JSON tags column.
      final all = await repository.getAll();
      all.fold((_) => fail('expected Right'), (cards) {
        expect(cards.single.id, card.id);
        expect(cards.single.tags, ['algebra', '考试']);
      });

      final due = await repository.getDue(card.dueAt);
      due.fold((_) => fail('expected Right'),
          (cards) => expect(cards.single.id, card.id));
    });

    test('review persists a recomputed SM-2 schedule', () async {
      final created = await repository.createFromHistory(
        sourceHistoryId: 'h2',
        front: 'q',
        back: 'a',
      );
      final card = created.getOrElse(() => throw 'expected Right');

      final scheduling = applySm2(card, ReviewRating.good, now: now);
      final reviewed = await repository.review(card.id, scheduling);
      expect(reviewed.isRight(), isTrue);

      final all = await repository.getAll();
      all.fold((_) => fail('expected Right'), (cards) {
        final updated = cards.single;
        expect(updated.repetitions, 1);
        expect(updated.intervalDays, 1);
        expect(updated.dueAt.toUtc(), now.add(const Duration(days: 1)));
        expect(updated.lastReviewedAt!.toUtc(), now);
      });

      // After rescheduling a day out, it is no longer due "now".
      final countNow = await repository.countDue(now);
      countNow.fold((_) => fail('expected Right'), (c) => expect(c, 0));
    });

    test('deleteById removes the card', () async {
      final created = await repository.createFromHistory(
        sourceHistoryId: 'h3',
        front: 'q',
        back: 'a',
      );
      final card = created.getOrElse(() => throw 'expected Right');

      final deleted = await repository.deleteById(card.id);
      expect(deleted.isRight(), isTrue);

      final all = await repository.getAll();
      all.fold((_) => fail('expected Right'), (cards) => expect(cards, isEmpty));
    });

    test('getDue returns only due cards after one is rescheduled out', () async {
      // Two cards created -> both due at their createdAt (real clock).
      final c1 = (await repository.createFromHistory(
        sourceHistoryId: 'a',
        front: 'a',
        back: 'a',
      ))
          .getOrElse(() => throw 'r');
      await repository.createFromHistory(
        sourceHistoryId: 'b',
        front: 'b',
        back: 'b',
      );

      // Query relative to the real creation clock; both are due now.
      final queryAt = DateTime.now();
      final dueBefore = await repository.getDue(queryAt);
      dueBefore.fold(
          (_) => fail('expected Right'), (cards) => expect(cards.length, 2));

      // Push c1 into the future relative to the same query instant.
      final sched = applySm2(c1, ReviewRating.easy, now: queryAt);
      await repository.review(c1.id, sched);

      final due = await repository.getDue(queryAt);
      due.fold((_) => fail('expected Right'), (cards) {
        // Only the un-reviewed card remains due at `queryAt`.
        expect(cards.length, 1);
        expect(cards.single.front, 'b');
      });
    });
  });
}
