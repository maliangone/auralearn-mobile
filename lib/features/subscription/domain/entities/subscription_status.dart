import 'package:equatable/equatable.dart';

/// Phase C billing status, as reported by the proxy `GET /billing/status`.
///
/// Replaces the old Stripe-era [Subscription] entity for the IAP flow. The
/// proxy is the source of truth: it returns the current [plan] ('free' |
/// 'paid'), an optional store [tier] string, and an optional [expiresAt] for
/// the paid subscription. [freeDailyQuota] is carried for convenience so the
/// UI can render the free-tier copy ("每天 N 题") without re-reading config.
class SubscriptionStatus extends Equatable {
  /// 'free' or 'paid'.
  final String plan;

  /// Store tier / product identifier echoed back by the proxy (nullable for
  /// free accounts).
  final String? tier;

  /// When the paid subscription lapses. Null for free accounts (or when the
  /// proxy does not report an expiry).
  final DateTime? expiresAt;

  /// Free-tier daily question allowance (mirrors AppConfig.freeDailyQuota).
  final int freeDailyQuota;

  const SubscriptionStatus({
    required this.plan,
    this.tier,
    this.expiresAt,
    required this.freeDailyQuota,
  });

  /// True when the account is on the paid plan.
  bool get isPaid => plan == 'paid';

  /// True when on the free plan.
  bool get isFree => !isPaid;

  @override
  List<Object?> get props => [plan, tier, expiresAt, freeDailyQuota];
}
