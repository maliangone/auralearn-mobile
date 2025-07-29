import '../../../core/network/api_client.dart';
import '../models/subscription_response.dart';

abstract class SubscriptionRemoteDataSource {
  Future<SubscriptionResponse> getSubscriptionStatus();
  Future<SubscriptionResponse> purchaseSubscription(String plan, Map<String, dynamic> purchaseData);
  Future<void> cancelSubscription();
  Future<SubscriptionResponse> restoreSubscription();
  Future<Map<String, dynamic>> getUsageStats();
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient _apiClient;

  SubscriptionRemoteDataSourceImpl(this._apiClient);

  @override
  Future<SubscriptionResponse> getSubscriptionStatus() async {
    return await _apiClient.getSubscriptionStatus();
  }

  @override
  Future<SubscriptionResponse> purchaseSubscription(String plan, Map<String, dynamic> purchaseData) async {
    return await _apiClient.purchaseSubscription(purchaseData);
  }

  @override
  Future<void> cancelSubscription() async {
    // TODO: Implement cancel subscription API call
    throw UnimplementedError();
  }

  @override
  Future<SubscriptionResponse> restoreSubscription() async {
    // TODO: Implement restore subscription API call
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getUsageStats() async {
    return await _apiClient.getUsageStats();
  }
} 