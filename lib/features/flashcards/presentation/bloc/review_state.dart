import 'package:equatable/equatable.dart';

import '../../domain/entities/flashcard.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// Initial / loading the due queue.
class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// A review session is in progress. [current] is the card being shown, [flipped]
/// is whether the answer side is visible, [completed] is how many have been
/// rated so far, and [total] is the session size (completed + remaining).
class ReviewInProgress extends ReviewState {
  /// The remaining queue, current card first.
  final List<Flashcard> queue;
  final bool flipped;

  /// Number of cards already reviewed in this session.
  final int completed;

  /// Total cards in this session (completed + queue.length).
  final int total;

  const ReviewInProgress({
    required this.queue,
    required this.flipped,
    required this.completed,
    required this.total,
  });

  /// The card currently on screen (front of the queue).
  Flashcard get current => queue.first;

  /// 1-based position of the current card, e.g. "x" in "x / y".
  int get position => completed + 1;

  ReviewInProgress copyWith({
    List<Flashcard>? queue,
    bool? flipped,
    int? completed,
    int? total,
  }) {
    return ReviewInProgress(
      queue: queue ?? this.queue,
      flipped: flipped ?? this.flipped,
      completed: completed ?? this.completed,
      total: total ?? this.total,
    );
  }

  @override
  List<Object?> get props => [queue, flipped, completed, total];
}

/// No cards are due — nothing to review right now.
class ReviewEmpty extends ReviewState {
  const ReviewEmpty();
}

/// The session finished — every due card was reviewed. [reviewed] is how many
/// cards were rated.
class ReviewDone extends ReviewState {
  final int reviewed;

  const ReviewDone({required this.reviewed});

  @override
  List<Object?> get props => [reviewed];
}

/// Loading or persisting failed.
class ReviewError extends ReviewState {
  final String message;

  const ReviewError({required this.message});

  @override
  List<Object?> get props => [message];
}
