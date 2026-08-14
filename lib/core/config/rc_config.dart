/// RevenueCat configuration (Phase 3).
///
/// The platform API keys are PUBLIC (they only identify the app; they cannot
/// mint entitlements) and arrive via --dart-define so nothing secret lives in
/// the repo:
///
///   flutter run \
///     --dart-define=RC_GOOGLE_API_KEY=goog_... \
///     --dart-define=RC_APPLE_API_KEY=appl_...
///
/// Until keys are supplied, [PurchaseService] skips RevenueCat configuration
/// and subscription UI shows "store unavailable" — the rest of the app works.
class RcConfig {
  RcConfig._();

  static const String googleApiKey =
      String.fromEnvironment('RC_GOOGLE_API_KEY');

  static const String appleApiKey =
      String.fromEnvironment('RC_APPLE_API_KEY');

  /// Entitlement identifier configured in the RevenueCat dashboard. The proxy
  /// checks this same id server-side (RevenueCat REST API).
  static const String kEntitlementId = 'pro';

  /// True when at least one real platform key is configured (goog_/appl_).
  static bool get isConfigured =>
      googleApiKey.startsWith('goog_') || appleApiKey.startsWith('appl_');
}
