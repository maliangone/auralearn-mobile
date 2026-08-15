import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/llm/anthropic_tutor_client.dart';
import '../../../../core/llm/model_config.dart';
import '../../../../core/llm/openai_tutor_client.dart';
import '../../../../core/llm/tutor_client.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../l10n/app_localizations.dart';

/// Settings for the answer transport: AuraLearn subscription proxy vs
/// BYOK direct-to-vendor (provider / API key / base URL / model).
///
/// Non-sensitive fields persist on save; the API key goes straight to secure
/// storage (Keychain / EncryptedSharedPreferences) and is never shown back.
class ModelSettingsPage extends StatefulWidget {
  const ModelSettingsPage({super.key});

  @override
  State<ModelSettingsPage> createState() => _ModelSettingsPageState();
}

class _ModelSettingsPageState extends State<ModelSettingsPage> {
  final ModelConfigStore _store = getIt<ModelConfigStore>();

  ModelConfig _config = ModelConfig.defaults;
  String? _savedKey;
  bool _loaded = false;
  bool _testing = false;
  bool _saving = false;

  final TextEditingController _baseUrl = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _reasoningEffort = TextEditingController();
  final TextEditingController _apiKey = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _model.dispose();
    _reasoningEffort.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = await _store.load();
    _savedKey = await _store.getApiKey(config.provider);
    setState(() {
      _config = config;
      _baseUrl.text = config.baseUrl;
      _model.text = config.model;
      _reasoningEffort.text = config.reasoningEffort;
      _loaded = true;
    });
  }

  /// Applies a provider preset, keeping a user-edited key input untouched.
  void _applyPreset(ByokProviderPreset preset) {
    setState(() {
      _config = _config.copyWith(provider: preset.provider);
      _baseUrl.text = preset.defaultBaseUrl;
      _model.text = preset.defaultModel;
      _reasoningEffort.clear();
    });
    // Keys are stored per provider — refresh the "已存储" hint accordingly.
    _store.getApiKey(preset.provider).then((k) {
      if (mounted) setState(() => _savedKey = k);
    });
  }

  ByokProviderPreset _currentPreset() {
    for (final preset in kByokPresets) {
      if (preset.provider == _config.provider &&
          (preset.id == 'custom' || preset.defaultBaseUrl == _baseUrl.text)) {
        return preset;
      }
    }
    return kByokPresets.last; // custom
  }

  Future<void> _save() async {
    final config = _config.copyWith(
      baseUrl: _baseUrl.text.trim(),
      model: _model.text.trim(),
      reasoningEffort: _reasoningEffort.text.trim(),
    );
    final key = _apiKey.text.trim();
    setState(() => _saving = true);
    await _store.save(config);
    if (key.isNotEmpty) {
      await _store.saveApiKey(config.provider, key);
      _apiKey.clear();
      _savedKey = key;
    }
    setState(() {
      _config = config;
      _saving = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).settingsByokSaved)),
    );
  }

  /// One tiny streamed request against the configured endpoint to verify the
  /// key/model combination; completes on the first chunk or an error.
  Future<void> _testConnection() async {
    final l = AppLocalizations.of(context);
    final baseUrl = _baseUrl.text.trim();
    final model = _model.text.trim();
    final key = _apiKey.text.trim().isNotEmpty
        ? _apiKey.text.trim()
        : (await _store.getApiKey(_config.provider) ?? '');

    if (!mounted) return;
    if (baseUrl.isEmpty || model.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.settingsByokMissing)),
      );
      return;
    }

    setState(() => _testing = true);
    String? error;
    try {
      final TutorClient client = switch (_config.provider) {
        ByokProvider.anthropic => AnthropicTutorClient(
            apiKey: key,
            baseUrl: baseUrl,
          ),
        ByokProvider.openaiCompatible => OpenAiTutorClient(
            apiKey: key,
            baseUrl: baseUrl,
          ),
      };
      try {
        final chunks = client.streamTutor(
          model: model,
          system: 'You are a connection test. Reply with OK.',
          userText: 'ping',
          images: const [],
          maxTokens: 8,
          reasoningEffort: _reasoningEffort.text.trim(),
        );
        await chunks.first.timeout(const Duration(seconds: 20));
      } finally {
        if (client is AnthropicTutorClient) client.close();
        if (client is OpenAiTutorClient) client.close();
      }
    } catch (e) {
      error = '$e';
    }
    if (!mounted) return;
    final message =
        error == null ? l.settingsByokTestOk : l.settingsByokTestFailed(error);
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final byok = _config.mode == SolveMode.byok;
    final preset = _currentPreset();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(l.settingsTitle),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
                _SectionLabel(l.settingsModelMode),
                _ModeCard(
                  title: l.settingsModeSubscription,
                  subtitle: l.settingsModeSubscriptionDesc,
                  icon: Icons.cloud_outlined,
                  selected: !byok,
                  onTap: () => setState(() {
                    _config = _config.copyWith(mode: SolveMode.subscription);
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ModeCard(
                  title: l.settingsModeByok,
                  subtitle: l.settingsModeByokDesc,
                  icon: Icons.key_outlined,
                  selected: byok,
                  onTap: () => setState(() {
                    _config = _config.copyWith(mode: SolveMode.byok);
                  }),
                ),
                if (byok) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(l.settingsByokProvider),
                  DropdownButtonFormField<String>(
                    initialValue: preset.id,
                    decoration: _decoration(),
                    items: [
                      for (final p in kByokPresets)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.displayName),
                        ),
                    ],
                    onChanged: (id) {
                      final p = kByokPresets
                          .firstWhere((e) => e.id == id, orElse: () => preset);
                      _applyPreset(p);
                    },
                  ),
                  if (!preset.supportsVision) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.encourageLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l.settingsByokNoVision,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  _SectionLabel(l.settingsByokApiKey),
                  TextField(
                    controller: _apiKey,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration().copyWith(
                      hintText: _savedKey != null && _savedKey!.isNotEmpty
                          ? l.settingsByokApiKeyStored
                          : l.settingsByokApiKeyHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  _SectionLabel(l.settingsByokBaseUrl),
                  TextField(
                    controller: _baseUrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.url,
                    decoration: _decoration(),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  _SectionLabel(l.settingsByokModel),
                  TextField(
                    controller: _model,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration().copyWith(
                      hintText: l.settingsByokModelHint,
                    ),
                  ),
                  if (_config.provider == ByokProvider.openaiCompatible) ...[
                    const SizedBox(height: AppSpacing.base),
                    _SectionLabel(l.settingsByokReasoningEffort),
                    TextField(
                      controller: _reasoningEffort,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: _decoration().copyWith(
                        hintText: 'none / low / medium / high / xhigh / max',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _saving || _testing ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l.settingsByokSave),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _saving || _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering_rounded),
                    label: Text(l.settingsByokTest),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  InputDecoration _decoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.encourageLight : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
