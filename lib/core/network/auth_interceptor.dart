import 'package:dio/dio.dart';
import '../storage/secure_token_store.dart';
import '../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  final SecureTokenStore _tokenStore;

  AuthInterceptor(this._tokenStore);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login/register endpoints
    if (_shouldSkipAuth(options.path)) {
      return handler.next(options);
    }

    // Add bearer token if available
    final token = await _tokenStore.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    AppLogger.debug('Request: ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.debug('Response: ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    AppLogger.error('API Error: ${err.message}', err);

    // Handle 401 Unauthorized - token might be expired
    if (err.response?.statusCode == 401) {
      _handleUnauthorized();
    }

    handler.next(err);
  }

  bool _shouldSkipAuth(String path) {
    final skipPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
    ];

    return skipPaths.any((skipPath) => path.contains(skipPath));
  }

  void _handleUnauthorized() {
    // Clear stored sensitive tokens from secure storage.
    _tokenStore.clear();

    AppLogger.warning('User session expired - tokens cleared');

    // TODO: Navigate to login screen or trigger auth event
    // This would typically be handled by the auth bloc
  }
}
