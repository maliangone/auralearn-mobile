import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_token_store.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> saveAuthData(AuthResponse authResponse);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<UserModel?> getUser();
  Future<void> clearAuthData();
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final LocalStorage _localStorage;
  final SecureTokenStore _tokenStore;

  AuthLocalDataSourceImpl(this._localStorage, this._tokenStore);

  @override
  Future<void> saveAuthData(AuthResponse authResponse) async {
    // Sensitive tokens go to secure storage.
    await _tokenStore.saveTokens(
      access: authResponse.accessToken,
      refresh: authResponse.refreshToken,
    );
    await _localStorage.setString(LocalStorage.keyUserId, authResponse.user.id);
    await _localStorage.setString(LocalStorage.keyUserEmail, authResponse.user.email);
    
    // Save full user data as JSON
    final userJson = json.encode(authResponse.user.toJson());
    await _localStorage.setString('user_data', userJson);
    
    // Save subscription plan
    await _localStorage.setString(LocalStorage.keySubscriptionPlan, authResponse.user.subscriptionPlan);
    await _localStorage.setInt(LocalStorage.keyUsageCount, authResponse.user.usageCount);
  }

  @override
  Future<String?> getAccessToken() async {
    return _tokenStore.getAccessToken();
  }

  @override
  Future<String?> getRefreshToken() async {
    return _tokenStore.getRefreshToken();
  }

  @override
  Future<UserModel?> getUser() async {
    final userJson = _localStorage.getString('user_data');
    if (userJson != null) {
      try {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearAuthData() async {
    // Clear sensitive tokens from secure storage.
    await _tokenStore.clear();
    await _localStorage.remove(LocalStorage.keyUserId);
    await _localStorage.remove(LocalStorage.keyUserEmail);
    await _localStorage.remove('user_data');
    await _localStorage.remove(LocalStorage.keySubscriptionPlan);
    await _localStorage.remove(LocalStorage.keyUsageCount);
  }

  @override
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }
} 