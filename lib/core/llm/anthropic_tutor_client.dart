import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'tutor_client.dart';

/// Anthropic Messages API client (`POST {baseUrl}/v1/messages`, streaming).
///
/// Wire contract: `x-api-key` + `anthropic-version: 2023-06-01` headers,
/// `stream: true`, base64 JPEG image blocks. SSE frames are `data:` JSON
/// lines; text deltas arrive as `content_block_delta` with
/// `delta.type == "text_delta"`.
class AnthropicTutorClient implements TutorClient {
  static const String anthropicVersion = '2023-06-01';

  final String apiKey;
  final String baseUrl;
  final http.Client _client;

  AnthropicTutorClient({
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
    final uri = Uri.parse(
      '${baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl}'
      '/v1/messages',
    );

    final content = <Map<String, dynamic>>[
      for (final image in images)
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': 'image/jpeg',
            'data': base64Encode(image),
          },
        },
      {'type': 'text', 'text': userText},
    ];

    final request = http.Request('POST', uri)
      ..headers['x-api-key'] = apiKey
      ..headers['anthropic-version'] = anthropicVersion
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'stream': true,
        'system': system,
        'messages': [
          {'role': 'user', 'content': content},
        ],
      });

    final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } catch (e) {
      throw TutorClientException('Network error: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw TutorClientException(
        _friendlyError(response.statusCode, body),
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

      final type = json['type'];
      switch (type) {
        case 'content_block_delta':
          final delta = json['delta'];
          if (delta is Map<String, dynamic> && delta['type'] == 'text_delta') {
            final text = delta['text'];
            if (text is String && text.isNotEmpty) yield text;
          }
        case 'error':
          throw TutorClientException(
            'Anthropic stream error: ${json['error'] ?? json}',
          );
        case 'message_stop':
          return; // clean end of stream
      }
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
      return 'Authentication failed — check your Anthropic API key. $detail'
          .trim();
    }
    if (status == 404) {
      return 'Model "$detail" not found — check the model name.';
    }
    return 'Anthropic API error $status: $detail';
  }

  /// Releases the underlying HTTP client. Call when the owner is disposed.
  void close() => _client.close();
}
