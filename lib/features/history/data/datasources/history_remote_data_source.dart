import '../../../../core/network/api_client.dart';
import '../models/history_response.dart';

abstract class HistoryRemoteDataSource {
  Future<HistoryResponse> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  });
  
  Future<void> deleteHistoryItem(String itemId);
  
  Future<void> clearHistory();
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final ApiClient apiClient;

  HistoryRemoteDataSourceImpl(this.apiClient);

  @override
  Future<HistoryResponse> getHistory({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    try {
      return await apiClient.getHistory(page, limit, subject);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteHistoryItem(String itemId) async {
    try {
      await apiClient.deleteHistoryItem(itemId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearHistory() async {
    try {
      await apiClient.clearHistory();
    } catch (e) {
      rethrow;
    }
  }
} 