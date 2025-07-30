// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
      acceptTerms: json['acceptTerms'] as bool,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      referralCode: json['referralCode'] as String?,
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'acceptTerms': instance.acceptTerms,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'referralCode': instance.referralCode,
    };
