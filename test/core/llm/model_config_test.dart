import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auralearn/core/llm/model_config.dart';
import 'package:auralearn/core/storage/local_storage.dart';
import 'package:auralearn/core/storage/secure_token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ModelConfigStore store;
  late SecureTokenStore secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    secure = SecureTokenStore(const FlutterSecureStorage());
    store = ModelConfigStore(
      LocalStorage(await SharedPreferences.getInstance()),
      secure,
    );
  });

  test('defaults: subscription mode, no byok fields', () async {
    final config = await store.load();
    expect(config.mode, SolveMode.subscription);
    expect(config.baseUrl, isEmpty);
    expect(config.model, isEmpty);
  });

  test('save/load round-trip preserves all byok fields', () async {
    await store.save(const ModelConfig(
      mode: SolveMode.byok,
      provider: ByokProvider.anthropic,
      baseUrl: 'https://api.anthropic.com',
      model: 'claude-haiku-4-5-20251001',
      reasoningEffort: 'high',
    ));

    final loaded = await store.load();
    expect(loaded.mode, SolveMode.byok);
    expect(loaded.provider, ByokProvider.anthropic);
    expect(loaded.baseUrl, 'https://api.anthropic.com');
    expect(loaded.model, 'claude-haiku-4-5-20251001');
    expect(loaded.reasoningEffort, 'high');
  });

  test('unknown persisted provider falls back to openaiCompatible', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_byok_provider', 'does_not_exist');
    final config = await store.load();
    expect(config.provider, ByokProvider.openaiCompatible);
  });

  test('api key round-trips through secure storage, not SharedPreferences',
      () async {
    await store.saveApiKey(ByokProvider.openaiCompatible, 'sk-secret-123');

    expect(await store.getApiKey(ByokProvider.openaiCompatible),
        'sk-secret-123');
    expect(await store.getApiKey(ByokProvider.anthropic), isNull,
        reason: 'keys are namespaced per provider family');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('byok_key_openaiCompatible'), isNull,
        reason: 'the key must never land in plaintext SharedPreferences');

    await store.deleteApiKey(ByokProvider.openaiCompatible);
    expect(await store.getApiKey(ByokProvider.openaiCompatible), isNull);
  });

  test('secureKeyFor matches SecureTokenStore.byokKey naming', () {
    expect(ModelConfigStore.secureKeyFor(ByokProvider.anthropic),
        SecureTokenStore.byokKey('anthropic'));
    expect(ModelConfigStore.secureKeyFor(ByokProvider.openaiCompatible),
        SecureTokenStore.byokKey('openaiCompatible'));
  });
}
