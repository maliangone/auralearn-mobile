import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/flashcard.dart';

/// Maps between the authoritative Drift [FlashcardRow] / [FlashcardsCompanion]
/// and the domain [Flashcard] entity.
///
/// The Drift table stores the `tags` list column as JSON-encoded TEXT, so this
/// mapper is the single place that decodes on read and encodes on write. Keep it
/// in sync with `flashcard_tables.dart`.
class FlashcardDriftMapper {
  const FlashcardDriftMapper._();

  /// Decode the `tags` JSON column. Returns an empty list for null/blank/invalid
  /// input (matches the table's `'[]'` default).
  static List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }

  /// Build a [Flashcard] entity from a persisted Drift row.
  static Flashcard rowToEntity(FlashcardRow row) {
    return Flashcard(
      id: row.id,
      front: row.front,
      back: row.back,
      sourceHistoryId: row.sourceHistoryId,
      subject: row.subject,
      tags: _decodeTags(row.tags),
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
      lapses: row.lapses,
      dueAt: row.dueAt,
      lastReviewedAt: row.lastReviewedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Build an upsertable companion from a [Flashcard], JSON-encoding `tags`.
  static FlashcardsCompanion entityToCompanion(Flashcard card) {
    return FlashcardsCompanion(
      id: Value(card.id),
      front: Value(card.front),
      back: Value(card.back),
      sourceHistoryId: Value(card.sourceHistoryId),
      subject: Value(card.subject),
      tags: Value(jsonEncode(card.tags)),
      easeFactor: Value(card.easeFactor),
      intervalDays: Value(card.intervalDays),
      repetitions: Value(card.repetitions),
      lapses: Value(card.lapses),
      dueAt: Value(card.dueAt),
      lastReviewedAt: Value(card.lastReviewedAt),
      createdAt: Value(card.createdAt),
      updatedAt: Value(card.updatedAt),
    );
  }
}
