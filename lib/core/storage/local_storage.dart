import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../utils/logger.dart';

class LocalStorage {
  final SharedPreferences _prefs;
  
  LocalStorage(this._prefs);

  // SharedPreferences methods
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } catch (e) {
      AppLogger.error('Error setting string value for key: $key', e);
      return false;
    }
  }

  String? getString(String key) {
    try {
      return _prefs.getString(key);
    } catch (e) {
      AppLogger.error('Error getting string value for key: $key', e);
      return null;
    }
  }

  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('Error setting bool value for key: $key', e);
      return false;
    }
  }

  bool? getBool(String key) {
    try {
      return _prefs.getBool(key);
    } catch (e) {
      AppLogger.error('Error getting bool value for key: $key', e);
      return null;
    }
  }

  Future<bool> setInt(String key, int value) async {
    try {
      return await _prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('Error setting int value for key: $key', e);
      return false;
    }
  }

  int? getInt(String key) {
    try {
      return _prefs.getInt(key);
    } catch (e) {
      AppLogger.error('Error getting int value for key: $key', e);
      return null;
    }
  }

  Future<bool> setDouble(String key, double value) async {
    try {
      return await _prefs.setDouble(key, value);
    } catch (e) {
      AppLogger.error('Error setting double value for key: $key', e);
      return false;
    }
  }

  double? getDouble(String key) {
    try {
      return _prefs.getDouble(key);
    } catch (e) {
      AppLogger.error('Error getting double value for key: $key', e);
      return null;
    }
  }

  Future<bool> setStringList(String key, List<String> value) async {
    try {
      return await _prefs.setStringList(key, value);
    } catch (e) {
      AppLogger.error('Error setting string list value for key: $key', e);
      return false;
    }
  }

  List<String>? getStringList(String key) {
    try {
      return _prefs.getStringList(key);
    } catch (e) {
      AppLogger.error('Error getting string list value for key: $key', e);
      return null;
    }
  }

  Future<bool> remove(String key) async {
    try {
      return await _prefs.remove(key);
    } catch (e) {
      AppLogger.error('Error removing key: $key', e);
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      return await _prefs.clear();
    } catch (e) {
      AppLogger.error('Error clearing preferences', e);
      return false;
    }
  }

  bool containsKey(String key) {
    try {
      return _prefs.containsKey(key);
    } catch (e) {
      AppLogger.error('Error checking if key exists: $key', e);
      return false;
    }
  }

  Set<String> getKeys() {
    try {
      return _prefs.getKeys();
    } catch (e) {
      AppLogger.error('Error getting all keys', e);
      return <String>{};
    }
  }

  // Hive methods for complex objects
  Future<Box<T>> openBox<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      AppLogger.error('Error opening Hive box: $boxName', e);
      rethrow;
    }
  }

  Future<void> closeBox(String boxName) async {
    try {
      await Hive.close();
    } catch (e) {
      AppLogger.error('Error closing Hive box: $boxName', e);
    }
  }

  // Common storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keySubscriptionPlan = 'subscription_plan';
  static const String keyUsageCount = 'usage_count';
  static const String keyLastResetDate = 'last_reset_date';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
} 