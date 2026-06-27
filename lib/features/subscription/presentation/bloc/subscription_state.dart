import 'package:equatable/equatable.dart';

import '../../domain/entities/subscription_status.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

/// Loading the billing status from the proxy.
class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

/// Status loaded. [status.isPaid] distinguishes the free vs paid UI.
/// [priceLabel] is the store-supplied localized price (e.g. "￥38.00/月"),
/// null when the product/price could not be fetched.
class SubscriptionLoaded extends SubscriptionState {
  final SubscriptionStatus status;
  final String? priceLabel;

  const SubscriptionLoaded({required this.status, this.priceLabel});

  @override
  List<Object?> get props => [status, priceLabel];

  SubscriptionLoaded copyWith({
    SubscriptionStatus? status,
    String? priceLabel,
  }) =>
      SubscriptionLoaded(
        status: status ?? this.status,
        priceLabel: priceLabel ?? this.priceLabel,
      );
}

/// A purchase or restore is in flight (show a blocking spinner).
class SubscriptionPurchasing extends SubscriptionState {
  const SubscriptionPurchasing();
}

/// A purchase/restore succeeded; carries the refreshed status.
class SubscriptionPurchaseSuccess extends SubscriptionState {
  final SubscriptionStatus status;
  const SubscriptionPurchaseSuccess({required this.status});

  @override
  List<Object?> get props => [status];
}

/// A purchase/restore failed (validation, store error, anti-replay, etc.).
/// The page shows a snackbar and falls back to the loaded state.
class SubscriptionPurchaseError extends SubscriptionState {
  final String message;
  const SubscriptionPurchaseError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// The device/store does not support in-app purchases (e.g. emulator).
class SubscriptionStoreUnavailable extends SubscriptionState {
  final SubscriptionStatus? status;
  const SubscriptionStoreUnavailable({this.status});

  @override
  List<Object?> get props => [status];
}

/// Could not reach the billing service (network / timeout). The page shows the
/// offline state with a 重试 button.
class SubscriptionOfflineError extends SubscriptionState {
  final String message;
  const SubscriptionOfflineError({required this.message});

  @override
  List<Object?> get props => [message];
}
