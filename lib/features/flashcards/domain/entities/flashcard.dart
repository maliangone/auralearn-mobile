import 'package:equatable/equatable.dart';

/// A single spaced-repetition card in the flashcards / 错题本 (error-book)
/// feature.
///
/// Mirrors the authoritative Drift `flashcards` row but is a pure domain object
/// (no Drift / JSON concerns). The SM-2 scheduling state ([easeFactor],
/// [intervalDays], [repetitions], [lapses], [dueAt], [lastReviewedAt]) is
/// recomputed by [applySm2] (see `sm2.dart`) and persisted via the repository.
class Flashcard extends Equatable {
  /// Stable id (uuid string).
  final String id;

  /// Prompt side — the question / problem text.
  final String front;

  /// Answer side — the conclusion + steps / explanation.
  final String back;

  /// Id of the history item this card was generated from, if any.
  final String? sourceHistoryId;

  /// Subject label (e.g. math / physics). Drives the error-book subject chip.
  final String? subject;

  /// Free-text tags.
  final List<String> tags;

  /// SM-2 ease factor. Starts at 2.5 and is clamped to >= 1.3.
  final double easeFactor;

  /// Current inter-repetition interval in whole days. 0 for a brand-new card.
  final int intervalDays;

  /// Number of consecutive successful repetitions (SM-2 `n`).
  final int repetitions;

  /// Number of times the card has lapsed (failed and reset).
  final int lapses;

  /// When the card next becomes due for review.
  final DateTime dueAt;

  /// Timestamp of the most recent review, or `null` if never reviewed.
  final DateTime? lastReviewedAt;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last-update timestamp.
  final DateTime updatedAt;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.sourceHistoryId,
    this.subject,
    this.tags = const <String>[],
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.lapses = 0,
    required this.dueAt,
    this.lastReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? sourceHistoryId,
    String? subject,
    List<String>? tags,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      sourceHistoryId: sourceHistoryId ?? this.sourceHistoryId,
      subject: subject ?? this.subject,
      tags: tags ?? this.tags,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        front,
        back,
        sourceHistoryId,
        subject,
        tags,
        easeFactor,
        intervalDays,
        repetitions,
        lapses,
        dueAt,
        lastReviewedAt,
        createdAt,
        updatedAt,
      ];
}
