import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class PurchaseSubscriptionUseCase {
  final SubscriptionRepository repository;

  PurchaseSubscriptionUseCase(this.repository);

  Future<Either<Failure, Subscription>> call(PurchaseSubscriptionParams params) async {
    return await repository.purchaseSubscription(params.plan, params.purchaseData);
  }
}

class PurchaseSubscriptionParams {
  final String plan;
  final Map<String, dynamic> purchaseData;

  PurchaseSubscriptionParams({
    required this.plan,
    required this.purchaseData,
  });
} 