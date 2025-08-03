import 'package:equatable/equatable.dart';

class OAuthUser extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final OAuthProvider provider;

  const OAuthUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.provider,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl, provider];
}

enum OAuthProvider {
  google,
  apple,
}
