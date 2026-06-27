import 'package:auralearn/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  // Deterministic, distinct instants so ordering assertions are unambiguous.
  final past = DateTime.utc(2026, 1, 1, 8);
  final mid = DateTime.utc(2026, 1, 2, 8);
  final now = DateTime.utc(2026, 1, 3, 8);

  DocumentsCompanion doc(
    String id, {
    required DateTime createdAt,
    String title = 'title',
    String sourceType = 'text',
    String content = '',
    int charCount = 0,
    int? pageCount,
  }) {
    return DocumentsCompanion.insert(
      id: id,
      title: Value(title),
      sourceType: Value(sourceType),
      content: Value(content),
      charCount: Value(charCount),
      pageCount: Value(pageCount),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DocumentDao', () {
    test('insertItem then getById round-trips with defaults applied', () async {
      await db.documentDao.insertItem(
        doc(
          'd1',
          createdAt: now,
          title: 'Algebra notes',
          sourceType: 'pdf',
          content: 'x^2 + y^2 = z^2',
          charCount: 15,
          pageCount: 3,
        ),
      );

      final found = await db.documentDao.getById('d1');
      expect(found, isNotNull);
      expect(found!.title, 'Algebra notes');
      expect(found.sourceType, 'pdf');
      expect(found.content, 'x^2 + y^2 = z^2');
      expect(found.charCount, 15);
      expect(found.pageCount, 3);
      expect(found.createdAt.toUtc(), now);

      expect(await db.documentDao.getById('missing'), isNull);
    });

    test('schema defaults applied for a minimal text note', () async {
      await db.documentDao.insertItem(doc('d1', createdAt: now));

      final found = await db.documentDao.getById('d1');
      // Schema defaults: empty content/title, char_count 0, null page_count.
      expect(found!.content, '');
      expect(found.charCount, 0);
      expect(found.sourceType, 'text');
      expect(found.pageCount, isNull);
    });

    test('upsert replaces an existing row with the same id', () async {
      await db.documentDao.upsert(doc('d1', createdAt: now, title: 'v1'));
      await db.documentDao.upsert(doc('d1', createdAt: now, title: 'v2'));

      expect(await db.documentDao.count(), 1);
      expect((await db.documentDao.getById('d1'))!.title, 'v2');
    });

    test('insertItem throws when the primary key already exists', () async {
      await db.documentDao.insertItem(doc('d1', createdAt: now));
      expect(
        () => db.documentDao.insertItem(doc('d1', createdAt: now)),
        throwsA(anything),
      );
    });

    test('getAllOrderedByCreatedAtDesc / watchAll are newest-first', () async {
      await db.documentDao.insertItem(doc('old', createdAt: past));
      await db.documentDao.insertItem(doc('new', createdAt: now));
      await db.documentDao.insertItem(doc('mid', createdAt: mid));

      final all = await db.documentDao.getAllOrderedByCreatedAtDesc();
      expect(all.map((r) => r.id).toList(), ['new', 'mid', 'old']);

      final watched = await db.documentDao.watchAll().first;
      expect(watched.map((r) => r.id).toList(), ['new', 'mid', 'old']);
    });

    test('count reflects the number of rows', () async {
      expect(await db.documentDao.count(), 0);
      await db.documentDao.insertItem(doc('a', createdAt: now));
      await db.documentDao.insertItem(doc('b', createdAt: mid));
      expect(await db.documentDao.count(), 2);
    });

    test('deleteById removes one row; clear empties the table', () async {
      await db.documentDao.insertItem(doc('a', createdAt: now));
      await db.documentDao.insertItem(doc('b', createdAt: mid));

      expect(await db.documentDao.deleteById('a'), 1);
      expect(await db.documentDao.getById('a'), isNull);
      expect(await db.documentDao.count(), 1);
      // Deleting a missing id is a no-op (0 rows affected).
      expect(await db.documentDao.deleteById('missing'), 0);

      expect(await db.documentDao.clear(), 1);
      expect(await db.documentDao.count(), 0);
    });
  });
}
