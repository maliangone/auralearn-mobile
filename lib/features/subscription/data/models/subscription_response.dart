import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'subscription_model.dart';

part 'subscription_response.g.dart';

@JsonSerializable()
class SubscriptionResponse extends Equatable {
  final SubscriptionModel subscription;
  final Map<String, dynamic> usageStats;

  const SubscriptionResponse({
    required this.subscription,
    required this.usageStats,
  });

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) => _$SubscriptionResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);

  @override
  List<Object?> get props => [subscription, usageStats];
} 