import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest extends Equatable {
  final String email;
  final String password;
  final bool rememberMe;
  final String? deviceId;
  final String? deviceName;

  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.deviceId,
    this.deviceName,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);

  @override
  List<Object?> get props => [email, password, rememberMe, deviceId, deviceName];
} 