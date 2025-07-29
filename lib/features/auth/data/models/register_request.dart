import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest extends Equatable {
  final String email;
  final String password;
  final String? name;
  final bool acceptTerms;
  final String? deviceId;
  final String? deviceName;
  final String? referralCode;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.name,
    required this.acceptTerms,
    this.deviceId,
    this.deviceName,
    this.referralCode,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  @override
  List<Object?> get props => [email, password, name, acceptTerms, deviceId, deviceName, referralCode];
} 