import 'entities/flashcard.dart';

/// The four review buttons surfaced in the review session, mapped to SM-2
/// quality grades `q ∈ {2,3,4,5}`.
///
/// SM-2 classically grades 0–5; we collapse the failing grades (0–2) into a
/// single 不会 button at `q = 2` and keep three passing grades. `q < 3` is a
/// lapse — repetitions reset and the card is shown again the next day.
enum ReviewRating {
  /// 不会 — total blackout. Treated as a lapse (q = 2).
  again(2),

  /// 模糊 — recalled with serious difficulty (q = 3).
  hard(3),

  /// 会 — recalled correctly after hesitation (q = 4).
  good(4),

  /// 简单 — perfect, effortless recall (q = 5).
  easy(5);

  const ReviewRating(this.quality);

  /// SM-2 quality grade for this rating.
  final int quality;
}

/// The recomputed scheduling state produced by [applySm2]. Pure data — the
/// caller (a use case / repository) persists it via `dao.updateScheduling`.
class SchedulingResult {
  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final int lapses;
  final DateTime dueAt;
  final DateTime lastReviewedAt;

  const SchedulingResult({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAt,
    required this.lastReviewedAt,
  });
}

/// The SM-2 minimum ease factor. The algorithm never lets ease drop below this.
const double kMinEaseFactor = 1.3;

/// Pure SM-2 scheduling function.
///
/// Given a [card]'s current scheduling state and a review [rating], returns the
/// next [SchedulingResult]. No I/O, no clock reads beyond the injected [now]
/// (defaults to `DateTime.now()`), so it is fully deterministic and unit
/// testable.
///
/// Algorithm (classic SM-2 with a hard-lapse floor):
///   - Ease update (applied every review):
///       `EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))`, floored at 1.3.
///   - Lapse (`q < 3`, i.e. 不会): repetitions reset to 0, interval = 1 day,
///     lapses += 1.
///   - Pass (`q >= 3`):
///       reps 0 -> interval 1 day, reps 1 -> interval 6 days,
///       reps >= 2 -> interval = round(prevInterval * EF').
///     repetitions += 1 on a pass.
///   - `dueAt = now + intervalDays`; `lastReviewedAt = now`.
SchedulingResult applySm2(
  Flashcard card,
  ReviewRating rating, {
  DateTime? now,
}) {
  final reviewedAt = now ?? DateTime.now();
  final q = rating.quality;

  // Ease factor update — applied on every review, then floored at 1.3.
  final delta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
  var ease = card.easeFactor + delta;
  if (ease < kMinEaseFactor) ease = kMinEaseFactor;

  final int repetitions;
  final int intervalDays;
  final int lapses;

  if (q < 3) {
    // Lapse: reset the repetition streak, re-show tomorrow, count the lapse.
    repetitions = 0;
    intervalDays = 1;
    lapses = card.lapses + 1;
  } else {
    // Pass: advance the repetition streak and grow the interval.
    repetitions = card.repetitions + 1;
    lapses = card.lapses;
    if (card.repetitions == 0) {
      intervalDays = 1;
    } else if (card.repetitions == 1) {
      intervalDays = 6;
    } else {
      intervalDays = (card.intervalDays * ease).round();
    }
  }

  final dueAt = reviewedAt.add(Duration(days: intervalDays));

  return SchedulingResult(
    easeFactor: ease,
    intervalDays: intervalDays,
    repetitions: repetitions,
    lapses: lapses,
    dueAt: dueAt,
    lastReviewedAt: reviewedAt,
  );
}
