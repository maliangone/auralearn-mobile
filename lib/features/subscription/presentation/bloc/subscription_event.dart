import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class SubscriptionStatusRequested extends SubscriptionEvent {}

class SubscriptionPurchaseRequested extends SubscriptionEvent {
  final String plan;
  final Map<String, dynamic> purchaseData;

  const SubscriptionPurchaseRequested({
    required this.plan,
    required this.purchaseData,
  });

  @override
  List<Object?> get props => [plan, purchaseData];
}

class SubscriptionCancelRequested extends SubscriptionEvent {}

class SubscriptionRestoreRequested extends SubscriptionEvent {}

class UsageUpdated extends SubscriptionEvent {
  final int newUsageCount;

  const UsageUpdated({required this.newUsageCount});

  @override
  List<Object?> get props => [newUsageCount];
} 