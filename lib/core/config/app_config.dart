class AppConfig {
  static const String appName = 'AuraLearn';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
  
  static const String authServiceUrl = String.fromEnvironment(
    'AUTH_SERVICE_URL',
    defaultValue: 'http://localhost:3001/api',
  );
  
  static const String imageServiceUrl = String.fromEnvironment(
    'IMAGE_SERVICE_URL',
    defaultValue: 'http://localhost:3002/api',
  );
  
  static const String lmGatewayUrl = String.fromEnvironment(
    'LM_GATEWAY_URL',
    defaultValue: 'http://localhost:3003/api',
  );
  
  static const String billingServiceUrl = String.fromEnvironment(
    'BILLING_SERVICE_URL',
    defaultValue: 'http://localhost:3005/api',
  );
  
  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  );
  
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );
  
  // App Constraints
  static const int maxImagesPerQuestion = 3;
  static const int maxImageSizeMB = 10;
  static const int historyAutoDeleteDays = 30;
  static const int responseTimeoutSeconds = 30;
  
  // Subscription Plans
  static const Map<String, int> subscriptionLimits = {
    'free': 10,
    'standard': 100,
    'pro': 500,
  };
  
  static const Map<String, double> subscriptionPrices = {
    'free': 0.0,
    'standard': 19.99,
    'pro': 39.99,
  };
  
  static const double overageRateStandard = 0.3;
  static const double overageRatePro = 0.2;
  
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