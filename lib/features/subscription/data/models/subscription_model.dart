import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel extends Equatable {
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

  const SubscriptionModel({
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

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) => _$SubscriptionModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

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