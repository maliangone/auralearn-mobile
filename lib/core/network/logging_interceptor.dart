import 'package:dio/dio.dart';
import '../utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final method = options.method.toUpperCase();
    final uri = options.uri.toString();
    
    AppLogger.info('🌐 $method $uri');
    
    if (options.headers.isNotEmpty) {
      AppLogger.debug('Headers: ${_formatHeaders(options.headers)}');
    }
    
    if (options.data != null) {
      AppLogger.debug('Request Body: ${_formatData(options.data)}');
    }
    
    if (options.queryParameters.isNotEmpty) {
      AppLogger.debug('Query Parameters: ${options.queryParameters}');
    }
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri.toString();
    final statusCode = response.statusCode;
    
    AppLogger.info('✅ $method $uri → $statusCode');
    
    if (response.headers.map.isNotEmpty) {
      AppLogger.debug('Response Headers: ${_formatHeaders(response.headers.map)}');
    }
    
    if (response.data != null) {
      AppLogger.debug('Response Body: ${_formatData(response.data)}');
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final method = err.requestOptions.method.toUpperCase();
    final uri = err.requestOptions.uri.toString();
    final statusCode = err.response?.statusCode;
    
    AppLogger.error('❌ $method $uri → ${statusCode ?? 'NO_RESPONSE'}');
    AppLogger.error('Error Type: ${err.type}');
    AppLogger.error('Error Message: ${err.message}');
    
    if (err.response?.data != null) {
      AppLogger.error('Error Response: ${_formatData(err.response!.data)}');
    }
    
    handler.next(err);
  }

  String _formatHeaders(Map<String, dynamic> headers) {
    final buffer = StringBuffer();
    headers.forEach((key, value) {
      // Don't log sensitive headers
      if (_isSensitiveHeader(key)) {
        buffer.writeln('  $key: [HIDDEN]');
      } else {
        buffer.writeln('  $key: $value');
      }
    });
    return buffer.toString().trim();
  }

  String _formatData(dynamic data) {
    if (data is Map || data is List) {
      return data.toString();
    }
    return data?.toString() ?? 'null';
  }

  bool _isSensitiveHeader(String headerName) {
    final sensitiveHeaders = [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
    ];
    
    return sensitiveHeaders.contains(headerName.toLowerCase());
  }
} 