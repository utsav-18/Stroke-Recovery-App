import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultCloudUrl = 'https://stroke-recovery-app.onrender.com';
  static const String defaultLocalUrl = 'http://192.168.1.3:8000';

  static const String _envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultCloudUrl,
  );

  static String _currentBaseUrl = _envUrl;

  static String get apiBaseUrl => _currentBaseUrl;

  static const String _prefKey = 'saved_api_base_url';

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _currentBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String url) async {
    _currentBaseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _currentBaseUrl);
    } catch (_) {}
  }

  static const bool useMockData = true;

  static String get backendDisplayName =>
      apiBaseUrl.startsWith('http') ? apiBaseUrl : 'https://$apiBaseUrl';
}
