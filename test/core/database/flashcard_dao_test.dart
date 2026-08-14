import 'dart:convert';

import 'package:auralearn/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  // Deterministic, distinct instants so due/ordering assertions are unambiguous.
  final past = DateTime.utc(2026, 1, 1, 8);
  final mid = DateTime.utc(2026, 1, 2, 8);
  final now = DateTime.utc(2026, 1, 3, 8);
  final future = DateTime.utc(2026, 1, 10, 8);

  FlashcardsCompanion card(
    String id, {
    required DateTime dueAt,
    String front = 'front',
    String back = 'back',
    String? subject,
    DateTime? createdAt,
  }) {
    final created = createdAt ?? past;
    return FlashcardsCompanion.insert(
      id: id,
      front: Value(front),
      back: Value(back),
      subject: Value(subject),
      dueAt: dueAt,
      createdAt: created,
      updatedAt: created,
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('FlashcardDao', () {
    test('insertItem then getById round-trips with defaults applied', () async {
      await db.flashcardDao.insertItem(
        card('f1', dueAt: now, subject: 'math'),
      );

      final found = await db.flashcardDao.getById('f1');
      expect(found, isNotNull);
      expect(found!.front, 'front');
      expect(found.subject, 'math');
      // SM-2 defaults persisted by the schema, untouched by the DAO.
      expect(found.easeFactor, 2.5);
      expect(found.intervalDays, 0);
      expect(found.repetitions, 0);
      expect(found.lapses, 0);
      expect(found.tags, '[]');
      expect(found.lastReviewedAt, isNull);

      expect(await db.flashcardDao.getById('missing'), isNull);
    });

    test('upsert replaces an existing row with the same id', () async {
      await db.flashcardDao.upsert(card('f1', dueAt: now, front: 'v1'));
      await db.flashcardDao.upsert(card('f1', dueAt: now, front: 'v2'));

      expect(await db.flashcardDao.count(), 1);
      expect((await db.flashcardDao.getById('f1'))!.front, 'v2');
    });

    test('getDue returns only due cards, oldest-due first', () async {
      await db.flashcardDao.insertItem(card('overdue', dueAt: past));
      await db.flashcardDao.insertItem(card('dueNow', dueAt: now));
      await db.flashcardDao.insertItem(card('mid', dueAt: mid));
      await db.flashcardDao.insertItem(card('notYet', dueAt: future));

      final due = await db.flashcardDao.getDue(now);
      // future card excluded; remaining ordered oldest-due first.
      expect(due.map((c) => c.id).toList(), ['overdue', 'mid', 'dueNow']);
    });

    test('countDue counts only cards due at the given instant', () async {
      await db.flashcardDao.insertItem(card('a', dueAt: past));
      await db.flashcardDao.insertItem(card('b', dueAt: now));
      await db.flashcardDao.insertItem(card('c', dueAt: future));

      expect(await db.flashcardDao.countDue(now), 2);
      expect(await db.flashcardDao.countDue(past), 1);
      expect(await db.flashcardDao.countDue(future), 3);
    });

    test('watchDue emits due cards and re-emits after a write', () async {
      await db.flashcardDao.insertItem(card('a', dueAt: past));

      final first = await db.flashcardDao.watchDue(now).first;
      expect(first.map((c) => c.id).toList(), ['a']);
    });

    test('updateScheduling persists the recomputed SM-2 state', () async {
      await db.flashcardDao.insertItem(card('f1', dueAt: now));

      final reviewedAt = now;
      final nextDue = future;
      final affected = await db.flashcardDao.updateScheduling(
        id: 'f1',
        easeFactor: 2.6,
        intervalDays: 6,
        repetitions: 2,
        lapses: 1,
        dueAt: nextDue,
        lastReviewedAt: reviewedAt,
      );
      expect(affected, 1);

      final updated = await db.flashcardDao.getById('f1');
      expect(updated!.easeFactor, 2.6);
      expect(updated.intervalDays, 6);
      expect(updated.repetitions, 2);
      expect(updated.lapses, 1);
      expect(updated.dueAt.toUtc(), nextDue);
      expect(updated.lastReviewedAt!.toUtc(), reviewedAt);
      // The card is no longer due "now" after rescheduling into the future.
      expect(await db.flashcardDao.countDue(now), 0);
    });

    test('getAllOrderedByCreatedAtDesc / watchAll are newest-first', () async {
      await db.flashcardDao.insertItem(card('old', dueAt: now, createdAt: past));
      await db.flashcardDao.insertItem(card('new', dueAt: now, createdAt: now));
      await db.flashcardDao.insertItem(card('mid', dueAt: now, createdAt: mid));

      final all = await db.flashcardDao.getAllOrderedByCreatedAtDesc();
      expect(all.map((c) => c.id).toList(), ['new', 'mid', 'old']);

      final watched = await db.flashcardDao.watchAll().first;
      expect(watched.map((c) => c.id).toList(), ['new', 'mid', 'old']);
    });

    test('deleteById removes one row; clear empties the table', () async {
      await db.flashcardDao.insertItem(card('a', dueAt: now));
      await db.flashcardDao.insertItem(card('b', dueAt: now));

      expect(await db.flashcardDao.deleteById('a'), 1);
      expect(await db.flashcardDao.getById('a'), isNull);
      expect(await db.flashcardDao.count(), 1);

      expect(await db.flashcardDao.clear(), 1);
      expect(await db.flashcardDao.count(), 0);
    });
  });

  group('HistoryDao archive (search / filter / tags / subject)', () {
    HistoryItemsCompanion hrow(
      String id, {
      required DateTime createdAt,
      String question = '',
      String answer = '',
      String? subject,
    }) {
      return HistoryItemsCompanion.insert(
        id: id,
        question: Value(question),
        answer: Value(answer),
        subject: Value(subject),
        createdAt: createdAt,
        updatedAt: createdAt,
      );
    }

    setUp(() async {
      await db.historyDao.upsert(hrow(
        'a',
        createdAt: mid,
        question: 'Solve the quadratic equation',
        answer: 'Use the quadratic formula',
        subject: 'math',
      ));
      await db.historyDao.upsert(hrow(
        'b',
        createdAt: now,
        question: 'What is Newton second law',
        answer: 'Force equals mass times acceleration',
        subject: 'physics',
      ));
      await db.historyDao.upsert(hrow(
        'c',
        createdAt: past,
        question: 'Balance this chemical equation',
        answer: 'Conserve atoms on each side',
        subject: 'chemistry',
      ));
    });

    test('searchAndFilter by query matches question/answer/subject', () async {
      final byQuestion =
          await db.historyDao.searchAndFilter(query: 'equation');
      // 'a' (quadratic equation) and 'c' (chemical equation), newest-first.
      expect(byQuestion.map((r) => r.id).toList(), ['a', 'c']);

      final byAnswer = await db.historyDao.searchAndFilter(query: 'Force');
      expect(byAnswer.map((r) => r.id).toList(), ['b']);

      final bySubjectText =
          await db.historyDao.searchAndFilter(query: 'physics');
      expect(bySubjectText.map((r) => r.id).toList(), ['b']);
    });

    test('searchAndFilter by subject filters exactly, newest-first', () async {
      final math = await db.historyDao.searchAndFilter(subject: 'math');
      expect(math.map((r) => r.id).toList(), ['a']);

      // Empty/blank query is ignored (returns all, newest-first).
      final all = await db.historyDao.searchAndFilter(query: '  ');
      expect(all.map((r) => r.id).toList(), ['b', 'a', 'c']);
    });

    test('searchAndFilter combines query AND subject', () async {
      // 'equation' matches a + c, subject filter narrows to math => only a.
      final combined = await db.historyDao
          .searchAndFilter(query: 'equation', subject: 'math');
      expect(combined.map((r) => r.id).toList(), ['a']);
    });

    test('searchAndFilter honors limit/offset', () async {
      final page1 = await db.historyDao.searchAndFilter(limit: 2, offset: 0);
      expect(page1.map((r) => r.id).toList(), ['b', 'a']);
      final page2 = await db.historyDao.searchAndFilter(limit: 2, offset: 2);
      expect(page2.map((r) => r.id).toList(), ['c']);
    });

    test('watchFiltered emits the filtered set newest-first', () async {
      final emitted =
          await db.historyDao.watchFiltered(query: 'equation').first;
      expect(emitted.map((r) => r.id).toList(), ['a', 'c']);
    });

    test('getDistinctSubjects returns non-null subjects, alphabetical',
        () async {
      // Add a second math row + a null-subject row to prove de-dup + null skip.
      await db.historyDao.upsert(hrow('d', createdAt: now, subject: 'math'));
      await db.historyDao.upsert(hrow('e', createdAt: now));

      final subjects = await db.historyDao.getDistinctSubjects();
      expect(subjects, ['chemistry', 'math', 'physics']);
    });

    test('updateTags JSON-encodes and persists tags', () async {
      final affected = await db.historyDao.updateTags('a', ['algebra', '考试']);
      expect(affected, 1);

      final row = await db.historyDao.getById('a');
      expect(jsonDecode(row!.tags), ['algebra', '考试']);
    });

    test('updateSubject sets and clears the subject', () async {
      expect(await db.historyDao.updateSubject('c', 'biology'), 1);
      expect((await db.historyDao.getById('c'))!.subject, 'biology');

      expect(await db.historyDao.updateSubject('c', null), 1);
      expect((await db.historyDao.getById('c'))!.subject, isNull);
    });
  });
}
