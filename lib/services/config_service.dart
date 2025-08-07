import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _huggingFaceApiKeyKey = 'huggingface_api_key';
  static const String _isDarkModeKey = 'is_dark_mode';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // API Keys
  static Future<void> setGeminiApiKey(String apiKey) async {
    await _prefs!.setString(_geminiApiKeyKey, apiKey);
  }

  static String? getGeminiApiKey() {
    return _prefs!.getString(_geminiApiKeyKey);
  }

  static Future<void> setHuggingFaceApiKey(String apiKey) async {
    await _prefs!.setString(_huggingFaceApiKeyKey, apiKey);
  }

  static String? getHuggingFaceApiKey() {
    return _prefs!.getString(_huggingFaceApiKeyKey);
  }

  // Theme settings
  static Future<void> setDarkMode(bool isDarkMode) async {
    await _prefs!.setBool(_isDarkModeKey, isDarkMode);
  }

  static bool isDarkMode() {
    return _prefs!.getBool(_isDarkModeKey) ?? true; // Default to dark mode
  }

  // Validation
  static bool hasValidApiKeys() {
    final geminiKey = getGeminiApiKey();
    final huggingFaceKey = getHuggingFaceApiKey();
    return geminiKey != null &&
        geminiKey.isNotEmpty &&
        huggingFaceKey != null &&
        huggingFaceKey.isNotEmpty;
  }

  static Future<void> clearApiKeys() async {
    await _prefs!.remove(_geminiApiKeyKey);
    await _prefs!.remove(_huggingFaceApiKeyKey);
  }
}
