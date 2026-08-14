import 'package:firebase_core/firebase_core.dart';

/// Firebase options fed entirely by `--dart-define` (no flutterfire codegen,
/// no committed google-services.json — keys are build-time inputs, not repo
/// secrets). Values come from the Firebase console after creating the project:
///
///   flutter run \
///     --dart-define=FIREBASE_API_KEY=AIza... \
///     --dart-define=FIREBASE_APP_ID=1:1234567890:android:abc... \
///     --dart-define=FIREBASE_MESSAGING_SENDER_ID=1234567890 \
///     --dart-define=FIREBASE_PROJECT_ID=auralearn-xxxx \
///     --dart-define=FIREBASE_ANDROID_CLIENT_ID=1234567890-....apps.googleusercontent.com \
///     --dart-define=FIREBASE_IOS_CLIENT_ID=... (iOS client id / reversed) \
///     --dart-define=FIREBASE_IOS_BUNDLE_ID=com.maliangone.auralearn (iOS only)
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
      appId: const String.fromEnvironment('FIREBASE_APP_ID'),
      messagingSenderId:
          const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      // Optional; only needed for Firebase features that use them.
      storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      androidClientId:
          const String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID'),
      iosClientId: const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID'),
      iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    );
  }
}
