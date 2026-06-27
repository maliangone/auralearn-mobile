import 'package:auralearn/core/database/app_database.dart';
import 'package:auralearn/features/flashcards/data/datasources/flashcard_local_data_source.dart';
import 'package:auralearn/features/flashcards/data/repositories/flashcard_repository_impl.dart';
import 'package:auralearn/features/flashcards/domain/sm2.dart';
import 'package:auralearn/features/flashcards/domain/usecases/get_due_cards_usecase.dart';
import 'package:auralearn/features/flashcards/domain/usecases/review_card_usecase.dart';
import 'package:auralearn/features/flashcards/presentation/bloc/review_bloc.dart';
import 'package:auralearn/features/flashcards/presentation/bloc/review_event.dart';
import 'package:auralearn/features/flashcards/presentation/bloc/review_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late FlashcardRepositoryImpl repository;
  late ReviewBloc bloc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = FlashcardRepositoryImpl(
      localDataSource: FlashcardLocalDataSourceImpl(db),
    );
    bloc = ReviewBloc(
      getDueCardsUseCase: GetDueCardsUseCase(repository),
      reviewCardUseCase: ReviewCardUseCase(repository),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<void> seed(int n) async {
    for (var i = 0; i < n; i++) {
      await repository.createFromHistory(
        sourceHistoryId: 'h$i',
        front: 'front $i',
        back: 'back $i',
      );
    }
  }

  test('LoadDue with no due cards -> ReviewEmpty', () async {
    final states = <ReviewState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const LoadDue());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    expect(states.whereType<ReviewEmpty>(), isNotEmpty);
  });

  test('LoadDue with due cards -> ReviewInProgress at first card', () async {
    await seed(2);

    final states = <ReviewState>[];
    final sub = bloc.stream.listen(states.add);

    bloc.add(const LoadDue());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();

    final inProgress = states.whereType<ReviewInProgress>().last;
    expect(inProgress.total, 2);
    expect(inProgress.completed, 0);
    expect(inProgress.position, 1);
    expect(inProgress.flipped, isFalse);
  });

  test('FlipCard toggles the flipped flag', () async {
    await seed(1);

    bloc.add(const LoadDue());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((bloc.state as ReviewInProgress).flipped, isFalse);

    bloc.add(const FlipCard());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((bloc.state as ReviewInProgress).flipped, isTrue);
  });

  test('RateCard advances to next card then to ReviewDone', () async {
    await seed(2);

    bloc.add(const LoadDue());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Rate the first card -> advance to the second.
    bloc.add(const RateCard(ReviewRating.good));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final mid = bloc.state as ReviewInProgress;
    expect(mid.completed, 1);
    expect(mid.position, 2);
    expect(mid.flipped, isFalse);

    // Rate the second card -> done.
    bloc.add(const RateCard(ReviewRating.again));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final done = bloc.state as ReviewDone;
    expect(done.reviewed, 2);
  });

  test('rating persists the SM-2 schedule (card no longer due)', () async {
    await seed(1);

    bloc.add(const LoadDue());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    bloc.add(const RateCard(ReviewRating.good));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state, isA<ReviewDone>());

    // good on a new card -> due 1 day out -> not due now.
    final due = await repository.countDue(DateTime.now());
    due.fold((_) => fail('expected Right'), (c) => expect(c, 0));
  });
}
