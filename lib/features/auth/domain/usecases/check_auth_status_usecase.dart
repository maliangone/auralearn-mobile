import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<Either<Failure, User?>> call() async {
    final isLoggedInResult = await repository.isLoggedIn();
    
    return isLoggedInResult.fold(
      (failure) => Left(failure),
      (isLoggedIn) async {
        if (isLoggedIn) {
          final userResult = await repository.getCurrentUser();
          return userResult.fold(
            (failure) => Left(failure),
            (user) => Right(user),
          );
        } else {
          return const Right(null);
        }
      },
    );
  }
} 