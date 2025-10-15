import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/config/app_config.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/oauth_data_source.dart';
import '../datasources/mock_auth_data_source.dart';
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

      // In a real app, you'd send the OAuth token to your backend
      // For now, we'll create a mock auth response
      if (remoteDataSource != null) {
        // TODO: Implement backend OAuth verification
        // final authResponse = await remoteDataSource!.signInWithOAuth(oauthUser);
      }

      // For now, create a user from OAuth data
      final user = User(
        id: oauthUser.id,
        email: oauthUser.email,
        name: oauthUser.name ?? 'Google User',
        avatar: oauthUser.photoUrl,
        subscriptionPlan: 'free',
        usageCount: 0,
        monthlyLimit: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        emailVerifiedAt: DateTime.now(),
        metadata: {'provider': 'google'},
      );

      return Right(user);
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

      // In a real app, you'd send the OAuth token to your backend
      // For now, we'll create a mock auth response
      if (remoteDataSource != null) {
        // TODO: Implement backend OAuth verification
        // final authResponse = await remoteDataSource!.signInWithOAuth(oauthUser);
      }

      // For now, create a user from OAuth data
      final user = User(
        id: oauthUser.id,
        email: oauthUser.email.isNotEmpty
            ? oauthUser.email
            : 'apple.user@example.com',
        name: oauthUser.name ?? 'Apple User',
        avatar: oauthUser.photoUrl,
        subscriptionPlan: 'free',
        usageCount: 0,
        monthlyLimit: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        emailVerifiedAt: DateTime.now(),
        metadata: {'provider': 'apple'},
      );

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
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
    }
  }
}
