import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/app_exceptions.dart';

/// Abstract interface for local storage operations
abstract class StorageService {
  /// Get a string value from storage
  Future<String?> getString(String key);

  /// Set a string value in storage
  Future<void> setString(String key, String value);

  /// Get an int value from storage
  Future<int?> getInt(String key);

  /// Set an int value in storage
  Future<void> setInt(String key, int value);

  /// Get a bool value from storage
  Future<bool?> getBool(String key);

  /// Set a bool value in storage
  Future<void> setBool(String key, bool value);

  /// Get a DateTime from storage (stored as ISO8601 string)
  Future<DateTime?> getDateTime(String key);

  /// Set a DateTime in storage (stored as ISO8601 string)
  Future<void> setDateTime(String key, DateTime value);

  /// Remove a value from storage
  Future<void> remove(String key);

  /// Clear all storage
  Future<void> clear();

  /// Check if a key exists in storage
  Future<bool> containsKey(String key);
}

/// SharedPreferences implementation of StorageService
class SharedPreferencesStorageService implements StorageService {
  SharedPreferencesStorageService._();

  static SharedPreferencesStorageService? _instance;
  static SharedPreferences? _prefs;

  /// Get singleton instance
  static Future<SharedPreferencesStorageService> getInstance() async {
    if (_instance == null) {
      _instance = SharedPreferencesStorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      throw StorageException('Failed to get string for key: $key');
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      final bool result = await _prefs?.setString(key, value) ?? false;
      if (!result) {
        throw StorageException.saveFailed(key);
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to set string for key: $key');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return _prefs?.getInt(key);
    } catch (e) {
      throw StorageException('Failed to get int for key: $key');
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      final bool result = await _prefs?.setInt(key, value) ?? false;
      if (!result) {
        throw StorageException.saveFailed(key);
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to set int for key: $key');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return _prefs?.getBool(key);
    } catch (e) {
      throw StorageException('Failed to get bool for key: $key');
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      final bool result = await _prefs?.setBool(key, value) ?? false;
      if (!result) {
        throw StorageException.saveFailed(key);
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to set bool for key: $key');
    }
  }

  @override
  Future<DateTime?> getDateTime(String key) async {
    try {
      final String? timestamp = _prefs?.getString(key);
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp);
    } catch (e) {
      throw StorageException('Failed to get DateTime for key: $key');
    }
  }

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    try {
      final String timestamp = value.toUtc().toIso8601String();
      final bool result = await _prefs?.setString(key, timestamp) ?? false;
      if (!result) {
        throw StorageException.saveFailed(key);
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to set DateTime for key: $key');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _prefs?.remove(key);
    } catch (e) {
      throw StorageException('Failed to remove key: $key');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      throw StorageException('Failed to clear storage');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return _prefs?.containsKey(key) ?? false;
    } catch (e) {
      throw StorageException('Failed to check key: $key');
    }
  }
}

