import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionStatusUseCase {
  final SubscriptionRepository repository;

  GetSubscriptionStatusUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call() async {
    return await repository.getSubscriptionStatus();
  }
} 