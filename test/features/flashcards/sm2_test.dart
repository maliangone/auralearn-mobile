import 'package:auralearn/features/flashcards/domain/entities/flashcard.dart';
import 'package:auralearn/features/flashcards/domain/sm2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A fixed clock so dueAt assertions are exact.
  final now = DateTime.utc(2026, 1, 10, 8);

  Flashcard card({
    double easeFactor = 2.5,
    int intervalDays = 0,
    int repetitions = 0,
    int lapses = 0,
  }) {
    final created = DateTime.utc(2026, 1, 1, 8);
    return Flashcard(
      id: 'c1',
      front: 'front',
      back: 'back',
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitions: repetitions,
      lapses: lapses,
      dueAt: created,
      createdAt: created,
      updatedAt: created,
    );
  }

  group('applySm2 — passing progression (good, q=4)', () {
    test('reps 0 -> interval 1 day, reps 1, ease unchanged at q=4', () {
      final r = applySm2(card(), ReviewRating.good, now: now);
      expect(r.repetitions, 1);
      expect(r.intervalDays, 1);
      expect(r.lapses, 0);
      // q=4: delta = 0.1 - (1)*(0.08 + 1*0.02) = 0.1 - 0.10 = 0.0 -> ease 2.5.
      expect(r.easeFactor, closeTo(2.5, 1e-9));
      expect(r.dueAt, now.add(const Duration(days: 1)));
      expect(r.lastReviewedAt, now);
    });

    test('reps 1 -> interval 6 days', () {
      final r = applySm2(
        card(repetitions: 1, intervalDays: 1),
        ReviewRating.good,
        now: now,
      );
      expect(r.repetitions, 2);
      expect(r.intervalDays, 6);
      expect(r.dueAt, now.add(const Duration(days: 6)));
    });

    test('reps >= 2 -> interval = round(prevInterval * newEase)', () {
      // ease stays 2.5 at q=4; interval = round(6 * 2.5) = 15.
      final r = applySm2(
        card(repetitions: 2, intervalDays: 6, easeFactor: 2.5),
        ReviewRating.good,
        now: now,
      );
      expect(r.repetitions, 3);
      expect(r.easeFactor, closeTo(2.5, 1e-9));
      expect(r.intervalDays, 15);
      expect(r.dueAt, now.add(const Duration(days: 15)));
    });
  });

  group('applySm2 — ease factor updates', () {
    test('easy (q=5) raises ease by 0.1', () {
      final r = applySm2(card(easeFactor: 2.5), ReviewRating.easy, now: now);
      // q=5: delta = 0.1 - 0 = 0.1 -> 2.6.
      expect(r.easeFactor, closeTo(2.6, 1e-9));
    });

    test('hard (q=3) lowers ease by 0.14', () {
      final r = applySm2(card(easeFactor: 2.5), ReviewRating.hard, now: now);
      // q=3: delta = 0.1 - (2)*(0.08 + 2*0.02) = 0.1 - 2*0.12 = -0.14 -> 2.36.
      expect(r.easeFactor, closeTo(2.36, 1e-9));
      // hard is still a pass: reps progress.
      expect(r.repetitions, 1);
      expect(r.intervalDays, 1);
    });

    test('repeated again lowers ease but never below the 1.3 floor', () {
      var c = card(easeFactor: 1.4);
      // again: q=2 -> delta = 0.1 - 3*(0.08+3*0.02) = 0.1 - 3*0.14 = -0.32.
      final r1 = applySm2(c, ReviewRating.again, now: now);
      // 1.4 - 0.32 = 1.08 -> floored to 1.3.
      expect(r1.easeFactor, closeTo(1.3, 1e-9));

      c = card(easeFactor: 1.3);
      final r2 = applySm2(c, ReviewRating.again, now: now);
      expect(r2.easeFactor, closeTo(1.3, 1e-9));
      expect(r2.easeFactor, greaterThanOrEqualTo(kMinEaseFactor));
    });
  });

  group('applySm2 — lapse (again, q=2)', () {
    test('resets repetitions, sets interval to 1 day, increments lapses', () {
      final r = applySm2(
        card(repetitions: 5, intervalDays: 40, lapses: 1),
        ReviewRating.again,
        now: now,
      );
      expect(r.repetitions, 0);
      expect(r.intervalDays, 1);
      expect(r.lapses, 2);
      expect(r.dueAt, now.add(const Duration(days: 1)));
    });

    test('again lowers ease and floors at 1.3 from a mid value', () {
      final r = applySm2(
        card(easeFactor: 2.5),
        ReviewRating.again,
        now: now,
      );
      // 2.5 - 0.32 = 2.18.
      expect(r.easeFactor, closeTo(2.18, 1e-9));
    });
  });

  group('applySm2 — full good lifecycle 0 -> 1d -> 6d -> round(*ease)', () {
    test('three consecutive good reviews follow SM-2 intervals', () {
      var c = card();

      final s1 = applySm2(c, ReviewRating.good, now: now);
      expect(s1.intervalDays, 1);
      expect(s1.repetitions, 1);
      c = c.copyWith(
        easeFactor: s1.easeFactor,
        intervalDays: s1.intervalDays,
        repetitions: s1.repetitions,
        lapses: s1.lapses,
      );

      final s2 = applySm2(c, ReviewRating.good, now: now);
      expect(s2.intervalDays, 6);
      expect(s2.repetitions, 2);
      c = c.copyWith(
        easeFactor: s2.easeFactor,
        intervalDays: s2.intervalDays,
        repetitions: s2.repetitions,
        lapses: s2.lapses,
      );

      final s3 = applySm2(c, ReviewRating.good, now: now);
      // ease still 2.5 across q=4 reviews; round(6 * 2.5) = 15.
      expect(s3.intervalDays, 15);
      expect(s3.repetitions, 3);
    });
  });

  test('ReviewRating maps the four buttons to SM-2 qualities', () {
    expect(ReviewRating.again.quality, 2);
    expect(ReviewRating.hard.quality, 3);
    expect(ReviewRating.good.quality, 4);
    expect(ReviewRating.easy.quality, 5);
  });
}
