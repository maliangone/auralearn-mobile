import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:auralearn/core/llm/anthropic_tutor_client.dart';
import 'package:auralearn/core/llm/openai_tutor_client.dart';
import 'package:auralearn/core/llm/tutor_client.dart';

/// A BaseClient returning canned streamed (SSE) responses — MockClient only
/// models `Future<Response>`, while these clients need `StreamedResponse`.
class _FakeSseClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest) _handler;
  _FakeSseClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

/// Records the request and returns a canned SSE response.
_FakeSseClient _mock({
  required void Function(http.BaseRequest) inspect,
  required List<String> sseLines,
  int status = 200,
}) {
  return _FakeSseClient((request) async {
    inspect(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode('${sseLines.join('\n')}\n')),
      status,
      headers: {'content-type': 'text/event-stream'},
    );
  });
}

const _params = (
  model: 'test-model',
  system: 'You are a tutor.',
  userText: 'Solve this.',
  images: <Uint8List>[],
  maxTokens: 10,
);

void main() {
  group('AnthropicTutorClient', () {
    test('posts to /v1/messages with x-api-key + version headers', () async {
      late http.Request captured;
      final client = AnthropicTutorClient(
        apiKey: 'sk-test',
        baseUrl: 'https://api.anthropic.com',
        client: _mock(
          inspect: (r) => captured = r as http.Request,
          sseLines: [
            'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello"}}',
            'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":" world"}}',
            'data: {"type":"message_stop"}',
          ],
        ),
      );

      final chunks = await client
          .streamTutor(
            model: _params.model,
            system: _params.system,
            userText: _params.userText,
            images: _params.images,
            maxTokens: _params.maxTokens,
          )
          .toList();

      expect(chunks, ['Hello', ' world']);
      expect(captured.url.toString(),
          'https://api.anthropic.com/v1/messages');
      expect(captured.headers['x-api-key'], 'sk-test');
      expect(captured.headers['anthropic-version'],
          AnthropicTutorClient.anthropicVersion);
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['stream'], true);
      expect(body['system'], 'You are a tutor.');
      expect((body['messages'] as List).first['role'], 'user');
    });

    test('401 -> TutorClientException with isAuthError', () async {
      final client = AnthropicTutorClient(
        apiKey: 'bad',
        baseUrl: 'https://api.anthropic.com',
        client: _mock(
          inspect: (_) {},
          sseLines: [],
          status: 401,
        ),
      );

      await expectLater(
        client.streamTutor(
          model: _params.model,
          system: _params.system,
          userText: _params.userText,
          images: _params.images,
          maxTokens: _params.maxTokens,
        ).toList(),
        throwsA(isA<TutorClientException>()
            .having((e) => e.isAuthError, 'isAuthError', true)
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('streamed error event throws mid-stream', () async {
      final client = AnthropicTutorClient(
        apiKey: 'sk-test',
        baseUrl: 'https://api.anthropic.com',
        client: _mock(
          inspect: (_) {},
          sseLines: [
            'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"partial"}}',
            'data: {"type":"error","error":{"message":"overloaded"}}',
          ],
        ),
      );

      await expectLater(
        client.streamTutor(
          model: _params.model,
          system: _params.system,
          userText: _params.userText,
          images: _params.images,
          maxTokens: _params.maxTokens,
        ).toList(),
        throwsA(isA<TutorClientException>()),
      );
    });
  });

  group('OpenAiTutorClient', () {
    test('posts to {baseUrl}/chat/completions and parses delta content',
        () async {
      late http.Request captured;
      final client = OpenAiTutorClient(
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1/',
        client: _mock(
          inspect: (r) => captured = r as http.Request,
          sseLines: [
            'data: {"choices":[{"delta":{"content":"Hello"}}]}',
            'data: {"choices":[{"delta":{"content":"!"}}]}',
            'data: [DONE]',
          ],
        ),
      );

      final chunks = await client
          .streamTutor(
            model: _params.model,
            system: _params.system,
            userText: _params.userText,
            images: _params.images,
            maxTokens: _params.maxTokens,
          )
          .toList();

      expect(chunks, ['Hello', '!']);
      // Trailing slash must not produce a double slash.
      expect(captured.url.toString(),
          'https://api.openai.com/v1/chat/completions');
      expect(captured.headers['Authorization'], 'Bearer sk-test');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'test-model');
      expect(body['stream'], true);
      expect(body.containsKey('reasoning_effort'), false,
          reason: 'empty reasoning effort must omit the field');
      expect((body['messages'] as List).first['role'], 'system');
    });

    test('images become data-URL image_url parts; reasoning_effort passed '
        'through when set', () async {
      late http.Request captured;
      final client = OpenAiTutorClient(
        apiKey: 'sk-test',
        baseUrl: 'https://api.deepseek.com',
        client: _mock(
          inspect: (r) => captured = r as http.Request,
          sseLines: ['data: [DONE]'],
        ),
      );

      await client
          .streamTutor(
            model: 'deepseek-chat',
            system: _params.system,
            userText: _params.userText,
            images: [Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9])],
            maxTokens: _params.maxTokens,
            reasoningEffort: 'high',
          )
          .toList();

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['reasoning_effort'], 'high');
      final userMsg = (body['messages'] as List).last as Map<String, dynamic>;
      final parts = userMsg['content'] as List;
      expect(parts, hasLength(2));
      final imagePart = parts.first as Map<String, dynamic>;
      expect(imagePart['type'], 'image_url');
      final url =
          (imagePart['image_url'] as Map<String, dynamic>)['url'] as String;
      expect(url, startsWith('data:image/jpeg;base64,/9j/'));
    });

    test('401 -> TutorClientException with isAuthError', () async {
      final client = OpenAiTutorClient(
        apiKey: 'bad',
        baseUrl: 'https://api.openai.com/v1',
        client: _mock(inspect: (_) {}, sseLines: [], status: 401),
      );

      await expectLater(
        client.streamTutor(
          model: _params.model,
          system: _params.system,
          userText: _params.userText,
          images: _params.images,
          maxTokens: _params.maxTokens,
        ).toList(),
        throwsA(isA<TutorClientException>()
            .having((e) => e.isAuthError, 'isAuthError', true)),
      );
    });
  });
}
