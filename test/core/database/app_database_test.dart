import 'package:auralearn/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  // Three rows with deterministic, distinct createdAt timestamps so ordering
  // and pagination are unambiguous. `older` < `middle` < `newer`.
  final older = DateTime.utc(2026, 1, 1, 8);
  final middle = DateTime.utc(2026, 1, 2, 8);
  final newer = DateTime.utc(2026, 1, 3, 8);

  HistoryItemsCompanion row(String id, DateTime createdAt, {String? subject}) {
    return HistoryItemsCompanion.insert(
      id: id,
      question: Value('Q-$id'),
      answer: Value('A-$id'),
      subject: Value(subject),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.historyDao.upsert(row('a', middle, subject: 'math'));
    await db.historyDao.upsert(row('b', newer, subject: 'physics'));
    await db.historyDao.upsert(row('c', older, subject: 'chemistry'));
  });

  tearDown(() async {
    await db.close();
  });

  test('getAllOrderedByCreatedAtDesc returns rows newest-first', () async {
    final rows = await db.historyDao.getAllOrderedByCreatedAtDesc();

    expect(rows.map((r) => r.id).toList(), ['b', 'a', 'c']);
    // Drift stores DateTime as epoch seconds and reads back in local time, so
    // compare the instant (UTC) rather than the wall-clock representation.
    expect(rows.first.createdAt.toUtc(), newer);
    expect(rows.last.createdAt.toUtc(), older);
  });

  test('getById returns the matching row, or null when absent', () async {
    final found = await db.historyDao.getById('a');
    expect(found, isNotNull);
    expect(found!.question, 'Q-a');
    expect(found.subject, 'math');

    final missing = await db.historyDao.getById('does-not-exist');
    expect(missing, isNull);
  });

  test('upsert replaces an existing row with the same id', () async {
    await db.historyDao.upsert(
      HistoryItemsCompanion.insert(
        id: 'a',
        question: const Value('updated-question'),
        answer: const Value('updated-answer'),
        createdAt: middle,
        updatedAt: middle,
      ),
    );

    final all = await db.historyDao.getAllOrderedByCreatedAtDesc();
    expect(all.length, 3); // still 3 rows, not 4
    final updated = await db.historyDao.getById('a');
    expect(updated!.question, 'updated-question');
  });

  test('getPaginated honors limit/offset newest-first', () async {
    final page1 = await db.historyDao.getPaginated(limit: 2, offset: 0);
    expect(page1.map((r) => r.id).toList(), ['b', 'a']);

    final page2 = await db.historyDao.getPaginated(limit: 2, offset: 2);
    expect(page2.map((r) => r.id).toList(), ['c']);
  });

  test('watchRecent emits the most recent N rows newest-first', () async {
    final recent = await db.historyDao.watchRecent(2).first;
    expect(recent.map((r) => r.id).toList(), ['b', 'a']);
  });

  test('count reflects the number of rows', () async {
    expect(await db.historyDao.count(), 3);
  });

  test('deleteById removes one row only', () async {
    final removed = await db.historyDao.deleteById('b');
    expect(removed, 1);

    final rows = await db.historyDao.getAllOrderedByCreatedAtDesc();
    expect(rows.map((r) => r.id).toList(), ['a', 'c']);
    expect(await db.historyDao.getById('b'), isNull);
  });

  test('clear empties the table', () async {
    final removed = await db.historyDao.clear();
    expect(removed, 3);
    expect(await db.historyDao.getAllOrderedByCreatedAtDesc(), isEmpty);
    expect(await db.historyDao.count(), 0);
  });
}
