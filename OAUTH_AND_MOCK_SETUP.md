# OAuth and Mock Mode Setup

This document explains how to use the newly implemented OAuth authentication and mock/debug mode features.

## OAuth Authentication

### Google Sign-In
- Added Google sign-in capability using `google_sign_in` package
- Works on both Android and iOS
- Shows Google sign-in button on login screen

### Apple Sign-In  
- Added Apple sign-in capability using `sign_in_with_apple` package
- Only shows on iOS devices (automatically hidden on Android)
- Integrates with Apple's Sign in with Apple service

### How OAuth Works
1. User taps Google/Apple sign-in button
2. OAuth service handles authentication flow
3. App receives user data (email, name, profile picture)
4. User is automatically signed in

## Mock/Debug Mode

### What is Mock Mode?
Mock mode allows you to run the app with simulated backend responses instead of connecting to real API services. This is perfect for:
- Frontend development without backend dependency
- Testing UI flows
- Demonstrating app functionality
- Development when backend is unavailable

### Features Available in Mock Mode
- **Authentication**: Mock login/register with predefined users
- **OAuth**: Simulated Google/Apple sign-in flows
- **Questions**: Mock AI responses with realistic explanations
- **History**: Pre-populated question history
- **Subscriptions**: Mock subscription status and usage data

### How to Enable Mock Mode

#### Option 1: Environment Variable
```bash
# Run with mock mode enabled
flutter run --dart-define=ENABLE_MOCK_MODE=true
```

#### Option 2: Temporary Code Change
In `lib/core/config/app_config.dart`, temporarily change:
```dart
static const bool enableMockMode = bool.fromEnvironment(
  'ENABLE_MOCK_MODE',
  defaultValue: true, // Change this to true for mock mode
);
```

### Mock Users Available
When mock mode is enabled, you can log in with these test accounts:

1. **Demo User**
   - Email: `demo@auralearn.com`
   - Password: `password123`
   - Plan: Pro (500 questions/month)
   - Usage: 25 questions used

2. **Student User**
   - Email: `student@example.com`  
   - Password: `student123`
   - Plan: Free (10 questions/month)
   - Usage: 8 questions used

### OAuth in Mock Mode
- Google Sign-In creates a mock user: `google.user@gmail.com`
- Apple Sign-In creates a mock user: `apple.user@icloud.com`
- Both get assigned realistic subscription plans and usage data

### Mock Question Responses
The mock question service provides:
- Realistic AI-generated explanations
- Step-by-step solutions
- Formula breakdowns
- Multiple subjects (Math, Physics, Chemistry, Biology, English, History)
- Varying difficulty levels
- Realistic processing delays (500-2500ms)

### Mock History Data
Pre-populated with:
- 8+ sample questions across different subjects
- Realistic timestamps (from 2 hours to 12 days ago)
- Confidence scores and difficulty ratings
- Searchable and filterable

### Mock Subscription Data
Includes:
- Current plan and usage tracking
- Billing cycle information
- Usage statistics and charts
- Available plans with pricing
- Subscription management (cancel/resume)

## Development Workflow

### Frontend Development
1. Enable mock mode: `flutter run --dart-define=ENABLE_MOCK_MODE=true`
2. Use any mock credentials to log in
3. Test all app features without backend dependency
4. OAuth flows work with simulated responses

### Backend Integration Testing
1. Disable mock mode (default): `flutter run`
2. Ensure backend services are running
3. Test with real API endpoints
4. OAuth requires proper Google/Apple developer setup

## Configuration Files

### App Config
- `lib/core/config/app_config.dart` - Main configuration with mock mode flag

### Dependency Injection
- `lib/core/di/injection_container.dart` - Automatically switches between real and mock services

### Mock Data Sources
- `lib/features/auth/data/datasources/mock_auth_data_source.dart`
- `lib/features/question/data/datasources/mock_question_data_source.dart`
- `lib/features/history/data/datasources/mock_history_data_source.dart`
- `lib/features/subscription/data/datasources/mock_subscription_data_source.dart`

## OAuth Setup for Production

### Google Sign-In Setup
1. Create project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Sign-In API
3. Configure OAuth consent screen
4. Add SHA-1 fingerprints for Android
5. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### Apple Sign-In Setup  
1. Enable "Sign in with Apple" in Apple Developer Console
2. Configure app identifier
3. No additional setup needed in app (handled by package)

## Troubleshooting

### Mock Mode Not Working
- Verify environment variable: `--dart-define=ENABLE_MOCK_MODE=true`
- Check app logs for "Mock" prefixed messages
- Ensure mock data sources are being used

### OAuth Issues
- Google: Check SHA-1 fingerprints and google-services files
- Apple: Ensure running on iOS device/simulator
- Verify OAuth packages are properly installed

### Build Errors
- Run `flutter clean && flutter pub get`
- Check all import statements in new files
- Verify pubspec.yaml dependencies are correct

## Benefits

### For Developers
- Faster development cycles
- No backend dependency for frontend work
- Consistent test data
- Easy demonstration of features

### For Testing
- Predictable responses for UI testing
- Various scenarios (different user types, subscription levels)
- Network-independent testing
- Realistic data for screenshots/demos

This implementation provides a robust foundation for both OAuth authentication and offline development capabilities.