import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// SharedPreferences Service Provider & Wrapper
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be initialized in main()');
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  SharedPreferences get prefs => _prefs;

  // Theme Persistence
  String getThemeMode() {
    return _prefs.getString(AppConstants.prefKeyThemeMode) ?? 'light';
  }

  Future<bool> setThemeMode(String themeMode) async {
    return await _prefs.setString(AppConstants.prefKeyThemeMode, themeMode);
  }

  // Language Preference Persistence
  String getLanguage() {
    return _prefs.getString(AppConstants.prefKeyLanguage) ?? 'English';
  }

  Future<bool> setLanguage(String lang) async {
    return await _prefs.setString(AppConstants.prefKeyLanguage, lang);
  }

  // User Role Persistence ('customer' or 'rider')
  String getUserRole() {
    return _prefs.getString(AppConstants.prefKeyUserRole) ?? 'customer';
  }

  Future<bool> setUserRole(String role) async {
    return await _prefs.setString(AppConstants.prefKeyUserRole, role);
  }

  // Persistent Login State
  bool isLoggedIn() {
    return _prefs.getBool(AppConstants.prefKeyIsLoggedIn) ?? false;
  }

  bool isAuthenticated() => isLoggedIn();

  Future<bool> setLoggedIn(bool value) async {
    return await _prefs.setBool(AppConstants.prefKeyIsLoggedIn, value);
  }

  Future<bool> setAuthenticated(bool value) => setLoggedIn(value);

  // Notification Preference Persistence
  bool getNotificationsEnabled() {
    return _prefs.getBool(AppConstants.prefKeyNotificationsEnabled) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool value) async {
    return await _prefs.setBool(
        AppConstants.prefKeyNotificationsEnabled, value);
  }

  // Clear Preferences on Logout
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
