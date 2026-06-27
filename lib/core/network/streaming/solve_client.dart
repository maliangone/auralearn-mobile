import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'image_encode.dart';
import 'solve_event.dart';

/// SSE streaming client for the proxy `/solve` endpoint.
///
/// Uses `package:http` streamed requests (instead of dio, which is frozen at
/// ^4 and unsuitable for SSE) to consume a `text/event-stream` response and
/// surface decoded [SolveEvent]s as they arrive.
///
/// Contract: `POST {AppConfig.proxyBaseUrl}/solve`, header
/// `Authorization: Bearer <token>`, JSON body
/// `{ images: [base64 jpeg], subject?, plan: "free"|"paid", context? }`.
///
/// [context] is optional reference material (Phase C document-import
/// context-stuffing): when supplied it is sent verbatim as the `context`
/// field so the model can answer a question over an imported document. No
/// RAG / vector store is involved; the caller is responsible for any size cap.
class SolveClient {
  final http.Client _client;

  /// [client] is injectable for testing; defaults to a fresh [http.Client].
  SolveClient({http.Client? client}) : _client = client ?? http.Client();

  /// Streams solve events for [images] under [token] auth.
  ///
  /// Images are downscaled + JPEG + base64-encoded (max 3) per contract.
  /// A mid-stream close (network drop / server hang-up) closes the stream
  /// without an extra synthetic event — the BLoC owns resume/restart policy.
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String plan = 'free',
    required String token,
    String? context,
  }) async* {
    final uri = Uri.parse('${AppConfig.proxyBaseUrl}/solve');

    final body = <String, dynamic>{
      'images': SolveImageEncoder.encodeAll(images),
      if (subject != null && subject.isNotEmpty) 'subject': subject,
      'plan': plan,
      if (context != null) 'context': context,
    };

    final request = http.Request('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(body);

    final http.StreamedResponse response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      yield SolveError(
        'http_${response.statusCode}',
        'Solve request failed with status ${response.statusCode}',
      );
      return;
    }

    // SSE frames are newline-delimited; `data:` lines carry the JSON payload.
    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (!trimmed.startsWith('data:')) continue;

      final payload = trimmed.substring('data:'.length).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        // Skip malformed frames rather than aborting the whole stream.
        continue;
      }

      yield SolveEvent.fromJson(json);
    }
    // Stream exhausted (clean end or mid-stream close): emit nothing extra.
  }

  /// Releases the underlying HTTP client. Call when the owner is disposed.
  void close() => _client.close();
}
