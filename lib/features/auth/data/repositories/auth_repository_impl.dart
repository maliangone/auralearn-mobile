import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/oauth_user.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/config/app_config.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/oauth_data_source.dart';
import '../datasources/mock_auth_data_source.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource? remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final OAuthDataSource? oauthDataSource;
  final MockAuthDataSource? mockDataSource;

  AuthRepositoryImpl({
    this.remoteDataSource,
    required this.localDataSource,
    this.oauthDataSource,
    this.mockDataSource,
  });

  @override
  Future<Either<Failure, User>> login(LoginRequest request) async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final authResponse = await mockDataSource!.login(request);
        await localDataSource.saveAuthData(authResponse);
        return Right(_userModelToEntity(authResponse.user));
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final authResponse = await remoteDataSource!.login(request);
      await localDataSource.saveAuthData(authResponse);
      return Right(_userModelToEntity(authResponse.user));
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> register(RegisterRequest request) async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final authResponse = await mockDataSource!.register(request);
        await localDataSource.saveAuthData(authResponse);
        return Right(_userModelToEntity(authResponse.user));
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final authResponse = await remoteDataSource!.register(request);
      await localDataSource.saveAuthData(authResponse);
      return Right(_userModelToEntity(authResponse.user));
    } on DioError catch (e) {
      return Left(_handleDioException(e));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final authResponse =
            await mockDataSource!.signInWithGoogle('mock_google_token');
        await localDataSource.saveAuthData(authResponse);
        return Right(_userModelToEntity(authResponse.user));
      }

      if (oauthDataSource == null) {
        return const Left(AuthFailure('OAuth not available'));
      }

      final oauthUser = await oauthDataSource!.signInWithGoogle();
      final authResponse = await _exchangeOAuthForSession(oauthUser);
      await localDataSource.saveAuthData(authResponse);
      return Right(_userModelToEntity(authResponse.user));
    } on OAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        final authResponse =
            await mockDataSource!.signInWithApple('mock_apple_token');
        await localDataSource.saveAuthData(authResponse);
        return Right(_userModelToEntity(authResponse.user));
      }

      if (oauthDataSource == null) {
        return const Left(AuthFailure('OAuth not available'));
      }

      final oauthUser = await oauthDataSource!.signInWithApple();
      final authResponse = await _exchangeOAuthForSession(oauthUser);
      await localDataSource.saveAuthData(authResponse);
      return Right(_userModelToEntity(authResponse.user));
    } on OAuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// TOKEN-EXCHANGE SEAM (BYOK-proxy model).
  ///
  /// In production the AuraLearn account JWT is NOT minted on the device — it is
  /// issued by the accounts service (`AppConfig.accountsBaseUrl` / ACCOUNTS_URL)
  /// which verifies the provider [oauthUser.idToken] / [oauthUser.authorizationCode]
  /// and returns `{ accessToken, refreshToken, user }`. The proxy then verifies
  /// that account JWT's signature locally on every `/solve`.
  ///
  /// There is no real accounts backend yet, so this method builds a LOCAL DEV
  /// session so the rest of the app (router guards, `isLoggedIn`, secure token
  /// store) works end-to-end. Replace the body with the real call below.
  ///
  ///   TODO(integration): exchange OAuth identity -> account JWT at ACCOUNTS_URL.
  ///   e.g. add `AuthRemoteDataSource.exchangeOAuth(oauthUser)` ->
  ///     POST {accountsBaseUrl}/auth/oauth
  ///       { provider, idToken, authorizationCode? }
  ///     -> AuthResponse { accessToken, refreshToken, user }
  ///   Then: `return await remoteDataSource!.exchangeOAuth(oauthUser);`
  Future<AuthResponse> _exchangeOAuthForSession(OAuthUser oauthUser) async {
    final providerName =
        oauthUser.provider == OAuthProvider.google ? 'google' : 'apple';

    final email = oauthUser.email.isNotEmpty
        ? oauthUser.email
        : '$providerName.user@auralearn.local';

    final user = UserModel(
      id: oauthUser.id,
      email: email,
      name: oauthUser.name ??
          (oauthUser.provider == OAuthProvider.google
              ? 'Google User'
              : 'Apple User'),
      avatar: oauthUser.photoUrl,
      subscriptionPlan: 'free',
      usageCount: 0,
      monthlyLimit: AppConfig.subscriptionLimits['free'] ?? 10,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isEmailVerified: true,
      metadata: {'provider': providerName},
    );

    // Dev-only placeholder tokens. The real access/refresh tokens come from the
    // accounts service (see TODO above) and are what the proxy verifies.
    return AuthResponse(
      accessToken: _devToken('access', oauthUser, providerName),
      refreshToken: _devToken('refresh', oauthUser, providerName),
      user: user,
      expiresIn: 3600,
    );
  }

  /// Encodes a non-secret, clearly-marked dev token. NOT a real JWT; only used
  /// to keep the local session machinery functional until ACCOUNTS_URL lands.
  String _devToken(String kind, OAuthUser oauthUser, String provider) {
    final payload = json.encode({
      'dev': true,
      'kind': kind,
      'provider': provider,
      'sub': oauthUser.id,
    });
    return 'devoauth_${kind}_${base64Encode(utf8.encode(payload))}';
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      if (AppConfig.enableMockMode && mockDataSource != null) {
        await mockDataSource!.logout();
        await localDataSource.clearAuthData();
        return const Right(null);
      }

      if (remoteDataSource != null) {
        await remoteDataSource!.logout();
      }
      await localDataSource.clearAuthData();
      return const Right(null);
    } on DioError catch (e) {
      // Even if remote logout fails, clear local data
      await localDataSource.clearAuthData();
      return Left(_handleDioException(e));
    } catch (e) {
      await localDataSource.clearAuthData();
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null) {
        return const Left(AuthFailure('No refresh token available'));
      }

      if (AppConfig.enableMockMode && mockDataSource != null) {
        final authResponse = await mockDataSource!.refreshToken(refreshToken);
        await localDataSource.saveAuthData(authResponse);
        return Right(_userModelToEntity(authResponse.user));
      }

      if (remoteDataSource == null) {
        return const Left(NetworkFailure('No data source available'));
      }

      final authResponse = await remoteDataSource!.refreshToken(refreshToken);
      await localDataSource.saveAuthData(authResponse);
      return Right(_userModelToEntity(authResponse.user));
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        // Refresh token is invalid, clear auth data
        await localDataSource.clearAuthData();
        return const Left(AuthFailure('Session expired'));
      }
      return Left(_handleDioException(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = await localDataSource.getUser();
      if (userModel == null) {
        return const Left(AuthFailure('No user data found'));
      }
      return Right(_userModelToEntity(userModel));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await localDataSource.isLoggedIn();
      return Right(isLoggedIn);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  User _userModelToEntity(userModel) {
    return User(
      id: userModel.id,
      email: userModel.email,
      name: userModel.name,
      avatar: userModel.avatar,
      subscriptionPlan: userModel.subscriptionPlan,
      usageCount: userModel.usageCount,
      monthlyLimit: userModel.monthlyLimit,
      createdAt: userModel.createdAt,
      updatedAt: userModel.lastLoginAt ?? userModel.createdAt,
      emailVerifiedAt: userModel.isEmailVerified ? userModel.createdAt : null,
      metadata: userModel.metadata,
    );
  }

  Failure _handleDioException(DioError e) {
    switch (e.type) {
      case DioErrorType.connectTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioErrorType.response:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Server error';

        if (statusCode == 401) {
          return AuthFailure(message, code: statusCode);
        } else if (statusCode == 422) {
          return ValidationFailure(message, code: statusCode);
        } else {
          return ServerFailure(message, code: statusCode);
        }
      case DioErrorType.cancel:
        return const NetworkFailure('Request cancelled');
      case DioErrorType.other:
        return const NetworkFailure('No internet connection');
      default:
        return UnknownFailure(e.message);
    }
  }
}
