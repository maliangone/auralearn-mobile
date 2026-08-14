import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/local_storage.dart';

/// Holds the app's selected [Locale]. `null` means "follow the system locale".
///
/// The choice is persisted in [LocalStorage] under
/// [LocalStorage.keyLanguageCode] (`'zh'` / `'en'`, or empty for system) so it
/// survives restarts. The app is local-first; this is a device-level setting.
class LocaleCubit extends Cubit<Locale?> {
  final LocalStorage _storage;

  LocaleCubit(this._storage) : super(_loadInitial(_storage));

  /// Locales the app ships translations for (matches `lib/l10n/*.arb`).
  static const List<Locale> supported = [Locale('zh'), Locale('en')];

  static Locale? _loadInitial(LocalStorage storage) {
    final code = storage.getString(LocalStorage.keyLanguageCode);
    if (code == null || code.isEmpty) return null; // follow system
    return Locale(code);
  }

  /// Sets the locale (`null` = follow system) and persists the choice.
  Future<void> setLocale(Locale? locale) async {
    await _storage.setString(
      LocalStorage.keyLanguageCode,
      locale?.languageCode ?? '',
    );
    emit(locale);
  }
}
