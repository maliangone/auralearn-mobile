import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

/// Outcome of a purchase/restore flow, surfaced to the bloc.
enum IapResultKind { success, canceled, pending, error, storeUnavailable }

class IapResult {
  final IapResultKind kind;
  final String? message;
  const IapResult(this.kind, {this.message});

  static const IapResult success = IapResult(IapResultKind.success);
  static const IapResult canceled = IapResult(IapResultKind.canceled);
  static const IapResult pending = IapResult(IapResultKind.pending);
  static const IapResult storeUnavailable =
      IapResult(IapResultKind.storeUnavailable, message: '当前设备不支持内购');
}

/// Signature for delivering a completed purchase's verification data to the
/// backend. Returns `true` if the backend accepted/validated the purchase.
typedef PurchaseVerifier = Future<bool> Function({
  required String platform,
  required String productId,
  required String verificationData,
});

/// Thin wrapper over [InAppPurchase] for the AuraLearn Pro subscription.
///
/// Responsibilities:
/// * query [AppConfig.proProductId] details from the store,
/// * kick off a non-consumable (subscription) purchase,
/// * listen to [InAppPurchase.purchaseStream], and on a `purchased`/`restored`
///   item hand the verification data (Apple receipt / Google purchase token)
///   to the injected [PurchaseVerifier] (which posts it to /billing/validate),
///   then [completePurchase] so the store stops re-delivering it,
/// * expose [restorePurchases].
///
/// Store-unavailable safety: every entry point first checks
/// [InAppPurchase.isAvailable]. On an emulator / unsupported device it returns
/// [IapResult.storeUnavailable] instead of throwing, so the app never crashes.
class IapService {
  final InAppPurchase _iap;
  final PurchaseVerifier _verifier;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Completer for the in-flight buy/restore flow so callers can await the
  /// asynchronous purchaseStream result.
  Completer<IapResult>? _pending;

  IapService({
    required PurchaseVerifier verifier,
    InAppPurchase? inAppPurchase,
  })  : _verifier = verifier,
        _iap = inAppPurchase ?? InAppPurchase.instance;

  /// 'apple' on iOS/macOS, 'google' on Android, per the proxy contract.
  String get _platform =>
      (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS)
          ? 'apple'
          : 'google';

  /// Subscribes to the purchase stream. Safe to call once at construction /
  /// bloc init. No-op if already listening.
  void init() {
    _sub ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        AppLogger.error('IAP purchaseStream error', error);
        _completePending(IapResult(IapResultKind.error, message: '$error'));
      },
    );
  }

  /// Whether the underlying store billing is available on this device.
  Future<bool> isAvailable() async {
    try {
      return await _iap.isAvailable();
    } catch (e) {
      AppLogger.error('IAP isAvailable() threw', e);
      return false;
    }
  }

  /// Looks up the Pro [ProductDetails] from the store, or null if the store is
  /// unavailable / the product is not found / not configured.
  Future<ProductDetails?> getProProduct() async {
    if (!await isAvailable()) return null;
    try {
      final response =
          await _iap.queryProductDetails({AppConfig.proProductId});
      if (response.error != null) {
        AppLogger.error(
            'queryProductDetails error: ${response.error!.message}');
      }
      if (response.notFoundIDs.contains(AppConfig.proProductId)) {
        AppLogger.error(
            'Pro product not found in store: ${AppConfig.proProductId}');
      }
      if (response.productDetails.isEmpty) return null;
      return response.productDetails.first;
    } catch (e) {
      AppLogger.error('queryProductDetails threw', e);
      return null;
    }
  }

  /// Initiates a Pro subscription purchase and resolves once the resulting
  /// purchase-stream event has been processed (verified with the backend or
  /// rejected). Returns [IapResult.storeUnavailable] on unsupported devices.
  Future<IapResult> buyPro() async {
    if (!await isAvailable()) return IapResult.storeUnavailable;

    final product = await getProProduct();
    if (product == null) {
      return const IapResult(IapResultKind.error, message: '暂时无法获取商品信息');
    }

    // Reset any stale completer and arm a fresh one.
    _pending = Completer<IapResult>();
    init();

    try {
      final param = PurchaseParam(productDetails: product);
      // Subscriptions are non-consumable.
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _completePending(
          const IapResult(IapResultKind.error, message: '无法发起购买'),
        );
      }
    } catch (e) {
      AppLogger.error('buyNonConsumable threw', e);
      _completePending(IapResult(IapResultKind.error, message: '$e'));
    }

    return _pending!.future;
  }

  /// Restores previously purchased subscriptions. Restored items flow through
  /// the same purchaseStream handler (verified + completed). Resolves with the
  /// outcome of the first restored item, or success/no-op once the request is
  /// acknowledged.
  Future<IapResult> restore() async {
    if (!await isAvailable()) return IapResult.storeUnavailable;

    _pending = Completer<IapResult>();
    init();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      AppLogger.error('restorePurchases threw', e);
      _completePending(IapResult(IapResultKind.error, message: '$e'));
      return _pending!.future;
    }

    // If no restored purchases arrive shortly, treat the restore as a no-op
    // (nothing to restore) rather than hanging the UI forever.
    return _pending!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => const IapResult(
        IapResultKind.error,
        message: '没有可恢复的购买',
      ),
    );
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Leave the spinner up; a follow-up event will resolve it.
          break;

        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completePending(IapResult.canceled);
          break;

        case PurchaseStatus.error:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          AppLogger.error(
              'Purchase error: ${purchase.error?.message ?? 'unknown'}');
          _completePending(IapResult(
            IapResultKind.error,
            message: purchase.error?.message ?? '购买失败',
          ));
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver(purchase);
          break;
      }
    }
  }

  Future<void> _deliver(PurchaseDetails purchase) async {
    try {
      final verificationData =
          purchase.verificationData.serverVerificationData;

      final ok = await _verifier(
        platform: _platform,
        productId: purchase.productID,
        verificationData: verificationData,
      );

      // Always complete the store transaction so it is not re-delivered.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      _completePending(
        ok
            ? IapResult.success
            : const IapResult(IapResultKind.error, message: '购买校验失败'),
      );
    } catch (e) {
      // Verifier surfaced an error (e.g. 409 anti-replay). Still complete the
      // transaction to avoid an infinite redelivery loop.
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
      AppLogger.error('Purchase delivery/verification failed', e);
      _completePending(IapResult(IapResultKind.error, message: _readable(e)));
    }
  }

  String _readable(Object e) {
    final s = e.toString();
    // Strip the exception type prefix for a cleaner user-facing message.
    final idx = s.indexOf(': ');
    return idx >= 0 && idx < 40 ? s.substring(idx + 2) : s;
  }

  void _completePending(IapResult result) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(result);
    }
    _pending = null;
  }

  /// Cancels the stream subscription. Call when the owner is disposed.
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
