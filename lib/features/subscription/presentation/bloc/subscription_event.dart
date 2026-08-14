import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load the current billing status from the proxy (called on page open + retry).
class LoadStatus extends SubscriptionEvent {
  const LoadStatus();
}

/// User tapped "升级 Pro" — start the store purchase flow.
class BuyRequested extends SubscriptionEvent {
  const BuyRequested();
}

/// User tapped "恢复购买" — restore prior store purchases.
class RestoreRequested extends SubscriptionEvent {
  const RestoreRequested();
}

/// Backwards-compatibility alias for out-of-lane callers (e.g. home_page)
/// that still dispatch the legacy "请求订阅状态" event. Handled identically to
/// [LoadStatus]. Prefer [LoadStatus] in new code.
class SubscriptionStatusRequested extends LoadStatus {
  const SubscriptionStatusRequested();
}
