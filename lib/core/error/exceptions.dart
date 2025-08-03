class ServerException implements Exception {
  final String message;
  final int? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() =>
      'ServerException: $message ${code != null ? '(Code: $code)' : ''}';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  final int? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() =>
      'AuthException: $message ${code != null ? '(Code: $code)' : ''}';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}
