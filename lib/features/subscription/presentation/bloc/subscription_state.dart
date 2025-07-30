import 'package:equatable/equatable.dart';
import '../../domain/entities/subscription.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final Subscription subscription;
  final Map<String, dynamic> usageStats;

  const SubscriptionLoaded({
    required this.subscription,
    required this.usageStats,
  });

  @override
  List<Object?> get props => [subscription, usageStats];
}

class SubscriptionPurchasing extends SubscriptionState {}

class SubscriptionPurchaseSuccess extends SubscriptionState {
  final Subscription subscription;

  const SubscriptionPurchaseSuccess({required this.subscription});

  @override
  List<Object?> get props => [subscription];
}

class SubscriptionError extends SubscriptionState {
  final String message;
  final int? code;

  const SubscriptionError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
} 