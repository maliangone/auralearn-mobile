import 'dart:convert';

import 'package:auralearn/core/storage/secure_token_store.dart';
import 'package:auralearn/features/subscription/data/datasources/billing_remote_data_source.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Token store stub that returns a fixed token without touching the platform
/// secure storage (which is unavailable in unit tests).
class _FakeTokenStore extends SecureTokenStore {
  final String? _token;
  _FakeTokenStore(this._token) : super(const FlutterSecureStorage());

  @override
  Future<String?> getAccessToken() async => _token;
}

void main() {
  group('BillingRemoteDataSource.getStatus', () {
    test('parses a paid status with expiry', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/billing/status');
        expect(request.headers['Authorization'], 'Bearer tok-123');
        return http.Response(
          jsonEncode({
            'plan': 'paid',
            'tier': 'auralearn_pro_monthly',
            'expiresAt': '2026-07-01T00:00:00Z',
          }),
          200,
        );
      });

      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok-123'),
        client: client,
      );

      final status = await ds.getStatus();
      expect(status.isPaid, isTrue);
      expect(status.tier, 'auralearn_pro_monthly');
      expect(status.expiresAt, DateTime.parse('2026-07-01T00:00:00Z'));
      expect(status.freeDailyQuota, 3);
    });

    test('defaults to free when plan missing', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({}), 200),
      );
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      final status = await ds.getStatus();
      expect(status.isFree, isTrue);
      expect(status.expiresAt, isNull);
    });

    test('throws BillingException on non-2xx', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      expect(ds.getStatus(), throwsA(isA<BillingException>()));
    });

    test('throws BillingException when not authenticated', () async {
      final client = MockClient((_) async => http.Response('{}', 200));
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore(null),
        client: client,
      );

      expect(ds.getStatus(), throwsA(isA<BillingException>()));
    });
  });

  group('BillingRemoteDataSource.validatePurchase', () {
    test('sends purchaseToken for google and returns refreshed status',
        () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/billing/validate');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['platform'], 'google');
        expect(body['productId'], 'auralearn_pro_monthly');
        expect(body['purchaseToken'], 'token-abc');
        expect(body.containsKey('receipt'), isFalse);
        return http.Response(jsonEncode({'plan': 'paid'}), 200);
      });

      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      final status = await ds.validatePurchase(
        platform: 'google',
        productId: 'auralearn_pro_monthly',
        verificationData: 'token-abc',
      );
      expect(status.isPaid, isTrue);
    });

    test('sends receipt for apple', () async {
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['platform'], 'apple');
        expect(body['receipt'], 'base64-receipt');
        expect(body.containsKey('purchaseToken'), isFalse);
        return http.Response(jsonEncode({'plan': 'paid'}), 200);
      });

      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      final status = await ds.validatePurchase(
        platform: 'apple',
        productId: 'auralearn_pro_monthly',
        verificationData: 'base64-receipt',
      );
      expect(status.isPaid, isTrue);
    });

    test('throws ReceiptAlreadyUsedException on 409 anti-replay', () async {
      final client = MockClient((_) async => http.Response('conflict', 409));
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      expect(
        ds.validatePurchase(
          platform: 'google',
          productId: 'auralearn_pro_monthly',
          verificationData: 'dup',
        ),
        throwsA(isA<ReceiptAlreadyUsedException>()),
      );
    });
  });
}
