import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';
import 'local_storage.dart';

/// Secure store for sensitive auth tokens (access + refresh).
///
/// Sensitive tokens are kept in the platform secure storage
/// (Keychain on iOS, EncryptedSharedPreferences on Android) instead of
/// plain [SharedPreferences]. Non-sensitive values (user id/email,
/// subscription plan, theme, onboarding flag, etc.) continue to live in
/// [SharedPreferences] / [LocalStorage].
class SecureTokenStore {
  final FlutterSecureStorage _secureStorage;

  SecureTokenStore(this._secureStorage);

  /// Convenience constructor with platform-hardened defaults.
  factory SecureTokenStore.create() {
    return SecureTokenStore(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    );
  }

  // Keys mirror the legacy SharedPreferences keys so migration is 1:1.
  static const String keyAccessToken = LocalStorage.keyAccessToken;
  static const String keyRefreshToken = LocalStorage.keyRefreshToken;

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: keyAccessToken);
    } catch (e) {
      AppLogger.error('Error reading access token from secure storage', e);
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: keyRefreshToken);
    } catch (e) {
      AppLogger.error('Error reading refresh token from secure storage', e);
      return null;
    }
  }

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    try {
      await _secureStorage.write(key: keyAccessToken, value: access);
      await _secureStorage.write(key: keyRefreshToken, value: refresh);
    } catch (e) {
      AppLogger.error('Error writing tokens to secure storage', e);
    }
  }

  Future<void> clear() async {
    try {
      await _secureStorage.delete(key: keyAccessToken);
      await _secureStorage.delete(key: keyRefreshToken);
    } catch (e) {
      AppLogger.error('Error clearing tokens from secure storage', e);
    }
  }

  /// One-time migration of legacy plaintext tokens.
  ///
  /// If old `access_token` / `refresh_token` keys exist in [prefs], copy them
  /// into secure storage and remove them from [prefs]. Idempotent: a second
  /// call is a no-op once the legacy keys are gone.
  Future<void> migrateFromSharedPreferences(SharedPreferences prefs) async {
    try {
      final legacyAccess = prefs.getString(keyAccessToken);
      final legacyRefresh = prefs.getString(keyRefreshToken);

      if (legacyAccess == null && legacyRefresh == null) {
        return;
      }

      if (legacyAccess != null) {
        await _secureStorage.write(key: keyAccessToken, value: legacyAccess);
      }
      if (legacyRefresh != null) {
        await _secureStorage.write(key: keyRefreshToken, value: legacyRefresh);
      }

      await prefs.remove(keyAccessToken);
      await prefs.remove(keyRefreshToken);

      AppLogger.info('Migrated auth tokens from SharedPreferences to secure storage');
    } catch (e) {
      AppLogger.error('Error migrating tokens from SharedPreferences', e);
    }
  }

  // --- BYOK API keys -------------------------------------------------------
  // User-supplied LLM vendor keys (direct-to-vendor mode) live in secure
  // storage alongside auth tokens — never in plaintext SharedPreferences.

  /// Key names are per provider family, e.g. `byok_key_anthropic`.
  static String byokKey(String providerName) => 'byok_key_$providerName';

  Future<String?> getByokKey(String providerName) async {
    try {
      return await _secureStorage.read(key: byokKey(providerName));
    } catch (e) {
      AppLogger.error('Error reading BYOK key for $providerName', e);
      return null;
    }
  }

  Future<void> saveByokKey(String providerName, String key) async {
    try {
      await _secureStorage.write(key: byokKey(providerName), value: key);
    } catch (e) {
      AppLogger.error('Error writing BYOK key for $providerName', e);
    }
  }

  Future<void> deleteByokKey(String providerName) async {
    try {
      await _secureStorage.delete(key: byokKey(providerName));
    } catch (e) {
      AppLogger.error('Error deleting BYOK key for $providerName', e);
    }
  }
}
