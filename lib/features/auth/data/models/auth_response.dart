import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'user_model.dart';

part 'auth_response.g.dart';

@JsonSerializable()
class AuthResponse extends Equatable {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final int expiresIn;
  final String tokenType;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  DateTime get expiresAt => DateTime.now().add(Duration(seconds: expiresIn));
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, user, expiresIn, tokenType];
} 