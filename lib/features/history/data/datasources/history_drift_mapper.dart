import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/history_response.dart';

/// Maps between the authoritative Drift [HistoryItemRow] / [HistoryItemsCompanion]
/// and the data-layer [HistoryItemModel].
///
/// The Drift table stores list/map columns ([tags], [imageUrls], [metadata]) as
/// JSON-encoded TEXT, so this mapper is the single place that encodes on write
/// and decodes on read. Keep it in sync with `tables.dart`.
class HistoryDriftMapper {
  const HistoryDriftMapper._();

  /// Decode a `List<String>` JSON column. Returns `null` for null/blank input
  /// and an empty list for an explicitly empty JSON array.
  static List<String>? _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Decode a `Map<String, dynamic>` JSON column.
  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Build a [HistoryItemModel] from a persisted Drift row, decoding the
  /// JSON-encoded list/map columns.
  static HistoryItemModel rowToModel(HistoryItemRow row) {
    return HistoryItemModel(
      id: row.id,
      question: row.question.isEmpty ? null : row.question,
      answer: row.answer.isEmpty ? null : row.answer,
      explanation: row.explanation,
      subject: row.subject,
      category: row.category,
      imageUrls: _decodeStringList(row.imageUrls),
      confidence: row.confidence,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      metadata: _decodeMap(row.metadata),
      tags: _decodeStringList(row.tags) ?? const [],
    );
  }

  /// Build an upsertable companion from a [HistoryItemModel], encoding the
  /// list/map columns to JSON TEXT. `model`/`tags` are pulled from metadata when
  /// present so a question-sourced row keeps its Phase-B-ready fields populated.
  static HistoryItemsCompanion modelToCompanion(HistoryItemModel model) {
    final metadata = model.metadata;
    final tagsValue = _tagsFromMetadata(metadata);
    final modelIdValue = _modelIdFromMetadata(metadata);

    return HistoryItemsCompanion(
      id: Value(model.id),
      question: Value(model.question ?? ''),
      answer: Value(model.answer ?? ''),
      explanation: Value(model.explanation),
      subject: Value(model.subject),
      category: Value(model.category),
      tags: Value(jsonEncode(tagsValue)),
      model: Value(modelIdValue),
      imageUrls: Value(
        model.imageUrls == null ? null : jsonEncode(model.imageUrls),
      ),
      confidence: Value(model.confidence),
      metadata: Value(
        metadata == null ? null : jsonEncode(metadata),
      ),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
  }

  /// Extract a `List<String>` of tags from arbitrary metadata, defaulting to an
  /// empty list (matches the table's `'[]'` default).
  static List<String> _tagsFromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata == null ? null : metadata['tags'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  /// Extract the LLM model id from metadata if the question flow stashed it
  /// there (`metadata['model']`).
  static String? _modelIdFromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata == null ? null : metadata['model'];
    return raw is String ? raw : null;
  }
}
