class AppConfig {
  static const String appName = 'AuraLearn';
  static const String appVersion = '1.0.0';

  // API Endpoints
  //
  // Phase A0: the old per-service localhost URLs (auth/image/lm-gateway/
  // billing) are removed in favor of a single stateless streaming proxy plus a
  // separate accounts service. Android emulator reaches the host via 10.0.2.2.
  //
  // - proxyBaseUrl    -> SSE `/solve` streaming proxy (see SolveClient).
  // - accountsBaseUrl -> auth / accounts / metering service.
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );

  static const String accountsBaseUrl = String.fromEnvironment(
    'ACCOUNTS_URL',
    defaultValue: 'http://10.0.2.2:8788',
  );

  /// Compatibility alias for legacy callers (e.g. dio/Retrofit DI wiring).
  /// Points at the proxy; remove once all callers migrate off `baseUrl`.
  static String get baseUrl => proxyBaseUrl;

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );

  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );

  static const bool enableMockMode = bool.fromEnvironment(
    'ENABLE_MOCK_MODE',
    defaultValue: true,
  );

  // App Constraints
  static const int maxImagesPerQuestion = 3;
  static const int maxImageSizeMB = 10;
  static const int historyAutoDeleteDays = 30;
  static const int responseTimeoutSeconds = 30;

  // Subscription Plans (Phase C: store-billed IAP, two tiers).
  //
  // The old three-tier Stripe model (free/standard/pro with metered quotas and
  // overage rates) is gone. Billing is now a single non-consumable monthly
  // subscription validated through the store + proxy `/billing/*` endpoints.
  //
  // NOTE: the real price and localized display string are configured in
  // App Store Connect (iOS) and Google Play Console (Android) against the
  // [proProductId] below — the app never hardcodes a price. The store returns
  // the price via `ProductDetails.price`.

  /// Free tier: questions allowed per calendar day before an upgrade is needed.
  static const int freeDailyQuota = 3;

  /// Store product identifier for the Pro monthly subscription. Must match the
  /// product id created in App Store Connect / Google Play Console.
  static const String proProductId = 'auralearn_pro_monthly';

  // --- Backwards-compatibility shims -------------------------------------
  // Older callers referenced `subscriptionLimits` / `subscriptionPrices`.
  // These map onto the new two-tier (free/paid) model so nothing breaks while
  // the rest of the app migrates. Prefer [freeDailyQuota] / store-supplied
  // prices in new code.
  @Deprecated('Use freeDailyQuota; paid tier has no fixed client-side quota.')
  static const Map<String, int> subscriptionLimits = {
    'free': freeDailyQuota,
    'paid': -1, // -1 == effectively unlimited / not client-enforced
  };

  @Deprecated('Price comes from the store (ProductDetails.price), not the app.')
  static const Map<String, double> subscriptionPrices = {
    'free': 0.0,
    'paid': 0.0, // real price configured in the store, fetched at runtime
  };

  // Image Processing
  static const int maxImageWidth = 2048;
  static const int maxImageHeight = 2048;
  static const double imageQuality = 0.8;

  // Cache Settings
  static const int imageCacheDuration = 7; // days
  static const int apiCacheDuration = 5; // minutes

  // Environment
  static bool get isProduction =>
      const String.fromEnvironment('ENVIRONMENT') == 'production';

  static bool get isDevelopment =>
      const String.fromEnvironment('ENVIRONMENT') == 'development';

  static bool get isDebug => !isProduction;
}
