import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tutor_client.dart';

/// OpenAI-compatible chat completions client
/// (`POST {baseUrl}/chat/completions`, streaming).
///
/// Covers OpenAI, DeepSeek, and any custom endpoint speaking the chat
/// completions wire format. Images are `image_url` content parts with a
/// `data:image/jpeg;base64,...` data URL (vendors without vision will reject
/// the request — the caller should pre-check capability).
///
/// [reasoningEffort], when non-empty, is sent as the `reasoning_effort`
/// request field; providers that do not know it reject the request, so the
/// settings UI only offers it where supported.
class OpenAiTutorClient implements TutorClient {
  final String apiKey;
  final String baseUrl;
  final http.Client _client;

  OpenAiTutorClient({
    required this.apiKey,
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Stream<String> streamTutor({
    required String model,
    required String system,
    required String userText,
    required List<Uint8List> images,
    required int maxTokens,
    String reasoningEffort = '',
  }) async* {
    final base =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final uri = Uri.parse('$base/chat/completions');

    final userContent = <Map<String, dynamic>>[
      for (final image in images)
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(image)}',
          },
        },
      {'type': 'text', 'text': userText},
    ];

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'stream': true,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': userContent},
      ],
      if (reasoningEffort.isNotEmpty) 'reasoning_effort': reasoningEffort,
    };

    final request = http.Request('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode(body);

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      throw TutorClientException('Network error: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyText = await response.stream.bytesToString();
      throw TutorClientException(
        _friendlyError(response.statusCode, bodyText),
        statusCode: response.statusCode,
        isAuthError: response.statusCode == 401 || response.statusCode == 403,
      );
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring('data:'.length).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(payload) as Map<String, dynamic>;
      } on FormatException {
        continue; // skip malformed frames rather than aborting the stream
      }

      // Streamed error frame (some providers emit one inside the SSE body).
      final err = json['error'];
      if (err != null) {
        final message = err is Map<String, dynamic>
            ? (err['message'] as String?) ?? 'unknown'
            : '$err';
        throw TutorClientException('Upstream stream error: $message');
      }

      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) continue;
      final delta = (choices.first as Map<String, dynamic>)['delta'];
      if (delta is! Map<String, dynamic>) continue;
      final text = delta['content'];
      if (text is String && text.isNotEmpty) yield text;
    }
  }

  /// Maps status codes to actionable messages without echoing the key.
  String _friendlyError(int status, String body) {
    String detail = '';
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final err = json['error'];
      if (err is Map<String, dynamic>) {
        detail = (err['message'] as String?) ?? '';
      }
    } on FormatException {
      // not JSON — leave detail empty
    }
    if (status == 401 || status == 403) {
      return 'Authentication failed — check your API key. $detail'.trim();
    }
    if (status == 404) {
      return 'Endpoint or model not found — check the base URL and model name. '
          '$detail'.trim();
    }
    return 'API error $status: $detail';
  }

  /// Releases the underlying HTTP client. Call when the owner is disposed.
  void close() => _client.close();
}
