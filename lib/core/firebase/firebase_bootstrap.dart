import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../utils/logger.dart';

/// Firebase bootstrap for the app account identity (Phase 3).
///
/// The AuraLearn account IS a Firebase Auth user: Google/Apple sign-in happens
/// in Firebase, and the Firebase ID token is what the proxy verifies on every
/// `/solve` (replacing the Phase A dev token entirely).
///
/// Configuration is dart-define based — no `flutterfire configure` and no
/// `google-services.json` are required:
///
///   flutter run --dart-define=FIREBASE_API_KEY=... \
///               --dart-define=FIREBASE_APP_ID=... \
///               --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
///               --dart-define=FIREBASE_PROJECT_ID=... \
///               --dart-define=FIREBASE_ANDROID_CLIENT_ID=... \
///               --dart-define=FIREBASE_IOS_CLIENT_ID=...
///
/// Until those are supplied the app runs WITHOUT Firebase (dev mode): OAuth
/// sign-in surfaces a clear "not configured" error and everything else works.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  /// True once Firebase is initialized AND configured.
  static bool get isReady => Firebase.apps.isNotEmpty;

  /// Initializes Firebase when the FIREBASE_* dart-defines are present.
  /// No-op (and fast) when they are absent, so dev builds never block on it.
  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    if (const String.fromEnvironment('FIREBASE_PROJECT_ID').isEmpty) {
      AppLogger.info(
          'Firebase not configured (no FIREBASE_PROJECT_ID dart-define); '
          'running without Firebase Auth.');
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized');
    } catch (e) {
      // Never crash startup over Firebase config; sign-in will surface it.
      AppLogger.error('Firebase initialization failed', e);
    }
  }

  /// The signed-in Firebase user, or null when Firebase is off / signed out.
  static User? get currentUser => FirebaseAuth.instance.currentUser;
}
