import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';
import '../../data/datasources/billing_remote_data_source.dart';
import '../../data/datasources/iap_service.dart';
import '../../domain/entities/subscription_status.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

/// Drives the Phase C subscription / IAP flow.
///
/// Dependencies (both registered in the DI container — see integration notes):
/// * [billing] — proxy `/billing/validate` + `/billing/status` data source.
/// * [iap] — [IapService] wrapping `in_app_purchase`. Its verifier callback
///   (wired in DI) posts completed store receipts to [billing]'s
///   `validatePurchase`; the bloc then re-reads `/billing/status`.
///
/// Status loads keep the existing 8s-timeout / offline-error behaviour:
/// [BillingRemoteDataSource] enforces the timeout and throws, and the bloc maps
/// any failure to [SubscriptionOfflineError] (the page renders 重试).
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final BillingRemoteDataSource billing;
  final IapService iap;

  SubscriptionBloc({
    required this.billing,
    required this.iap,
  }) : super(const SubscriptionInitial()) {
    on<LoadStatus>(_onLoadStatus);
    on<BuyRequested>(_onBuyRequested);
    on<RestoreRequested>(_onRestoreRequested);

    // Wire the store-receipt verifier to the proxy validate endpoint and
    // start listening to the purchase stream immediately so events that fire
    // outside an explicit buy() (store front purchases, pending completions)
    // are still delivered.
    iap.init();
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
        final product = await iap.getProProduct();
        priceLabel = product?.price;
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

    final result = await iap.buyPro();

    switch (result.kind) {
      case IapResultKind.success:
        await _refreshAfterPurchase(emit, previous);
        break;
      case IapResultKind.storeUnavailable:
        emit(SubscriptionStoreUnavailable(status: _statusOf(previous)));
        break;
      case IapResultKind.canceled:
        // User backed out — silently return to the prior loaded view.
        _restore(emit, previous);
        break;
      case IapResultKind.pending:
        // Purchase is awaiting external action; keep the user informed.
        emit(const SubscriptionPurchaseError(message: '购买处理中，请稍后查看'));
        _restore(emit, previous);
        break;
      case IapResultKind.error:
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

    final result = await iap.restore();

    switch (result.kind) {
      case IapResultKind.success:
        await _refreshAfterPurchase(emit, previous);
        break;
      case IapResultKind.storeUnavailable:
        emit(SubscriptionStoreUnavailable(status: _statusOf(previous)));
        break;
      case IapResultKind.canceled:
        _restore(emit, previous);
        break;
      case IapResultKind.pending:
      case IapResultKind.error:
        emit(SubscriptionPurchaseError(message: result.message ?? '恢复失败'));
        _restore(emit, previous);
        break;
    }
  }

  /// Re-reads /billing/status after a successful purchase/restore and emits a
  /// success state, falling back to a fresh loaded state.
  Future<void> _refreshAfterPurchase(
    Emitter<SubscriptionState> emit,
    SubscriptionState previous,
  ) async {
    try {
      final status = await billing.getStatus();
      emit(SubscriptionPurchaseSuccess(status: status));
      emit(SubscriptionLoaded(status: status));
    } catch (e) {
      AppLogger.error('Status refresh after purchase failed: $e');
      // Purchase succeeded but status read failed — show offline so the user
      // can retry; the proxy already recorded the entitlement.
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
    iap.dispose();
    return super.close();
  }
}
