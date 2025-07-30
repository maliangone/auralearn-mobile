import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String? stripeSubscriptionId;
  final String? stripeCustomerId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    this.stripeSubscriptionId,
    this.stripeCustomerId,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == 'active';
  
  bool get isCanceled => status == 'canceled';
  
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(currentPeriodEnd);
  
  bool get willCancelAtPeriodEnd => cancelAtPeriodEnd && isActive;
  
  Duration get timeUntilRenewal => currentPeriodEnd.difference(DateTime.now());
  
  bool get isNearRenewal => timeUntilRenewal.inDays <= 7;

  @override
  List<Object?> get props => [
        id,
        userId,
        plan,
        status,
        currentPeriodStart,
        currentPeriodEnd,
        cancelAtPeriodEnd,
        stripeSubscriptionId,
        stripeCustomerId,
        metadata,
        createdAt,
        updatedAt,
      ];
} 