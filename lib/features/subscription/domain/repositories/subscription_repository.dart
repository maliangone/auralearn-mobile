import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Either<Failure, Map<String, dynamic>>> getSubscriptionStatus();
  Future<Either<Failure, Subscription>> purchaseSubscription(String plan, Map<String, dynamic> purchaseData);
  Future<Either<Failure, void>> cancelSubscription();
  Future<Either<Failure, Subscription>> restoreSubscription();
  Future<Either<Failure, Map<String, dynamic>>> getUsageStats();
} 