import 'package:equatable/equatable.dart';

import '../../domain/sm2.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Load the cards due for review and start a session at the first one.
class LoadDue extends ReviewEvent {
  const LoadDue();
}

/// Flip the current card between its front (prompt) and back (answer).
class FlipCard extends ReviewEvent {
  const FlipCard();
}

/// Rate the current card with one of the four buttons. Applies SM-2, persists
/// the new schedule, and advances to the next due card (or the done state).
class RateCard extends ReviewEvent {
  final ReviewRating rating;

  const RateCard(this.rating);

  @override
  List<Object?> get props => [rating];
}

/// End the session early.
class Finish extends ReviewEvent {
  const Finish();
}
