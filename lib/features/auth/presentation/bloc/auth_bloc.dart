import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/error/failures.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await checkAuthStatusUseCase.call();
    
    result.fold(
      (failure) {
        AppLogger.error('Auth check failed: ${failure.message}');
        emit(AuthUnauthenticated());
      },
      (user) {
        if (user != null) {
          AppLogger.info('User is authenticated: ${user.email}');
          emit(AuthAuthenticated(user: user));
        } else {
          AppLogger.info('User is not authenticated');
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final deviceInfo = await _getDeviceInfo();
    
    final params = LoginParams(
      email: event.email,
      password: event.password,
      rememberMe: event.rememberMe,
      deviceId: deviceInfo['deviceId'],
      deviceName: deviceInfo['deviceName'],
    );
    
    final result = await loginUseCase.call(params);
    
    result.fold(
      (failure) {
        AppLogger.error('Login failed: ${failure.message}');
        emit(AuthError(message: failure.message, code: failure.code));
      },
      (user) {
        AppLogger.info('Login successful: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final deviceInfo = await _getDeviceInfo();
    
    final params = RegisterParams(
      email: event.email,
      password: event.password,
      name: event.name,
      acceptTerms: event.acceptTerms,
      deviceId: deviceInfo['deviceId'],
      deviceName: deviceInfo['deviceName'],
      referralCode: event.referralCode,
    );
    
    final result = await registerUseCase.call(params);
    
    result.fold(
      (failure) {
        AppLogger.error('Registration failed: ${failure.message}');
        emit(AuthError(message: failure.message, code: failure.code));
      },
      (user) {
        AppLogger.info('Registration successful: ${user.email}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await logoutUseCase.call();
    
    result.fold(
      (failure) {
        AppLogger.error('Logout failed: ${failure.message}');
        // Even if logout fails on server, treat as successful locally
        emit(AuthUnauthenticated());
      },
      (_) {
        AppLogger.info('Logout successful');
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Don't emit loading for token refresh to avoid UI flickering
    // final result = await refreshTokenUseCase.call();
    
    // result.fold(
    //   (failure) {
    //     AppLogger.error('Token refresh failed: ${failure.message}');
    //     emit(AuthUnauthenticated());
    //   },
    //   (user) {
    //     AppLogger.info('Token refresh successful');
    //     emit(AuthAuthenticated(user: user));
    //   },
    // );
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceName': '${androidInfo.brand} ${androidInfo.model}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceName': '${iosInfo.name} ${iosInfo.model}',
        };
      }
    } catch (e) {
      AppLogger.error('Failed to get device info: $e');
    }
    
    return {
      'deviceId': 'unknown',
      'deviceName': 'unknown',
    };
  }
} 