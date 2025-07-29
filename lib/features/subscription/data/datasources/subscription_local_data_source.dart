import '../../../../core/storage/local_storage.dart';
import '../models/subscription_response.dart';
import 'dart:convert';

abstract class SubscriptionLocalDataSource {
  Future<void> cacheSubscriptionData(SubscriptionResponse response);
  Future<SubscriptionResponse?> getCachedSubscriptionData();
  Future<void> clearSubscriptionCache();
}

class SubscriptionLocalDataSourceImpl implements SubscriptionLocalDataSource {
  final LocalStorage _localStorage;

  SubscriptionLocalDataSourceImpl(this._localStorage);

  @override
  Future<void> cacheSubscriptionData(SubscriptionResponse response) async {
    final subscriptionJson = json.encode(response.toJson());
    await _localStorage.setString('cached_subscription_data', subscriptionJson);
    
    // Cache subscription plan separately for quick access
    await _localStorage.setString(LocalStorage.keySubscriptionPlan, response.subscription.plan);
  }

  @override
  Future<SubscriptionResponse?> getCachedSubscriptionData() async {
    final subscriptionJson = _localStorage.getString('cached_subscription_data');
    if (subscriptionJson != null) {
      try {
        final subscriptionMap = json.decode(subscriptionJson) as Map<String, dynamic>;
        return SubscriptionResponse.fromJson(subscriptionMap);
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearSubscriptionCache() async {
    await _localStorage.remove('cached_subscription_data');
    await _localStorage.remove(LocalStorage.keySubscriptionPlan);
  }
} 