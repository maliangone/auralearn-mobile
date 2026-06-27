import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_token_store.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/subscription_status.dart';

/// Raised when a store receipt has already been bound to a different account
/// (proxy anti-replay returns HTTP 409). The UI surfaces a dedicated message.
class ReceiptAlreadyUsedException implements Exception {
  final String message;
  const ReceiptAlreadyUsedException([this.message = '该购买凭证已绑定到其他账户']);
  @override
  String toString() => 'ReceiptAlreadyUsedException: $message';
}

/// Generic billing failure (network / non-2xx / parse). Carries an optional
/// HTTP [statusCode] so callers can branch if needed.
class BillingException implements Exception {
  final String message;
  final int? statusCode;
  const BillingException(this.message, {this.statusCode});
  @override
  String toString() =>
      'BillingException($statusCode): $message';
}

/// Talks to the stateless proxy billing endpoints using `package:http`,
/// mirroring [SolveClient]'s lightweight approach (dio is frozen at ^4 and
/// reserved for legacy callers). All calls are authenticated with the account
/// Bearer token from [SecureTokenStore] and use an 8s timeout; on any failure
/// they throw (the subscription page already renders an offline/error state).
///
/// Contract:
/// * `POST {proxyBaseUrl}/billing/validate`
///   body `{ platform: 'apple'|'google', receipt|purchaseToken, productId }`
///   -> validates a store purchase, binds it to the account, returns status.
///   Anti-replay: the same receipt on another account returns 409.
/// * `GET  {proxyBaseUrl}/billing/status`
///   -> `{ plan: 'free'|'paid', tier, expiresAt }`.
abstract class BillingRemoteDataSource {
  /// Validates a freshly completed store purchase with the proxy and returns
  /// the resulting (refreshed) [SubscriptionStatus].
  ///
  /// [platform] is 'apple' or 'google'. For Apple, [verificationData] is the
  /// base64 App Store receipt; for Google it is the Play purchase token.
  Future<SubscriptionStatus> validatePurchase({
    required String platform,
    required String productId,
    required String verificationData,
  });

  /// Fetches the current billing status for the signed-in account.
  Future<SubscriptionStatus> getStatus();
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  final http.Client _client;
  final SecureTokenStore _tokenStore;

  static const Duration _timeout = Duration(seconds: 8);

  /// [client] is injectable for testing; defaults to a fresh [http.Client].
  BillingRemoteDataSourceImpl({
    required SecureTokenStore tokenStore,
    http.Client? client,
  })  : _tokenStore = tokenStore,
        _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final token = await _tokenStore.getAccessToken();
    if (token == null || token.isEmpty) {
      throw const BillingException('未登录，无法访问订阅服务', statusCode: 401);
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
    };
  }

  @override
  Future<SubscriptionStatus> validatePurchase({
    required String platform,
    required String productId,
    required String verificationData,
  }) async {
    final uri = Uri.parse('${AppConfig.proxyBaseUrl}/billing/validate');

    // Apple expects `receipt`, Google expects `purchaseToken` per the contract.
    final body = <String, dynamic>{
      'platform': platform,
      'productId': productId,
      if (platform == 'apple') 'receipt': verificationData,
      if (platform == 'google') 'purchaseToken': verificationData,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: await _authHeaders(json: true),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 409) {
        AppLogger.error('Billing validate rejected (409 anti-replay)');
        throw const ReceiptAlreadyUsedException();
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BillingException(
          '购买校验失败 (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      return _parseStatus(response.body);
    } on ReceiptAlreadyUsedException {
      rethrow;
    } on BillingException {
      rethrow;
    } on TimeoutException {
      throw const BillingException('购买校验超时，请稍后重试');
    } catch (e) {
      AppLogger.error('Billing validate failed', e);
      throw BillingException('购买校验失败: $e');
    }
  }

  @override
  Future<SubscriptionStatus> getStatus() async {
    final uri = Uri.parse('${AppConfig.proxyBaseUrl}/billing/status');

    try {
      final response = await _client
          .get(uri, headers: await _authHeaders())
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BillingException(
          '获取订阅状态失败 (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }

      return _parseStatus(response.body);
    } on BillingException {
      rethrow;
    } on TimeoutException {
      throw const BillingException('获取订阅状态超时');
    } catch (e) {
      AppLogger.error('Billing status failed', e);
      throw BillingException('获取订阅状态失败: $e');
    }
  }

  /// Maps a `{ plan, tier, expiresAt }` JSON body onto [SubscriptionStatus].
  SubscriptionStatus _parseStatus(String responseBody) {
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(responseBody);
      json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      throw const BillingException('订阅服务返回了无法解析的数据');
    }

    final plan = (json['plan'] as String?) ?? 'free';
    final tier = json['tier'] as String?;

    DateTime? expiresAt;
    final rawExpiry = json['expiresAt'];
    if (rawExpiry is String && rawExpiry.isNotEmpty) {
      expiresAt = DateTime.tryParse(rawExpiry);
    } else if (rawExpiry is int) {
      // Tolerate epoch-seconds or epoch-millis.
      expiresAt = rawExpiry > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(rawExpiry)
          : DateTime.fromMillisecondsSinceEpoch(rawExpiry * 1000);
    }

    return SubscriptionStatus(
      plan: plan == 'paid' ? 'paid' : 'free',
      tier: tier,
      expiresAt: expiresAt,
      freeDailyQuota: AppConfig.freeDailyQuota,
    );
  }

  /// Releases the underlying HTTP client. Call when the owner is disposed.
  void close() => _client.close();
}
