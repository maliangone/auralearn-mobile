import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';

import '../repositories/auth_repository.dart';

class GoogleSignInUseCase implements UseCase<User, NoParams> {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}

class AppleSignInUseCase implements UseCase<User, NoParams> {
  final AuthRepository repository;

  AppleSignInUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(NoParams params) async {
    return await repository.signInWithApple();
  }
}
