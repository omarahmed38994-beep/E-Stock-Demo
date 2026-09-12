import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

/// Wraps SharedPreferences for the small amount of local state the app
/// needs to persist: the JWT session token, the cached user profile (for
/// instant UI on relaunch), and the dark/light theme preference.
class StorageService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsTokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsTokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsUserKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefsUserKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsTokenKey);
    await prefs.remove(AppConstants.prefsUserKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsThemeKey, mode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefsThemeKey);
  }
}
