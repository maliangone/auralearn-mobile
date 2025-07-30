import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../data/models/login_request.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call(LoginParams params) async {
    final request = LoginRequest(
      email: params.email,
      password: params.password,
      rememberMe: params.rememberMe,
      deviceId: params.deviceId,
      deviceName: params.deviceName,
    );

    return await repository.login(request);
  }
}

class LoginParams {
  final String email;
  final String password;
  final bool rememberMe;
  final String? deviceId;
  final String? deviceName;

  LoginParams({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.deviceId,
    this.deviceName,
  });
} 