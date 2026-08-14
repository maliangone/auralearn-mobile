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

  group('BillingRemoteDataSource.syncEntitlement', () {
    test('POSTs an empty body to /billing/sync (server queries RevenueCat)',
        () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/billing/sync');
        expect(request.headers['Authorization'], 'Bearer tok-123');
        // The client never sends receipts — the server only trusts its own
        // RevenueCat lookup.
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, isEmpty);
        return http.Response(jsonEncode({'plan': 'paid'}), 200);
      });

      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok-123'),
        client: client,
      );

      final status = await ds.syncEntitlement();
      expect(status.isPaid, isTrue);
    });

    test('returns refreshed free status after sync', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'plan': 'free'}), 200),
      );
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      final status = await ds.syncEntitlement();
      expect(status.isFree, isTrue);
    });

    test('throws BillingException on non-2xx sync', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      final ds = BillingRemoteDataSourceImpl(
        tokenStore: _FakeTokenStore('tok'),
        client: client,
      );

      expect(ds.syncEntitlement(), throwsA(isA<BillingException>()));
    });
  });
}
