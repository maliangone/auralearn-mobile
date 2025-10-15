# AuraLearn Mobile Setup Guide

This guide will help you set up the AuraLearn mobile app (Flutter) for development.

## Prerequisites

Before you begin, ensure you have the following installed:

### Mobile Requirements
- **Flutter SDK 3.0+** - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git** - [Download Git](https://git-scm.com/downloads/)

## Quick Setup (Mock Mode - Recommended)

1. **Clone the Repository**
```bash
git clone <repository-url>
cd auralearn-mobile
```

2. **Install Flutter Dependencies**
```bash
flutter pub get
```

3. **Run the App (Mock Mode)**
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or run on all connected devices
flutter run
```

**🎉 The app runs in mock mode by default - no backend setup required!**

## Mock Mode vs Real Backend

### Mock Mode (Default - Recommended for Development)
- App runs with simulated data
- Perfect for frontend development and testing
- No backend dependencies required
- All features work with mock responses

### Real Backend Mode
- Set `ENABLE_MOCK_MODE=false` in environment
- Requires running AuraLearn backend server
- See backend repository for setup instructions

## Development Workflow

### Mobile Development
- Make changes to Flutter code
- Hot reload is enabled by default
- Use `flutter analyze` to check for issues
- Run `flutter test` to run tests

### Code Quality
```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor
   ```
   Follow the recommendations to fix any issues.

2. **Dependencies Issues**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build Issues**
   ```bash
   # Clean build cache
   flutter clean
   
   # Reinstall dependencies
   flutter pub get
   
   # Rebuild
   flutter run
   ```

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review project issues on GitHub
- Contact the development team

## Configuration

### Mock Mode Configuration
The app runs in mock mode by default. To configure:

```dart
// In lib/core/config/app_config.dart
class AppConfig {
  static const bool enableMockMode = true; // Set to false for real backend
  static const String baseUrl = 'http://localhost:8000'; // Backend URL
}
```

### Environment Variables (for real backend)
If using real backend, set these environment variables:
```bash
ENABLE_MOCK_MODE=false
BACKEND_URL=http://localhost:8000
```

## Project Structure

```
auralearn-mobile/
├── lib/
│   ├── core/                    # Core utilities and shared code
│   │   ├── config/              # App configuration and constants
│   │   ├── di/                  # Dependency injection setup
│   │   ├── error/               # Error handling and exceptions
│   │   ├── network/             # HTTP client and interceptors
│   │   ├── router/              # App navigation and routing
│   │   ├── storage/             # Local storage utilities
│   │   ├── theme/               # App theming and styles
│   │   ├── usecases/            # Base use case classes
│   │   └── utils/               # Helper utilities and validators
│   └── features/                # Feature-based modules
│       ├── auth/                # Authentication and user management
│       ├── history/             # Question history management
│       ├── home/               # Home screen and navigation
│       ├── onboarding/         # App onboarding flow
│       ├── profile/            # User profile management
│       ├── question/           # Q&A functionality
│       └── subscription/       # Subscription management
├── pubspec.yaml                 # Flutter dependencies
└── README.md                    # Project documentation
```

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [BLoC Pattern](https://bloclibrary.dev/)
- [GoRouter Documentation](https://pub.dev/packages/go_router)

## Support

If you encounter any issues:
1. Check this setup guide
2. Review the error logs
3. Check the project's issue tracker
4. Reach out to the development team