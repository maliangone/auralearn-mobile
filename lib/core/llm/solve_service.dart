import 'dart:typed_data';

import '../network/streaming/solve_client.dart';
import '../network/streaming/solve_event.dart';
import '../storage/secure_token_store.dart';
import '../utils/logger.dart';
import 'anthropic_tutor_client.dart';
import 'model_config.dart';
import 'openai_tutor_client.dart';
import 'solve_stream_parser.dart';
import 'tutor_client.dart';
import 'tutor_prompt.dart';

/// One question through whichever transport is active (subscription proxy or
/// BYOK direct). Emits the shared [SolveEvent] contract so callers (Bloc,
/// document chat) are transport-agnostic.
abstract class SolveService {
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String? text,
    String? context,
  });

  /// True when the active transport can handle photos. Text-only BYOK
  /// vendors (DeepSeek chat) answer [text] follow-ups but not images.
  Future<bool> supportsVision();

  /// Quick check that the configured transport is usable (key present /
  /// token present). Does not call the network.
  Future<String?> usabilityError();

  /// Releases transport resources. Call when the owner is disposed.
  void close() {}
}

/// Routes through the AuraLearn subscription proxy (`/solve` SSE).
class ProxySolveService implements SolveService {
  final SolveClient _client;
  final SecureTokenStore _tokenStore;

  ProxySolveService(this._client, this._tokenStore);

  @override
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String? text,
    String? context,
  }) async* {
    // The real account JWT once Phase 3 (Firebase Auth) lands; until then the
    // stored access token is the closest available credential.
    final token = await _tokenStore.getAccessToken() ?? 'dev-placeholder-token';
    yield* _client.solve(
      images: images,
      subject: subject,
      plan: 'free',
      token: token,
      context: context,
      text: text,
    );
  }

  @override
  Future<bool> supportsVision() async => true;

  @override
  Future<String?> usabilityError() async => null;

  @override
  void close() => _client.close();
}

/// Calls the vendor API directly with the user's own key (BYOK).
class DirectSolveService implements SolveService {
  final ModelConfigStore _configStore;

  /// Builds the right [TutorClient] for a [ModelConfig] + API key.
  final TutorClient Function(ModelConfig config, String apiKey) _clientFactory;

  static const int _maxTokens = 2048;

  DirectSolveService(this._configStore, {TutorClient Function(ModelConfig config, String apiKey)? clientFactory})
      : _clientFactory = clientFactory ?? _defaultClientFactory;

  static TutorClient _defaultClientFactory(ModelConfig config, String apiKey) {
    switch (config.provider) {
      case ByokProvider.anthropic:
        return AnthropicTutorClient(apiKey: apiKey, baseUrl: config.baseUrl);
      case ByokProvider.openaiCompatible:
        return OpenAiTutorClient(apiKey: apiKey, baseUrl: config.baseUrl);
    }
  }

  @override
  void close() {
    // Per-call clients are closed in solve()'s finally; nothing to release.
  }

  /// True when the configured provider preset advertises vision. The custom
  /// preset (or a user-edited base URL) assumes yes — the user's
  /// responsibility, and the vendor will reject images if unsupported.
  @override
  Future<bool> supportsVision() async {
    final config = await _configStore.load();
    for (final preset in kByokPresets) {
      if (preset.provider == config.provider &&
          (preset.id == 'custom' || preset.defaultBaseUrl == config.baseUrl)) {
        return preset.supportsVision;
      }
    }
    return true; // unknown endpoint — assume vision
  }

  @override
  Future<String?> usabilityError() async {
    final config = await _configStore.load();
    if (config.baseUrl.trim().isEmpty || config.model.trim().isEmpty) {
      return 'BYOK provider not configured (base URL / model missing).';
    }
    final key = await _configStore.getApiKey(config.provider);
    if (key == null || key.trim().isEmpty) {
      return 'No API key saved for the selected provider.';
    }
    return null;
  }

  @override
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String? text,
    String? context,
  }) async* {
    final config = await _configStore.load();

    // Cap + fence doc context exactly like the proxy does.
    var safeContext = context ?? '';
    var truncated = false;
    if (safeContext.length > kMaxContextChars) {
      truncated = true;
      safeContext = safeContext.substring(0, kMaxContextChars);
    }

    var userText = buildUserFraming(subject);
    if (safeContext.isNotEmpty) {
      userText += '\n\n${buildContextBlock(safeContext, truncated: truncated)}';
    }
    if (text != null && text.isNotEmpty) {
      userText += '\n\nFollow-up: $text';
    }

    final key = await _configStore.getApiKey(config.provider);
    if (key == null || key.trim().isEmpty) {
      yield const SolveError(
          'byok_no_key', 'No API key saved for the selected provider.');
      return;
    }

    final client = _clientFactory(config, key);
    final parser = SolveStreamParser();
    try {
      final chunks = client.streamTutor(
        model: config.model,
        system: kTutorSystemPrompt,
        userText: userText,
        images: images,
        maxTokens: _maxTokens,
        reasoningEffort: config.reasoningEffort,
      );
      // run() drives chunks -> parser -> SolveEvents and closes the stream;
      // errors (auth / upstream) arrive as terminal SolveError events.
      final runFuture = parser.run(chunks);
      yield* parser.events;
      await runFuture;
    } on TutorClientException catch (e) {
      AppLogger.error('BYOK solve failed: ${e.message}');
      yield SolveError(
        e.isAuthError ? 'byok_auth_error' : 'byok_upstream_error',
        e.message,
      );
    } catch (e) {
      AppLogger.error('BYOK solve failed: $e');
      yield SolveError('byok_upstream_error', 'Direct solve failed: $e');
    } finally {
      if (client is AnthropicTutorClient) client.close();
      if (client is OpenAiTutorClient) client.close();
    }
  }
}

/// Chooses the active [SolveService] from the persisted [ModelConfig] each
/// call, so a settings change takes effect on the next question.
class SolveServiceFactory implements SolveService {
  final ModelConfigStore _configStore;
  final ProxySolveService _proxy;
  final DirectSolveService _direct;

  SolveServiceFactory(this._configStore, this._proxy, this._direct);

  Future<SolveService> _active() async {
    final config = await _configStore.load();
    return config.mode == SolveMode.byok ? _direct : _proxy;
  }

  @override
  Stream<SolveEvent> solve({
    required List<Uint8List> images,
    String? subject,
    String? text,
    String? context,
  }) async* {
    final active = await _active();
    yield* active.solve(
      images: images,
      subject: subject,
      text: text,
      context: context,
    );
  }

  @override
  Future<bool> supportsVision() async {
    final active = await _active();
    return active.supportsVision();
  }

  @override
  Future<String?> usabilityError() async {
    final active = await _active();
    return active.usabilityError();
  }

  @override
  void close() => _proxy.close();
}
