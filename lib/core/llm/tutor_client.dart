import 'dart:typed_data';

/// Direct-to-vendor streaming abstraction (BYOK mode).
///
/// Mirrors the proxy's `TutorModel` interface (proxy/src/lib/anthropic.ts):
/// the service builds one user turn, the client streams raw text deltas back.
/// Implementations talk the vendor wire format and decode its SSE/streaming
/// response; the caller owns prompting, parsing into steps, and event
/// assembly.
abstract class TutorClient {
  /// Streams raw text chunks for one tutor turn.
  ///
  /// [images] are already downscaled + JPEG + base64-encoded (see
  /// `SolveImageEncoder`). [reasoningEffort] is forwarded only when the
  /// vendor supports it and the value is non-empty.
  Stream<String> streamTutor({
    required String model,
    required String system,
    required String userText,
    required List<Uint8List> images,
    required int maxTokens,
    String reasoningEffort = '',
  });
}

/// Thrown when a direct vendor call fails before or during streaming, e.g.
/// bad key (401), bad model name (404), or a network failure. [isAuthError]
/// lets the UI hint that the key is probably wrong.
class TutorClientException implements Exception {
  final String message;
  final int? statusCode;
  final bool isAuthError;

  const TutorClientException(
    this.message, {
    this.statusCode,
    this.isAuthError = false,
  });

  @override
  String toString() => message;
}
