import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/oauth_user.dart';

/// Thrown when a provider sign-in fails or platform OAuth config is missing.
///
/// The [message] is user-presentable Chinese copy; [cause] keeps the raw SDK
/// error/exception for logging. The repository maps this to an `AuthFailure`.
class OAuthException implements Exception {
  final String message;
  final Object? cause;

  const OAuthException(this.message, {this.cause});

  @override
  String toString() => 'OAuthException: $message${cause != null ? ' ($cause)' : ''}';
}

/// User-facing fallback when platform OAuth config has not been supplied yet.
const String kOAuthNotConfiguredMessage = '未配置登录，请联系开发者';

abstract class OAuthDataSource {
  Future<OAuthUser> signInWithGoogle();
  Future<OAuthUser> signInWithApple();
}

/// Firebase Auth OAuth sign-in (Phase 3).
///
/// The AuraLearn account IS the Firebase user: Google/Apple credentials are
/// exchanged for a Firebase ID token on device, and the proxy verifies that
/// token on every `/solve`. No self-hosted accounts service exists anymore.
///
/// The returned [OAuthUser] carries the FIREBASE identity:
///   - `id`       = Firebase uid (`sub` claim of the ID token)
///   - `idToken`  = Firebase ID token (JWT) — the proxy verifies this.
///   - `accessToken` = same token (SecureTokenStore reads this slot).
///
/// =====================================================================
/// REQUIRED PLATFORM OAUTH CONFIG (developer must supply before this works)
/// =====================================================================
/// Without the items below the SDK calls throw at runtime; every call here is
/// wrapped in try/catch and surfaced as an [OAuthException] with a clear
/// Chinese message so the app never crashes when config is absent.
///
/// --- GOOGLE ---
/// 1. Firebase console: enable the Google provider in Authentication > Sign-in
///    method (the Web client ID is auto-created).
/// 2. Google Cloud Console: for Android, create an OAuth client with the app's
///    SHA-1 (debug + release); for iOS, add the REVERSED_CLIENT_ID URL scheme
///    in ios/Runner/Info.plist. The Firebase console "add fingerprint" flow
///    covers the Android side.
/// 3. Pass the Web client ID via --dart-define=FIREBASE_WEB_CLIENT_ID=... so
///    `serverClientId` is wired below (required for ID-token minting).
///
/// --- APPLE ---
/// 1. Apple Developer account; enable "Sign in with Apple" for the App ID.
/// 2. Xcode: add the capability (ios/Runner/Runner.entitlements ->
///    com.apple.developer.applesignin).
/// 3. Firebase console: enable the Apple provider with the Apple Services ID.
///    On Android the Apple web flow needs a Services ID + key — see
///    `webAuthenticationOptions` below (until then Apple is iOS-only).
/// =====================================================================
class OAuthDataSourceImpl implements OAuthDataSource {
  final GoogleSignIn _googleSignIn;
  final fb.FirebaseAuth? _firebaseAuthOverride;

  /// Resolved lazily: `FirebaseAuth.instance` throws when Firebase isn't
  /// initialized (dev mode without FIREBASE_* dart-defines), and DI builds
  /// this object at startup — so it must never be touched in the constructor.
  /// Sign-in methods guard on `FirebaseBootstrap.isReady` before use.
  fb.FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? fb.FirebaseAuth.instance;

  /// Both are injectable for testing. The default GoogleSignIn uses the Web
  /// client ID from the FIREBASE_WEB_CLIENT_ID dart-define (when provided) so
  /// the idToken is minted for Firebase to verify.
  OAuthDataSourceImpl({GoogleSignIn? googleSignIn, fb.FirebaseAuth? firebaseAuth})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: const String.fromEnvironment(
                'FIREBASE_WEB_CLIENT_ID',
                defaultValue: '',
              ),
            ),
        _firebaseAuthOverride = firebaseAuth;

  @override
  Future<OAuthUser> signInWithGoogle() async {
    try {
      if (!FirebaseBootstrap.isReady) {
        throw const OAuthException(
            '未配置登录（缺少 FIREBASE_* 配置），请联系开发者');
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User dismissed the Google account picker.
        throw const OAuthException('已取消 Google 登录');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw OAuthException(kOAuthNotConfiguredMessage, cause: 'no idToken');
      }

      final credential = fb.GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw OAuthException('Google 登录失败', cause: userCredential);

      return _toOAuthUser(user, OAuthProvider.google,
          displayName: account.displayName, photoUrl: account.photoUrl);
    } on OAuthException {
      rethrow;
    } catch (e) {
      // Missing google-services config / OAuth client ID, network errors, etc.
      throw OAuthException(kOAuthNotConfiguredMessage, cause: e);
    }
  }

  @override
  Future<OAuthUser> signInWithApple() async {
    try {
      if (!FirebaseBootstrap.isReady) {
        throw const OAuthException(
            '未配置登录（缺少 FIREBASE_* 配置），请联系开发者');
      }

      // Guard: the native Apple flow only exists on iOS/macOS; elsewhere the
      // web flow needs a Services ID (webAuthenticationOptions below).
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw const OAuthException('当前设备不支持 Apple 登录');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // To offer Apple sign-in on Android/Web, supply:
        // webAuthenticationOptions: WebAuthenticationOptions(
        //   clientId: '<your Apple Services ID>',
        //   redirectUri: Uri.parse('<your https redirect>'),
        // ),
      );

      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      final oauthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: identityToken,
        accessToken: authorizationCode,
      );
      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) throw OAuthException('Apple 登录失败', cause: userCredential);

      // Apple returns name parts only on the FIRST authorization; fall back to
      // the Firebase displayName when the local credential has none.
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ').trim();

      return _toOAuthUser(user, OAuthProvider.apple,
          displayName: fullName.isEmpty ? user.displayName : fullName);
    } on OAuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw OAuthException('已取消 Apple 登录', cause: e);
      }
      throw OAuthException(kOAuthNotConfiguredMessage, cause: e);
    } catch (e) {
      // Missing entitlement / Services ID / network errors, etc.
      throw OAuthException(kOAuthNotConfiguredMessage, cause: e);
    }
  }

  /// Maps a Firebase user to [OAuthUser]; `idToken`/`accessToken` both carry
  /// the Firebase ID token (the proxy's verification credential).
  Future<OAuthUser> _toOAuthUser(
    fb.User user,
    OAuthProvider provider, {
    String? displayName,
    String? photoUrl,
  }) async {
    final idToken = await user.getIdToken();
    return OAuthUser(
      id: user.uid,
      email: user.email ?? '',
      name: displayName ?? user.displayName,
      photoUrl: photoUrl ?? user.photoURL,
      provider: provider,
      idToken: idToken,
      accessToken: idToken,
    );
  }
}
