import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';

class MockAuthDataSource {
  static const _uuid = Uuid();

  // Mock users database
  static final List<UserModel> _mockUsers = [
    UserModel(
      id: '1',
      email: 'demo@auralearn.com',
      name: 'Demo User',
      subscriptionPlan: 'pro',
      usageCount: 25,
      monthlyLimit: 500,
      avatar: null,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isEmailVerified: true,
    ),
    UserModel(
      id: '2',
      email: 'student@example.com',
      name: 'Student User',
      subscriptionPlan: 'free',
      usageCount: 8,
      monthlyLimit: 10,
      avatar: null,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      isEmailVerified: true,
    ),
  ];

  static final Map<String, String> _mockPasswords = {
    'demo@auralearn.com': 'password123',
    'student@example.com': 'student123',
  };

  Future<AuthResponse> login(LoginRequest request) async {
    AppLogger.info('Mock Auth: Login attempt for ${request.email}');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final user = _mockUsers.firstWhere(
      (u) => u.email == request.email,
      orElse: () => throw const AuthException('Invalid email or password'),
    );

    final expectedPassword = _mockPasswords[request.email];
    if (expectedPassword != request.password) {
      throw const AuthException('Invalid email or password');
    }

    return AuthResponse(
      accessToken: _generateMockToken(user.id),
      refreshToken: _generateMockRefreshToken(user.id),
      user: user,
      expiresIn: 3600,
    );
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    AppLogger.info('Mock Auth: Register attempt for ${request.email}');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check if user already exists
    final existingUser = _mockUsers.any((u) => u.email == request.email);
    if (existingUser) {
      throw const AuthException('User with this email already exists');
    }

    final newUser = UserModel(
      id: _uuid.v4(),
      email: request.email,
      name: request.name,
      subscriptionPlan: 'free',
      usageCount: 0,
      monthlyLimit: 10,
      avatar: null,
      createdAt: DateTime.now(),
      isEmailVerified: false,
    );

    _mockUsers.add(newUser);
    _mockPasswords[request.email] = request.password;

    return AuthResponse(
      accessToken: _generateMockToken(newUser.id),
      refreshToken: _generateMockRefreshToken(newUser.id),
      user: newUser,
      expiresIn: 3600,
    );
  }

  Future<AuthResponse> signInWithGoogle(String googleToken) async {
    AppLogger.info('Mock Auth: Google sign-in');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Create or get existing Google user
    const email = 'google.user@gmail.com';
    UserModel user = _mockUsers.firstWhere(
      (u) => u.email == email,
      orElse: () {
        final newUser = UserModel(
          id: _uuid.v4(),
          email: email,
          name: 'Google User',
          subscriptionPlan: 'standard',
          usageCount: 42,
          monthlyLimit: 100,
          avatar: 'https://avatar.placeholder.com/google',
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          isEmailVerified: true,
        );
        _mockUsers.add(newUser);
        return newUser;
      },
    );

    return AuthResponse(
      accessToken: _generateMockToken(user.id),
      refreshToken: _generateMockRefreshToken(user.id),
      user: user,
      expiresIn: 3600,
    );
  }

  Future<AuthResponse> signInWithApple(String appleToken) async {
    AppLogger.info('Mock Auth: Apple sign-in');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create or get existing Apple user
    const email = 'apple.user@icloud.com';
    UserModel user = _mockUsers.firstWhere(
      (u) => u.email == email,
      orElse: () {
        final newUser = UserModel(
          id: _uuid.v4(),
          email: email,
          name: 'Apple User',
          subscriptionPlan: 'pro',
          usageCount: 156,
          monthlyLimit: 500,
          avatar: null, // Apple doesn't provide photos
          createdAt: DateTime.now().subtract(const Duration(days: 90)),
          isEmailVerified: true,
        );
        _mockUsers.add(newUser);
        return newUser;
      },
    );

    return AuthResponse(
      accessToken: _generateMockToken(user.id),
      refreshToken: _generateMockRefreshToken(user.id),
      user: user,
      expiresIn: 3600,
    );
  }

  Future<void> logout() async {
    AppLogger.info('Mock Auth: Logout');
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real implementation, we'd invalidate the token on the server
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    AppLogger.info('Mock Auth: Refresh token');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    // Extract user ID from mock refresh token
    final userId = _extractUserIdFromMockToken(refreshToken);
    final user = _mockUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw const AuthException('Invalid refresh token'),
    );

    return AuthResponse(
      accessToken: _generateMockToken(user.id),
      refreshToken: _generateMockRefreshToken(user.id),
      user: user,
      expiresIn: 3600,
    );
  }

  String _generateMockToken(String userId) {
    final payload = {
      'user_id': userId,
      'exp':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      'iat': DateTime.now().millisecondsSinceEpoch,
    };
    return 'mock_access_${base64Encode(utf8.encode(json.encode(payload)))}';
  }

  String _generateMockRefreshToken(String userId) {
    final payload = {
      'user_id': userId,
      'exp': DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
      'iat': DateTime.now().millisecondsSinceEpoch,
    };
    return 'mock_refresh_${base64Encode(utf8.encode(json.encode(payload)))}';
  }

  String _extractUserIdFromMockToken(String token) {
    try {
      final base64Part = token.replaceFirst('mock_refresh_', '');
      final decoded = json.decode(utf8.decode(base64Decode(base64Part)));
      return decoded['user_id'] as String;
    } catch (e) {
      throw const AuthException('Invalid token format');
    }
  }
}
