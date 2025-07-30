// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionResponse _$SubscriptionResponseFromJson(
        Map<String, dynamic> json) =>
    SubscriptionResponse(
      subscription: SubscriptionModel.fromJson(
          json['subscription'] as Map<String, dynamic>),
      usageStats: json['usageStats'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SubscriptionResponseToJson(
        SubscriptionResponse instance) =>
    <String, dynamic>{
      'subscription': instance.subscription,
      'usageStats': instance.usageStats,
    };
