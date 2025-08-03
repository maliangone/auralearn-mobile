import '../../domain/entities/oauth_user.dart';

abstract class OAuthDataSource {
  Future<OAuthUser> signInWithGoogle();
  Future<OAuthUser> signInWithApple();
}

class OAuthDataSourceImpl implements OAuthDataSource {
  @override
  Future<OAuthUser> signInWithGoogle() async {
    // TODO: Implement actual Google Sign-In using google_sign_in package
    // For now, return a mock user to prevent compilation errors
    throw UnimplementedError('Google Sign-In not yet implemented');
  }

  @override
  Future<OAuthUser> signInWithApple() async {
    // TODO: Implement actual Apple Sign-In using sign_in_with_apple package
    // For now, return a mock user to prevent compilation errors
    throw UnimplementedError('Apple Sign-In not yet implemented');
  }
}