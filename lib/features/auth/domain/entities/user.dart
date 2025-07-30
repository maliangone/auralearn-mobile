import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? avatar;
  final String subscriptionPlan;
  final DateTime? emailVerifiedAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  
  // Usage statistics
  final int usageCount;
  final int monthlyLimit;
  final DateTime? lastUsageReset;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.avatar,
    this.subscriptionPlan = 'free',
    this.emailVerifiedAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.usageCount = 0,
    this.monthlyLimit = 10, // Default free plan limit
    this.lastUsageReset,
  });

  // Computed properties for subscription features
  double get usagePercentage => monthlyLimit > 0 ? (usageCount / monthlyLimit).clamp(0.0, 1.0) : 0.0;
  
  bool get isNearLimit => usagePercentage >= 0.8;
  
  bool get hasReachedLimit => usageCount >= monthlyLimit;
  
  int get remainingUsage => (monthlyLimit - usageCount).clamp(0, monthlyLimit);
  
  bool get isEmailVerified => emailVerifiedAt != null;
  
  bool get isPremiumUser => subscriptionPlan != 'free';

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatar,
        subscriptionPlan,
        emailVerifiedAt,
        isActive,
        createdAt,
        updatedAt,
        metadata,
        usageCount,
        monthlyLimit,
        lastUsageReset,
      ];
} 