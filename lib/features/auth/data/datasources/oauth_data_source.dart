import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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

/// Real OAuth provider sign-in.
///
/// =====================================================================
/// REQUIRED PLATFORM OAUTH CONFIG (developer must supply before this works)
/// =====================================================================
/// Without the items below the SDK calls throw at runtime; every call here is
/// wrapped in try/catch and surfaced as an [OAuthException] with a clear
/// Chinese message so the app never crashes when config is absent.
///
/// --- GOOGLE (google_sign_in) ---
/// 1. Google Cloud Console project with OAuth consent screen configured.
/// 2. ANDROID:
///    - Create an "Android" OAuth client ID using the app's package name
///      (`com.example.auralearn` or the real applicationId) + the SHA-1/SHA-256
///      of your debug AND release signing keys.
///    - Download `google-services.json` and place it at
///      `android/app/google-services.json`.
///    - Apply the Google Services Gradle plugin
///      (`com.google.gms.google-services`) in `android/build.gradle` +
///      `android/app/build.gradle`.  [OUT OF LANE: integration owns Gradle.]
/// 3. iOS:
///    - Create an "iOS" OAuth client ID; download `GoogleService-Info.plist`
///      into `ios/Runner/`.
///    - Add the REVERSED_CLIENT_ID as a URL scheme in
///      `ios/Runner/Info.plist` (CFBundleURLTypes).
///    - If you pass a `serverClientId`/`clientId`, wire it here or via
///      `GoogleSignIn(clientId: ..., serverClientId: ...)`.
/// 4. (Backend) The "Web" OAuth client ID is the audience the accounts service
///    should validate Google `idToken` against — pass it as `serverClientId`
///    so the returned idToken is minted for the backend.
///
/// --- APPLE (sign_in_with_apple) ---
/// 1. Apple Developer account; enable the "Sign in with Apple" capability for
///    the app's App ID.
/// 2. iOS:
///    - Add the "Sign in with Apple" capability in Xcode
///      (`ios/Runner/Runner.entitlements` -> `com.apple.developer.applesignin`).
/// 3. Android / Web (Apple sign-in via web flow — only needed to offer Apple on
///    Android): create a Services ID, a private key, and configure
///    `WebAuthenticationOptions(clientId: '<services id>', redirectUri: ...)`.
///    Pass it to `getAppleIDCredential(webAuthenticationOptions: ...)`.
///    Until then Apple sign-in is iOS/macOS-only (see [signInWithApple]).
///
/// --- ACCOUNTS SERVICE (token exchange — see also auth_repository_impl) ---
/// The provider tokens returned here are NOT an AuraLearn session. Integration
/// must add an accounts-service endpoint (ACCOUNTS_URL, see app_config.dart),
/// e.g. `POST /auth/oauth { provider, idToken|authorizationCode }` -> returns
/// `{ accessToken, refreshToken, user }`. Wire that call in
/// `AuthRepositoryImpl.signInWith*` where the TODO marks the seam.
/// =====================================================================
class OAuthDataSourceImpl implements OAuthDataSource {
  final GoogleSignIn _googleSignIn;

  /// [googleSignIn] is injectable for testing. In production the default
  /// instance picks up `google-services.json` / `GoogleService-Info.plist`.
  /// Pass `serverClientId` (the Web OAuth client ID) here once available so the
  /// `idToken` is minted for the accounts service to verify.
  OAuthDataSourceImpl({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            );

  @override
  Future<OAuthUser> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User dismissed the Google account picker.
        throw const OAuthException('已取消 Google 登录');
      }

      final auth = await account.authentication;

      return OAuthUser(
        id: account.id,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
        provider: OAuthProvider.google,
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
    } on OAuthException {
      rethrow;
    } catch (e) {
      // Missing google-services.json / OAuth client ID, network errors, etc.
      throw OAuthException(kOAuthNotConfiguredMessage, cause: e);
    }
  }

  @override
  Future<OAuthUser> signInWithApple() async {
    try {
      // Guard: Apple sign-in only works where the native flow (iOS/macOS) or a
      // configured web flow is available. `isAvailable()` returns false on
      // unsupported platforms instead of throwing.
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

      // Apple returns name parts only on the FIRST authorization; persist them
      // server-side. Email may be null on subsequent sign-ins.
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((p) => p != null && p.isNotEmpty).join(' ').trim();

      return OAuthUser(
        // `userIdentifier` is the stable Apple subject id (best id we have).
        id: credential.userIdentifier ?? credential.email ?? 'apple_user',
        email: credential.email ?? '',
        name: fullName.isEmpty ? null : fullName,
        photoUrl: null, // Apple never returns a photo.
        provider: OAuthProvider.apple,
        idToken: credential.identityToken,
        authorizationCode: credential.authorizationCode,
      );
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
}
