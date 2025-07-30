import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String subscriptionPlan;
  final int usageCount;
  final int monthlyLimit;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    required this.subscriptionPlan,
    required this.usageCount,
    required this.monthlyLimit,
    required this.createdAt,
    this.lastLoginAt,
    required this.isEmailVerified,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    String? subscriptionPlan,
    int? usageCount,
    int? monthlyLimit,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      usageCount: usageCount ?? this.usageCount,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasUsageRemaining => usageCount < monthlyLimit;
  
  double get usagePercentage => monthlyLimit > 0 ? (usageCount / monthlyLimit) : 0.0;
  
  bool get isNearLimit => usagePercentage >= 0.8;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatar,
        subscriptionPlan,
        usageCount,
        monthlyLimit,
        createdAt,
        lastLoginAt,
        isEmailVerified,
        metadata,
      ];
} 