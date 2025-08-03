import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../data/models/register_request.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call(RegisterParams params) async {
    final request = RegisterRequest(
      email: params.email,
      password: params.password,
      name: params.name,
      acceptTerms: params.acceptTerms,
      deviceId: params.deviceId,
      deviceName: params.deviceName,
      referralCode: params.referralCode,
    );

    return await repository.register(request);
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String? name;
  final bool acceptTerms;
  final String? deviceId;
  final String? deviceName;
  final String? referralCode;

  RegisterParams({
    required this.email,
    required this.password,
    this.name,
    required this.acceptTerms,
    this.deviceId,
    this.deviceName,
    this.referralCode,
  });
} 