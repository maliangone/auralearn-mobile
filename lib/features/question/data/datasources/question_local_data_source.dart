import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/history_dao.dart';
import '../models/question_response.dart';

/// Local-first authoritative persistence for solved questions, backed by the
/// Drift `history_items` table.
///
/// A solved question IS a history item, so this writes into the SAME table the
/// history feature reads from — persisting a Q&A here makes it show up in the
/// history list with no extra wiring. Interface signatures are unchanged so the
/// `QuestionBloc` (which calls [cacheQuestionResponse] / [getCachedQuestions])
/// needs no edits.
///
/// Trimming note: the previous Hive impl kept only the "last 50" questions.
/// Drift is the authoritative store and keeps ALL rows; volume is handled by
/// pagination on the read side ([HistoryDao.getPaginated]). The cap is dropped
/// on purpose — losing solved questions would contradict "offline-readable
/// authoritative history".
abstract class QuestionLocalDataSource {
  Future<void> cacheQuestionResponse(QuestionResponseModel questionResponse);
  Future<QuestionResponseModel?> getLastQuestionResponse();
  Future<List<QuestionResponseModel>> getCachedQuestions();
  Future<void> clearCache();
}

class QuestionLocalDataSourceImpl implements QuestionLocalDataSource {
  final AppDatabase database;

  QuestionLocalDataSourceImpl(this.database);

  HistoryDao get _dao => database.historyDao;

  @override
  Future<void> cacheQuestionResponse(
    QuestionResponseModel questionResponse,
  ) async {
    await _dao.upsert(_toCompanion(questionResponse));
  }

  @override
  Future<QuestionResponseModel?> getLastQuestionResponse() async {
    final rows = await _dao.getPaginated(limit: 1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<List<QuestionResponseModel>> getCachedQuestions() async {
    final rows = await _dao.getAllOrderedByCreatedAtDesc();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> clearCache() async {
    await _dao.clear();
  }

  /// Map a solved question into an upsertable `history_items` companion. The
  /// list/map columns are JSON-encoded; `updatedAt` mirrors `createdAt` since
  /// [QuestionResponse] has no separate update timestamp. `model`/`tags` are
  /// lifted out of metadata to populate the Phase-B-ready columns.
  HistoryItemsCompanion _toCompanion(QuestionResponseModel q) {
    final metadata = q.metadata;
    final modelId = metadata != null && metadata['model'] is String
        ? metadata['model'] as String
        : null;
    final tags = metadata != null && metadata['tags'] is List
        ? (metadata['tags'] as List).map((e) => e.toString()).toList()
        : const <String>[];

    return HistoryItemsCompanion(
      id: Value(q.id),
      question: Value(q.question ?? ''),
      answer: Value(q.answer ?? ''),
      explanation: Value(q.explanation),
      subject: Value(q.subject),
      category: Value(q.category),
      tags: Value(jsonEncode(tags)),
      model: Value(modelId),
      imageUrls: Value(
        q.imageUrls == null ? null : jsonEncode(q.imageUrls),
      ),
      confidence: Value(q.confidence),
      metadata: Value(metadata == null ? null : jsonEncode(metadata)),
      createdAt: Value(q.createdAt),
      updatedAt: Value(q.createdAt),
    );
  }

  /// Rebuild a [QuestionResponseModel] from a persisted row, decoding the
  /// JSON-encoded list/map columns.
  QuestionResponseModel _fromRow(HistoryItemRow row) {
    return QuestionResponseModel(
      id: row.id,
      question: row.question.isEmpty ? null : row.question,
      answer: row.answer.isEmpty ? null : row.answer,
      explanation: row.explanation,
      subject: row.subject,
      category: row.category,
      imageUrls: _decodeStringList(row.imageUrls),
      confidence: row.confidence,
      createdAt: row.createdAt,
      metadata: _decodeMap(row.metadata),
    );
  }

  List<String>? _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.map((e) => e.toString()).toList() : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}
