import 'package:hive/hive.dart';
import '../models/history_response.dart';

abstract class HistoryLocalDataSource {
  Future<void> cacheHistory(List<HistoryItemModel> items);
  Future<List<HistoryItemModel>> getCachedHistory();
  Future<void> clearCache();
  Future<HistoryItemModel?> getCachedHistoryItem(String itemId);
  Future<void> removeCachedHistoryItem(String itemId);
}

class HistoryLocalDataSourceImpl implements HistoryLocalDataSource {
  static const String boxName = 'history';
  static const String historyKey = 'history_items';

  @override
  Future<void> cacheHistory(List<HistoryItemModel> items) async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      final itemsJson = items.map((item) => item.toJson()).toList();
      await box.put(historyKey, itemsJson);
    } catch (e) {
      // Handle cache errors gracefully
    }
  }

  @override
  Future<List<HistoryItemModel>> getCachedHistory() async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      final cachedData = box.get(historyKey, defaultValue: <Map>[]);
      
      if (cachedData is List) {
        return cachedData
            .map((json) => HistoryItemModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await Hive.openBox<Map>(boxName);
      await box.clear();
    } catch (e) {
      // Handle cache errors gracefully
    }
  }

  @override
  Future<HistoryItemModel?> getCachedHistoryItem(String itemId) async {
    try {
      final cachedItems = await getCachedHistory();
      return cachedItems.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw StateError('Item not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeCachedHistoryItem(String itemId) async {
    try {
      final cachedItems = await getCachedHistory();
      final updatedItems = cachedItems.where((item) => item.id != itemId).toList();
      await cacheHistory(updatedItems);
    } catch (e) {
      // Handle cache errors gracefully
    }
  }
} 