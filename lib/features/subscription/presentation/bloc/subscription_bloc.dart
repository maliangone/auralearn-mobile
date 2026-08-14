import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';
import '../../data/datasources/billing_remote_data_source.dart';
import '../../data/datasources/purchase_service.dart';
import '../../domain/entities/subscription_status.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

/// Drives the Phase 3 subscription flow (RevenueCat-authoritative).
///
/// Dependencies (both registered in the DI container):
/// * [billing] — proxy `/billing/sync` + `/billing/status` data source.
/// * [purchases] — [PurchaseService] wrapping RevenueCat. Purchases happen in
///   the store via RevenueCat; after a success the bloc calls
///   `billing.syncEntitlement()` so the SERVER re-reads RevenueCat and
///   persists the entitlement (the only source of truth the proxy routes on).
///
/// Status loads keep the existing 8s-timeout / offline-error behaviour:
/// [BillingRemoteDataSource] enforces the timeout and throws, and the bloc maps
/// any failure to [SubscriptionOfflineError] (the page renders 重试).
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final BillingRemoteDataSource billing;
  final PurchaseService purchases;

  SubscriptionBloc({
    required this.billing,
    required this.purchases,
  }) : super(const SubscriptionInitial()) {
    on<LoadStatus>(_onLoadStatus);
    on<BuyRequested>(_onBuyRequested);
    on<RestoreRequested>(_onRestoreRequested);

    // Idempotent RevenueCat configuration (skips itself when the RC_*
    // dart-defines are absent so dev builds keep working).
    purchases.ensureInitialized();
  }

  Future<void> _onLoadStatus(
    LoadStatus event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionLoading());
    try {
      final status = await billing.getStatus();

      // Best-effort price fetch for the upgrade CTA. Never fatal: a null price
      // just hides the label. Skipped entirely when the store is unavailable.
      String? priceLabel;
      if (status.isFree) {
        priceLabel = await purchases.getProPriceLabel();
      }

      AppLogger.info('Billing status loaded: ${status.plan}');
      emit(SubscriptionLoaded(status: status, priceLabel: priceLabel));
    } catch (e) {
      AppLogger.error('Failed to load billing status: $e');
      emit(SubscriptionOfflineError(message: _message(e)));
    }
  }

  Future<void> _onBuyRequested(
    BuyRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final previous = state;
    emit(const SubscriptionPurchasing());

    final result = await purchases.buyPro();

    switch (result.kind) {
      case PurchaseResultKind.success:
        await _refreshAfterPurchase(emit, previous);
        break;
      case PurchaseResultKind.storeUnavailable:
        emit(SubscriptionStoreUnavailable(status: _statusOf(previous)));
        break;
      case PurchaseResultKind.canceled:
        // User backed out — silently return to the prior loaded view.
        _restore(emit, previous);
        break;
      case PurchaseResultKind.pending:
        // Purchase is awaiting external action; keep the user informed.
        emit(const SubscriptionPurchaseError(message: '购买处理中，请稍后查看'));
        _restore(emit, previous);
        break;
      case PurchaseResultKind.error:
        emit(SubscriptionPurchaseError(message: result.message ?? '购买失败'));
        _restore(emit, previous);
        break;
    }
  }

  Future<void> _onRestoreRequested(
    RestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    final previous = state;
    emit(const SubscriptionPurchasing());

    final result = await purchases.restore();

    switch (result.kind) {
      case PurchaseResultKind.success:
        await _refreshAfterPurchase(emit, previous);
        break;
      case PurchaseResultKind.storeUnavailable:
        emit(SubscriptionStoreUnavailable(status: _statusOf(previous)));
        break;
      case PurchaseResultKind.canceled:
        _restore(emit, previous);
        break;
      case PurchaseResultKind.pending:
      case PurchaseResultKind.error:
        emit(SubscriptionPurchaseError(message: result.message ?? '恢复失败'));
        _restore(emit, previous);
        break;
    }
  }

  /// After a successful store purchase/restore: sync the server entitlement
  /// (the proxy re-reads RevenueCat itself), then re-read /billing/status.
  Future<void> _refreshAfterPurchase(
    Emitter<SubscriptionState> emit,
    SubscriptionState previous,
  ) async {
    try {
      final status = await billing.syncEntitlement();
      emit(SubscriptionPurchaseSuccess(status: status));
      emit(SubscriptionLoaded(status: status));
    } catch (e) {
      AppLogger.error('Status refresh after purchase failed: $e');
      // Purchase succeeded but the sync failed — show offline so the user can
      // retry; the RevenueCat webhook also updates the server asynchronously.
      emit(SubscriptionOfflineError(message: _message(e)));
    }
  }

  /// Returns the UI to [previous] if it was a loaded state, otherwise reloads.
  void _restore(Emitter<SubscriptionState> emit, SubscriptionState previous) {
    if (previous is SubscriptionLoaded) {
      emit(previous);
    } else {
      add(const LoadStatus());
    }
  }

  String _message(Object e) {
    if (e is BillingException) return e.message;
    if (e is ReceiptAlreadyUsedException) return e.message;
    return '暂时无法获取订阅信息，请检查网络后重试';
  }

  SubscriptionStatus? _statusOf(SubscriptionState s) =>
      s is SubscriptionLoaded ? s.status : null;

  @override
  Future<void> close() {
    // RevenueCat has no per-instance resources to dispose.
    return super.close();
  }
}
