# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run development server with hot reload
flutter run

# Run on specific device
flutter run -d <device-id>

# List available devices
flutter devices

# Clean build cache
flutter clean

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Build Commands
```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

### Code Generation
```bash
# Generate API client code
flutter pub run build_runner build lib/core/network/api_client.dart

# Generate JSON serialization code
flutter pub run build_runner build --delete-conflicting-outputs

# Generate Hive type adapters
flutter pub run build_runner build
```

### Linting and Analysis
```bash
# Run Flutter linting
flutter analyze

# Run custom linting rules
flutter pub run flutter_lints
```

## Architecture Overview

This is a Flutter mobile app for AuraLearn, an educational Q&A platform that follows **Clean Architecture** with **BLoC** state management.

### Core Architecture Pattern
- **Presentation Layer**: Flutter widgets + BLoC state management
- **Domain Layer**: Business logic, use cases, and entities  
- **Data Layer**: Repository implementations with remote/local data sources

### Project Structure
```
lib/
├── core/                          # Shared infrastructure
│   ├── di/                        # Dependency injection (GetIt)
│   ├── network/                   # HTTP client (Dio) + interceptors
│   ├── router/                    # GoRouter navigation
│   ├── storage/                   # Local storage (SharedPreferences)
│   ├── theme/                     # App theming and styling
│   └── utils/                     # Shared utilities
├── features/                      # Feature modules
│   ├── auth/                      # Authentication flow
│   │   ├── data/                  # Data sources, models, repositories
│   │   ├── domain/                # Business logic, entities, use cases
│   │   └── presentation/          # UI screens, widgets, BLoC
│   ├── home/                      # Home dashboard
│   ├── question/                  # Question capture & processing
│   │   ├── data/                  # Image upload, question processing
│   │   ├── domain/                # Question entities, use cases
│   │   └── presentation/          # Camera, crop, chat interfaces
│   ├── subscription/              # Subscription management
│   │   ├── data/                  # Subscription data, Stripe integration
│   │   ├── domain/                # Subscription entities, use cases
│   │   └── presentation/          # Subscription UI, BLoC
│   ├── history/                   # Question history management
│   │   ├── data/                  # History data sources, models
│   │   ├── domain/                # History entities, use cases
│   │   └── presentation/          # History UI, BLoC
│   └── onboarding/                # App onboarding flow
└── main.dart                      # App entry point
```

### Key Technologies
- **State Management**: BLoC pattern with flutter_bloc
- **Dependency Injection**: GetIt service locator
- **HTTP Client**: Dio with Retrofit for API calls
- **Navigation**: GoRouter for declarative routing
- **Local Storage**: SharedPreferences + Hive
- **Image Processing**: image_picker + image_cropper
- **Code Generation**: Retrofit, JSON Serializable, Hive generators

### Feature Module Structure
Each feature follows the same clean architecture pattern:
```
features/feature_name/
├── data/                          # Data layer
│   ├── datasources/               # Remote/local data sources
│   ├── models/                    # Data models with JSON serialization
│   └── repositories/              # Repository implementations
├── domain/                        # Business logic layer
│   ├── entities/                  # Business entities
│   ├── repositories/              # Repository interfaces
│   └── usecases/                  # Business use cases
└── presentation/                  # UI layer
    ├── bloc/                      # BLoC state management
    ├── pages/                     # Screen widgets
    └── widgets/                   # Reusable UI components
```

## Development Guidelines

### Dependency Injection
- All dependencies are registered in `lib/core/di/injection_container.dart`
- Use `getIt<T>()` to access dependencies
- Register services as `LazySingleton` for performance
- BLoC instances use `registerFactory` to create new instances per widget

### API Integration
- API client uses Retrofit with Dio HTTP client
- Authentication handled via `AuthInterceptor` 
- All API endpoints defined in `lib/core/network/api_client.dart`
- Request/response models use JSON annotation for serialization

### State Management
- Use BLoC pattern for complex state management
- Events represent user actions/intents
- States represent UI states (loading, success, error, etc.)
- Keep widgets stateless when possible

### Code Generation
- Run `flutter pub run build_runner build` after modifying:
  - API client endpoints
  - JSON models
  - Hive type adapters
- Use `--delete-conflicting-outputs` flag if needed

### Configuration
- Backend API URL configured in `lib/core/config/app_config.dart`
- Use different URLs for development vs production
- Android emulator uses `10.0.2.2` for localhost
- iOS simulator uses `localhost`

## Important Notes

### API Configuration
The app connects to a Django backend API. Update the base URL in `lib/core/config/app_config.dart` based on your environment:
- Development: `http://10.0.2.2:8000/api` (Android emulator)
- Development: `http://localhost:8000/api` (iOS simulator)  
- Production: `https://your-api-domain.com/api`

### Required Backend Services
- Django REST API with authentication endpoints
- PostgreSQL database
- Redis for caching/sessions
- Stripe integration for subscriptions

### Image Processing
- Supports multi-image capture (up to 3 images per question)
- Advanced cropping with draggable rectangle handles
- Images are uploaded to backend for AI processing

### Authentication Flow
- JWT-based authentication with auto-refresh
- Tokens stored securely in SharedPreferences
- AuthInterceptor handles token injection and refresh

### Subscription Management
- In-app purchases via Stripe
- Usage tracking and token limits
- Real-time subscription status updates

### History Management
- View and manage question history
- Delete individual history items
- Clear entire history
- Pagination support for large history datasets