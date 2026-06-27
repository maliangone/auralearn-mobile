import 'package:equatable/equatable.dart';

/// Identity returned by a third-party OAuth provider (Google / Apple).
///
/// This is the *provider* identity, not the AuraLearn account. In the
/// BYOK-proxy model the AuraLearn account JWT is issued by the accounts
/// service (ACCOUNTS_URL) after it verifies one of [idToken] / [accessToken]
/// / [authorizationCode]. See the token-exchange seam documented in
/// `oauth_data_source.dart` and `auth_repository_impl.dart`.
class OAuthUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final OAuthProvider provider;

  /// Provider-issued OIDC ID token (JWT). Google: `idToken`. Apple:
  /// `identityToken`. This is what the accounts service should verify.
  final String? idToken;

  /// Provider-issued OAuth access token (Google only; Apple does not return
  /// one to the client).
  final String? accessToken;

  /// Apple-only single-use authorization code (also usable by the backend to
  /// redeem tokens server-side). Null for Google.
  final String? authorizationCode;

  const OAuthUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.provider,
    this.idToken,
    this.accessToken,
    this.authorizationCode,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        provider,
        idToken,
        accessToken,
        authorizationCode,
      ];
}

enum OAuthProvider {
  google,
  apple,
}
