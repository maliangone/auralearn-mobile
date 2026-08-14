import '../storage/local_storage.dart';
import '../storage/secure_token_store.dart';

/// Which transport answers questions: the AuraLearn subscription proxy, or a
/// direct connection to a user-supplied LLM vendor endpoint (BYOK).
enum SolveMode {
  /// Route through `POST {proxyBaseUrl}/solve` (server holds the vendor key,
  /// metering + entitlement apply).
  subscription,

  /// Call the vendor API directly from the device with the user's own key.
  byok,
}

/// Provider families the direct client can talk to. OpenAI-compatible covers
/// OpenAI, DeepSeek, and any custom endpoint speaking the chat-completions
/// wire format — the actual target is decided by [ModelConfig.baseUrl].
enum ByokProvider {
  /// Anthropic Messages API (`POST /v1/messages`, `x-api-key`).
  anthropic,

  /// OpenAI-compatible chat completions (`POST /chat/completions`,
  /// `Authorization: Bearer`).
  openaiCompatible,
}

/// One preset provider template shown in the settings UI.
class ByokProviderPreset {
  final String id;
  final String displayName;
  final ByokProvider provider;
  final String defaultBaseUrl;
  final String defaultModel;

  /// True when the vendor's official API supports image input. Text-only
  /// vendors (DeepSeek chat) can still answer text follow-ups but not photos.
  final bool supportsVision;

  const ByokProviderPreset({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.supportsVision,
  });
}

/// Known presets (base URLs documented by the vendors; model IDs are defaults
/// the user may override).
const List<ByokProviderPreset> kByokPresets = [
  ByokProviderPreset(
    id: 'anthropic',
    displayName: 'Anthropic (Claude)',
    provider: ByokProvider.anthropic,
    defaultBaseUrl: 'https://api.anthropic.com',
    defaultModel: 'claude-haiku-4-5-20251001',
    supportsVision: true,
  ),
  ByokProviderPreset(
    id: 'openai',
    displayName: 'OpenAI',
    provider: ByokProvider.openaiCompatible,
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-5.6-luna',
    supportsVision: true,
  ),
  ByokProviderPreset(
    id: 'deepseek',
    displayName: 'DeepSeek',
    provider: ByokProvider.openaiCompatible,
    defaultBaseUrl: 'https://api.deepseek.com',
    defaultModel: 'deepseek-chat',
    supportsVision: false,
  ),
  ByokProviderPreset(
    id: 'custom',
    displayName: 'Custom (OpenAI-compatible)',
    provider: ByokProvider.openaiCompatible,
    defaultBaseUrl: '',
    defaultModel: '',
    supportsVision: true,
  ),
];

/// Persisted BYOK settings. Non-sensitive fields live in SharedPreferences;
/// the API key lives in [SecureTokenStore] (Keychain / EncryptedSharedPreferences).
class ModelConfig {
  final SolveMode mode;
  final ByokProvider provider;
  final String baseUrl;
  final String model;

  /// Reasoning effort forwarded to providers that support it
  /// (OpenAI-compatible `reasoning_effort`). Empty = don't send the field.
  final String reasoningEffort;

  const ModelConfig({
    this.mode = SolveMode.subscription,
    this.provider = ByokProvider.openaiCompatible,
    this.baseUrl = '',
    this.model = '',
    this.reasoningEffort = '',
  });

  static const ModelConfig defaults = ModelConfig();

  ModelConfig copyWith({
    SolveMode? mode,
    ByokProvider? provider,
    String? baseUrl,
    String? model,
    String? reasoningEffort,
  }) {
    return ModelConfig(
      mode: mode ?? this.mode,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
    );
  }
}

/// Reads/writes [ModelConfig] (SharedPreferences) and the BYOK API key
/// (secure storage). Keys are kept separate from [LocalStorage]'s own key
/// constants so the LLM config can be cleared independently.
class ModelConfigStore {
  static const String _kMode = 'llm_solve_mode';
  static const String _kProvider = 'llm_byok_provider';
  static const String _kBaseUrl = 'llm_byok_base_url';
  static const String _kModel = 'llm_byok_model';
  static const String _kReasoningEffort = 'llm_byok_reasoning_effort';

  final LocalStorage _storage;
  final SecureTokenStore _secure;

  ModelConfigStore(this._storage, this._secure);

  /// Key names in secure storage, per provider.
  static String secureKeyFor(ByokProvider provider) =>
      'byok_key_${provider.name}';

  Future<ModelConfig> load() async {
    final modeName = _storage.getString(_kMode);
    final providerName = _storage.getString(_kProvider);
    return ModelConfig(
      mode: modeName == SolveMode.byok.name
          ? SolveMode.byok
          : SolveMode.subscription,
      provider: ByokProvider.values.asNameMap()[providerName] ??
          ByokProvider.openaiCompatible,
      baseUrl: _storage.getString(_kBaseUrl) ?? '',
      model: _storage.getString(_kModel) ?? '',
      reasoningEffort: _storage.getString(_kReasoningEffort) ?? '',
    );
  }

  Future<void> save(ModelConfig config) async {
    await _storage.setString(_kMode, config.mode.name);
    await _storage.setString(_kProvider, config.provider.name);
    await _storage.setString(_kBaseUrl, config.baseUrl);
    await _storage.setString(_kModel, config.model);
    await _storage.setString(_kReasoningEffort, config.reasoningEffort);
  }

  Future<String?> getApiKey(ByokProvider provider) =>
      _secure.getByokKey(provider.name);

  Future<void> saveApiKey(ByokProvider provider, String key) =>
      _secure.saveByokKey(provider.name, key);

  Future<void> deleteApiKey(ByokProvider provider) =>
      _secure.deleteByokKey(provider.name);
}
