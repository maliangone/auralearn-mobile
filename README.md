# AuraLearn Mobile App (Flutter)

Flutter mobile application for AuraLearn - an interactive Q&A education app that lets students capture images of textbook questions and get AI-powered answers with detailed explanations.

## Overview

This is the mobile frontend for AuraLearn, built with Flutter for cross-platform compatibility (Android & iOS). The app provides an intuitive interface for capturing and cropping question images, managing subscriptions, and viewing detailed AI-generated explanations.

## Features

- **Multi-Image Capture**: Support up to 3 images per question
- **Advanced Crop Tool**: Draggable rectangle handles for precise question selection
- **Camera Integration**: Native camera capture with real-time preview
- **AI-Powered Q&A**: Submit questions to multimodal language models
- **Usage Tracking**: Monitor subscription usage and token limits
- **Secure Authentication**: JWT-based authentication with auto-refresh
- **Subscription Management**: In-app billing with Stripe integration
- **Question History**: View past questions and answers
- **Cross-Platform**: Single codebase for Android and iOS

## Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: BLoC pattern
- **Dependency Injection**: GetIt service locator
- **HTTP Client**: Dio with interceptors
- **Image Processing**: Native camera and cropping tools
- **Storage**: Shared Preferences for local data
- **Authentication**: JWT tokens with auto-refresh
- **Navigation**: Go Router for type-safe routing

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
│       │   ├── data/           # Data sources and repositories
│       │   ├── domain/         # Business logic and entities
│       │   └── presentation/   # UI screens and widgets
│       ├── history/             # Question history management
│       ├── home/               # Home screen and navigation
│       ├── onboarding/         # App onboarding flow
│       ├── profile/            # User profile management
│       ├── question/           # Q&A functionality
│       └── subscription/       # Subscription management
│       ├── question/           # Question capture and processing
│       └── subscription/       # Subscription and billing
├── pubspec.yaml                 # Flutter dependencies
└── README.md                    # This file
```

## Architecture

This app follows **Clean Architecture** principles with **BLoC** state management:

- **Presentation Layer**: UI components, screens, and BLoC state management
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Repository implementations and data sources (local & remote)

## Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)

### Setup

1. **Install Flutter**
   - Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install)
   - Verify installation: `flutter doctor`

2. **Clone and Setup**
```bash
cd auralearn-mobile

# Install dependencies
flutter pub get

# Check for any issues
flutter doctor
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

### Mock Mode vs Real Backend
- **Mock Mode (Default)**: App runs with simulated data, perfect for frontend development
- **Real Backend**: Set `ENABLE_MOCK_MODE=false` to connect to live API

### Development

#### Running in Debug Mode
```bash
# Hot reload enabled for fast development
flutter run --debug
```

#### Building for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

#### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Project Configuration

### Backend API Configuration

Update the API base URL in `lib/core/network/auth_interceptor.dart`:

```dart
class NetworkConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  // static const String baseUrl = 'https://your-api-domain.com/api'; // Production
}
```

### Dependencies

Key dependencies used in this project:

- **State Management**: `flutter_bloc` - BLoC pattern implementation
- **Dependency Injection**: `get_it` - Service locator pattern
- **HTTP Client**: `dio` - Feature-rich HTTP client
- **Image Processing**: `image_picker`, `image_cropper` - Camera and crop functionality
- **Local Storage**: `shared_preferences` - Simple key-value storage
- **Navigation**: `go_router` - Declarative routing
- **JSON Handling**: `json_annotation`, `json_serializable` - Code generation

## Features Overview

### Authentication Flow
- User registration and login
- JWT token management with auto-refresh
- Secure token storage
- Logout functionality

### Question Processing
1. **Image Capture**: Use camera or gallery to select images
2. **Image Cropping**: Precise question area selection with drag handles
3. **Question Submission**: Send cropped images to AI backend
4. **Answer Display**: View detailed explanations with formatting

### Subscription Management
- View current subscription status
- Track usage and token limits
- Upgrade/downgrade subscription plans
- Stripe integration for secure payments

### User Experience
- Intuitive onboarding flow
- Dark/light theme support
- Responsive design for various screen sizes
- Smooth animations and transitions

## Development Guidelines

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex business logic
- Maintain consistent file and folder structure

### State Management
- Use BLoC pattern for complex state management
- Keep widgets stateless when possible
- Separate business logic from UI components
- Use events and states appropriately

### Testing
- Write unit tests for business logic
- Add widget tests for UI components
- Use integration tests for critical user flows
- Maintain test coverage above 80%

## Building and Deployment

### Android
1. **Configure signing** in `android/app/build.gradle`
2. **Generate signed APK**: `flutter build apk --release`
3. **Upload to Play Store** using Play Console

### iOS
1. **Configure signing** in Xcode
2. **Build archive**: `flutter build ios --release`
3. **Upload to App Store** using Xcode or Application Loader

### Environment Configuration
- Development: Use localhost API endpoints
- Staging: Use staging API endpoints
- Production: Use production API endpoints with proper security

## Troubleshooting

### Common Issues

**Flutter Doctor Issues**
- Install missing dependencies as suggested by `flutter doctor`
- Update Android SDK and tools if needed

**Build Errors**
- Run `flutter clean` and `flutter pub get`
- Check for version conflicts in `pubspec.yaml`
- Update Flutter and Dart SDK if needed

**Network Issues**
- Check backend API is running and accessible
- Verify API endpoints and base URL configuration
- Test with physical device if emulator has network issues

**Platform-Specific Issues**
- Android: Check Gradle and SDK versions
- iOS: Verify Xcode and CocoaPods setup

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the project coding standards
4. Write tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

MIT License - see LICENSE file for details 