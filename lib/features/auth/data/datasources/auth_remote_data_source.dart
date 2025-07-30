import '../../../core/network/api_client.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/auth_response.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> login(LoginRequest request);
  Future<AuthResponse> register(RegisterRequest request);
  Future<void> logout();
  Future<AuthResponse> refreshToken(String refreshToken);
  Future<AuthResponse> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    return await _apiClient.login(request);
  }

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    return await _apiClient.register(request);
  }

  @override
  Future<void> logout() async {
    await _apiClient.logout();
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    return await _apiClient.refreshToken(refreshToken);
  }

  @override
  Future<AuthResponse> getProfile() async {
    return await _apiClient.getProfile();
  }
} 