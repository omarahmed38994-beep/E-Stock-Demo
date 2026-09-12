/// Central app constants. Keeping the API base URL here (rather than
/// scattered through the codebase) makes it a single edit to point the
/// app at a different backend (e.g. a real device on the LAN instead of
/// an emulator's localhost alias).
class AppConstants {
  AppConstants._();

  static const String appName = 'StockVision';
  static const String tagline = 'Your Business. One View. Smarter Decisions.';

  /// Android emulator maps 10.0.2.2 to the host machine's localhost.
  /// iOS simulator and desktop can use 127.0.0.1 directly.
  /// For a physical device, replace with your computer's LAN IP, e.g.
  /// 'http://192.168.1.20:8000'.
  static const String apiBaseUrlAndroidEmulator = 'http://10.0.2.2:8000';
  static const String apiBaseUrlDefault = 'http://127.0.0.1:8000';

  static const String prefsTokenKey = 'sv_access_token';
  static const String prefsUserKey = 'sv_user';
  static const String prefsThemeKey = 'sv_theme_mode';
}
