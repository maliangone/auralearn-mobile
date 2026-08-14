import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/rc_config.dart';
import '../../../../core/utils/logger.dart';

/// Outcome of a purchase/restore flow, surfaced to the bloc. Same shape as the
/// legacy [IapResultKind] so the SubscriptionBloc state machine is unchanged.
enum PurchaseResultKind { success, canceled, pending, error, storeUnavailable }

class PurchaseResult {
  final PurchaseResultKind kind;
  final String? message;
  const PurchaseResult(this.kind, {this.message});

  static const PurchaseResult success = PurchaseResult(PurchaseResultKind.success);
  static const PurchaseResult canceled = PurchaseResult(PurchaseResultKind.canceled);
  static const PurchaseResult pending = PurchaseResult(PurchaseResultKind.pending);
  static const PurchaseResult storeUnavailable =
      PurchaseResult(PurchaseResultKind.storeUnavailable, message: '当前设备不支持内购');
}

/// RevenueCat subscription service (Phase 3) — port of the yijing app's
/// PurchaseService. The `purchases_flutter` API is fully static, so this class
/// is a thin stateful wrapper (configured-flag + result mapping).
///
/// Responsibilities:
/// * idempotent `Purchases.configure` (only with REAL platform keys — a fake
///   key would crash at runtime, so unconfigured apps just report
///   [storeUnavailable] like the old IAP path did),
/// * bind the RevenueCat appUserID to the Firebase uid so the proxy can query
///   `GET /v1/subscribers/{uid}` server-side,
/// * `isPro()` from `CustomerInfo.entitlements.active['pro']` (UI-only; the
///   server stays authoritative),
/// * purchase / restore via `Purchases.purchase` / `restorePurchases`.
///
/// After a successful purchase the caller MUST `POST /billing/sync` so the
/// server re-reads RevenueCat and persists the entitlement (the only source of
/// truth the proxy routes on).
class PurchaseService {
  Future<void>? _initFuture;
  bool _configured = false;

  /// Idempotent initialization. Configures RevenueCat only when real platform
  /// keys are compiled in; otherwise stays inert (storeUnavailable flows).
  Future<void> ensureInitialized() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    if (!RcConfig.isConfigured) {
      AppLogger.info('RevenueCat not configured (no RC_* dart-defines); '
          'subscription store is unavailable.');
      return;
    }
    try {
      final key = defaultTargetPlatform == TargetPlatform.android
          ? RcConfig.googleApiKey
          : RcConfig.appleApiKey;
      await Purchases.configure(PurchasesConfiguration(key));
      _configured = true;
      AppLogger.info('RevenueCat configured');
    } catch (e) {
      // Never crash startup over RevenueCat; purchase flows surface the error.
      AppLogger.error('RevenueCat configuration failed', e);
    }
  }

  bool get isStoreAvailable => _configured;

  /// Binds the RevenueCat identity to the Firebase account uid, mirroring
  /// yijing (server queries subscribers/{uid}; anonymous RC ids never buy).
  Future<void> logInFirebaseUid(String uid) async {
    if (!_configured) return;
    try {
      final info = await Purchases.logIn(uid);
      AppLogger.info(
          'RevenueCat logged in as ${info.customerInfo.originalAppUserId}');
    } catch (e) {
      AppLogger.error('RevenueCat logIn failed', e);
    }
  }

  Future<void> logOut() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      AppLogger.error('RevenueCat logOut failed', e);
    }
  }

  /// UI-only entitlement check. The server remains authoritative for routing.
  Future<bool> isPro() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(RcConfig.kEntitlementId);
    } catch (e) {
      AppLogger.error('RevenueCat isPro check failed', e);
      return false;
    }
  }

  /// Store-localized price for the Pro monthly product, or null when the
  /// store is unavailable (the UI hides the price label then).
  Future<String?> getProPriceLabel() async {
    if (!_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      return _findProPackage(offerings)?.storeProduct.priceString;
    } catch (e) {
      AppLogger.error('RevenueCat offerings failed', e);
      return null;
    }
  }

  /// Starts a Pro purchase from the current offering. Returns [success] only
  /// after the store sheet completes and the entitlement appears active.
  Future<PurchaseResult> buyPro() async {
    if (!_configured) return PurchaseResult.storeUnavailable;
    try {
      final offerings = await Purchases.getOfferings();
      final pkg = _findProPackage(offerings);
      if (pkg == null) {
        return const PurchaseResult(PurchaseResultKind.error, message: '未找到订阅商品');
      }
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      if (result.customerInfo.entitlements.active
          .containsKey(RcConfig.kEntitlementId)) {
        return PurchaseResult.success;
      }
      // The store completed but the entitlement is not active yet — RevenueCat
      // is still processing; treat as pending (user should check back).
      return PurchaseResult.pending;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.canceled;
      }
      AppLogger.error('RevenueCat purchase failed', e);
      return PurchaseResult(PurchaseResultKind.error,
          message: e.message ?? '购买失败');
    } catch (e) {
      AppLogger.error('RevenueCat purchase failed', e);
      return PurchaseResult(PurchaseResultKind.error, message: '购买失败');
    }
  }

  /// Restores a previous purchase (new device / reinstall).
  Future<PurchaseResult> restore() async {
    if (!_configured) return PurchaseResult.storeUnavailable;
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active.containsKey(RcConfig.kEntitlementId)) {
        return PurchaseResult.success;
      }
      return const PurchaseResult(PurchaseResultKind.error, message: '没有可恢复的订阅');
    } on PlatformException catch (e) {
      AppLogger.error('RevenueCat restore failed', e);
      return PurchaseResult(PurchaseResultKind.error,
          message: e.message ?? '恢复失败');
    } catch (e) {
      AppLogger.error('RevenueCat restore failed', e);
      return PurchaseResult(PurchaseResultKind.error, message: '恢复失败');
    }
  }

  /// Picks the Pro monthly package from the current offering (matches
  /// `auralearn_pro_monthly`; falls back to any package).
  Package? _findProPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;
    return current.monthly ??
        current.availablePackages.where(
          (p) => p.storeProduct.identifier == _proProductId,
        ).firstOrNull ??
        current.availablePackages.firstOrNull;
  }

  /// Store product id — must match App Store Connect / Google Play Console.
  static const String _proProductId = 'auralearn_pro_monthly';
}
