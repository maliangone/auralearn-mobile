import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/history_dao.dart';
import '../models/history_response.dart';
import 'history_drift_mapper.dart';

/// Local-first authoritative datasource for the history feature, backed by the
/// Drift [HistoryDao]. This is the source of truth on-device — reads never hit
/// the network. A solved question persisted through the question flow lands in
/// the same `history_items` table, so it surfaces here automatically.
abstract class HistoryLocalDataSource {
  /// Upsert a single item (used by both the history sync path and the question
  /// flow). Replaces any existing row with the same id.
  Future<void> upsertItem(HistoryItemModel item);

  /// Upsert a batch of items (e.g. a best-effort remote sync), newest data wins.
  Future<void> cacheHistory(List<HistoryItemModel> items);

  /// Newest-first page of items from the local store.
  Future<List<HistoryItemModel>> getHistory({
    int page = 1,
    int limit = 20,
  });

  /// All items, newest-first. Backs the legacy [getCachedHistory] contract.
  Future<List<HistoryItemModel>> getCachedHistory();

  /// Remove every item.
  Future<void> clearCache();

  /// Single item by id, or `null` if absent.
  Future<HistoryItemModel?> getCachedHistoryItem(String itemId);

  /// Remove a single item by id.
  Future<void> removeCachedHistoryItem(String itemId);

  // ---------------------------------------------------------------------------
  // Phase-B archive extensions
  // ---------------------------------------------------------------------------

  /// Search items matching [query] (question/answer/subject LIKE) and/or an
  /// exact [subject] filter. Both are optional and combine with AND.
  Future<List<HistoryItemModel>> search({String? query, String? subject});

  /// All distinct, non-null subject labels, alphabetical.
  Future<List<String>> getSubjects();

  /// Replace the tags for item [id] with [tags].
  Future<void> setTags(String id, List<String> tags);

  /// Set (or clear, when [subject] is `null`) the subject for item [id].
  Future<void> setSubject(String id, String? subject);
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  final AppDatabase database;

  HistoryLocalDataSourceImpl(this.database);

  HistoryDao get _dao => database.historyDao;

  @override
  Future<void> upsertItem(HistoryItemModel item) async {
    await _dao.upsert(HistoryDriftMapper.modelToCompanion(item));
  }

  @override
  Future<void> cacheHistory(List<HistoryItemModel> items) async {
    for (final item in items) {
      await _dao.upsert(HistoryDriftMapper.modelToCompanion(item));
    }
  }

  @override
  Future<List<HistoryItemModel>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit < 1 ? 1 : limit;
    final offset = (safePage - 1) * safeLimit;
    final rows = await _dao.getPaginated(limit: safeLimit, offset: offset);
    return rows.map(HistoryDriftMapper.rowToModel).toList();
  }

  @override
  Future<List<HistoryItemModel>> getCachedHistory() async {
    final rows = await _dao.getAllOrderedByCreatedAtDesc();
    return rows.map(HistoryDriftMapper.rowToModel).toList();
  }

  @override
  Future<void> clearCache() async {
    await _dao.clear();
  }

  @override
  Future<HistoryItemModel?> getCachedHistoryItem(String itemId) async {
    final row = await _dao.getById(itemId);
    return row == null ? null : HistoryDriftMapper.rowToModel(row);
  }

  @override
  Future<void> removeCachedHistoryItem(String itemId) async {
    await _dao.deleteById(itemId);
  }

  // ---------------------------------------------------------------------------
  // Phase-B archive extensions
  // ---------------------------------------------------------------------------

  @override
  Future<List<HistoryItemModel>> search({
    String? query,
    String? subject,
  }) async {
    final rows = await _dao.searchAndFilter(query: query, subject: subject);
    return rows.map(HistoryDriftMapper.rowToModel).toList();
  }

  @override
  Future<List<String>> getSubjects() => _dao.getDistinctSubjects();

  @override
  Future<void> setTags(String id, List<String> tags) async {
    await _dao.updateTags(id, tags);
  }

  @override
  Future<void> setSubject(String id, String? subject) async {
    await _dao.updateSubject(id, subject);
  }
}
