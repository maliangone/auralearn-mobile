import 'package:auralearn/core/database/app_database.dart';
import 'package:auralearn/features/history/data/datasources/history_drift_mapper.dart';
import 'package:auralearn/features/history/data/datasources/history_local_data_source.dart';
import 'package:auralearn/features/history/data/models/history_response.dart';
import 'package:auralearn/features/history/data/repositories/history_repository_impl.dart';
import 'package:auralearn/features/question/data/datasources/question_local_data_source.dart';
import 'package:auralearn/features/question/data/models/question_response.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late HistoryLocalDataSourceImpl historyLocal;
  late QuestionLocalDataSourceImpl questionLocal;
  late HistoryRepositoryImpl repository;

  final older = DateTime.utc(2026, 1, 1, 8);
  final newer = DateTime.utc(2026, 1, 3, 8);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    historyLocal = HistoryLocalDataSourceImpl(db);
    questionLocal = QuestionLocalDataSourceImpl(db);
    // Local-first: no remote datasource wired for authoritative reads.
    repository = HistoryRepositoryImpl(localDataSource: historyLocal);
  });

  tearDown(() async {
    await db.close();
  });

  HistoryItemModel historyModel(
    String id,
    DateTime createdAt, {
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    String? subject,
  }) {
    return HistoryItemModel(
      id: id,
      question: 'Q-$id',
      answer: 'A-$id',
      explanation: 'E-$id',
      subject: subject,
      imageUrls: imageUrls,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('HistoryDriftMapper', () {
    test('round-trips JSON list/map columns through a Drift row', () async {
      final model = historyModel(
        'm1',
        newer,
        imageUrls: const ['a.png', 'b.png'],
        metadata: const {'model': 'claude-haiku', 'tags': ['algebra']},
        subject: 'math',
      );

      await db.historyDao.upsert(HistoryDriftMapper.modelToCompanion(model));
      final row = await db.historyDao.getById('m1');
      final back = HistoryDriftMapper.rowToModel(row!);

      expect(back.imageUrls, ['a.png', 'b.png']);
      expect(back.metadata?['model'], 'claude-haiku');
      expect(back.subject, 'math');
      // Phase-B columns are populated from metadata on write.
      expect(row.model, 'claude-haiku');
      expect(row.tags, '["algebra"]');
    });

    test('null list/map columns decode back to null', () async {
      final model = historyModel('m2', newer);
      await db.historyDao.upsert(HistoryDriftMapper.modelToCompanion(model));
      final back =
          HistoryDriftMapper.rowToModel((await db.historyDao.getById('m2'))!);

      expect(back.imageUrls, isNull);
      expect(back.metadata, isNull);
    });
  });

  group('HistoryLocalDataSource (Drift-backed)', () {
    test('getHistory returns newest-first and paginates', () async {
      await historyLocal.upsertItem(historyModel('old', older));
      await historyLocal.upsertItem(historyModel('new', newer));

      final page1 = await historyLocal.getHistory(page: 1, limit: 1);
      expect(page1.map((i) => i.id).toList(), ['new']);

      final page2 = await historyLocal.getHistory(page: 2, limit: 1);
      expect(page2.map((i) => i.id).toList(), ['old']);
    });

    test('remove and clear mutate the authoritative store', () async {
      await historyLocal.upsertItem(historyModel('x', newer));
      await historyLocal.removeCachedHistoryItem('x');
      expect(await historyLocal.getCachedHistoryItem('x'), isNull);

      await historyLocal.upsertItem(historyModel('y', newer));
      await historyLocal.clearCache();
      expect(await historyLocal.getCachedHistory(), isEmpty);
    });
  });

  group('HistoryRepositoryImpl (local-first)', () {
    test('getHistory reads from Drift, newest-first, subject-filtered',
        () async {
      await historyLocal.upsertItem(historyModel('m', older, subject: 'math'));
      await historyLocal
          .upsertItem(historyModel('p', newer, subject: 'physics'));

      final all = await repository.getHistory();
      expect(all.isRight(), isTrue);
      all.fold((_) => fail('expected Right'),
          (items) => expect(items.map((i) => i.id).toList(), ['p', 'm']));

      final filtered = await repository.getHistory(subject: 'math');
      filtered.fold((_) => fail('expected Right'),
          (items) => expect(items.map((i) => i.id).toList(), ['m']));
    });

    test('delete/clear succeed with no remote wired', () async {
      await historyLocal.upsertItem(historyModel('d', newer));
      expect(await repository.deleteHistoryItem('d'), const Right(null));
      expect(await repository.clearHistory(), const Right(null));
    });
  });

  group('Question persistence shares the history store', () {
    test('a solved question upserts into history and surfaces in history list',
        () async {
      final solved = QuestionResponseModel(
        id: 'q1',
        question: 'What is 2+2?',
        answer: '4',
        explanation: 'add the numbers',
        subject: 'math',
        createdAt: newer,
        metadata: const {
          'model': 'claude-haiku',
          'steps': ['2+2'],
          'source': 'solve_stream',
        },
      );

      await questionLocal.cacheQuestionResponse(solved);

      // It is readable from the question side...
      final cached = await questionLocal.getCachedQuestions();
      expect(cached.single.id, 'q1');
      expect(cached.single.metadata?['source'], 'solve_stream');

      // ...and it shows up in the shared history list.
      final history = await repository.getHistory();
      history.fold(
        (_) => fail('expected Right'),
        (items) {
          expect(items.single.id, 'q1');
          expect(items.single.question, 'What is 2+2?');
          expect(items.single.answer, '4');
        },
      );
    });

    test('getLastQuestionResponse returns the newest persisted question',
        () async {
      await questionLocal.cacheQuestionResponse(QuestionResponseModel(
        id: 'first',
        question: 'older',
        createdAt: older,
      ));
      await questionLocal.cacheQuestionResponse(QuestionResponseModel(
        id: 'second',
        question: 'newer',
        createdAt: newer,
      ));

      final last = await questionLocal.getLastQuestionResponse();
      expect(last?.id, 'second');
    });
  });
}
