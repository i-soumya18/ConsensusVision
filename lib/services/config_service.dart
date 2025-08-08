import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _geminiApiKeyKey = 'gemini_api_key';
  static const String _huggingFaceApiKeyKey = 'huggingface_api_key';
  static const String _isDarkModeKey = 'is_dark_mode';

  // Model parameter keys
  static const String _temperatureKey = 'model_temperature';
  static const String _topPKey = 'model_top_p';
  static const String _topKKey = 'model_top_k';
  static const String _maxTokensKey = 'model_max_tokens';
  static const String _useAdvancedParametersKey = 'use_advanced_parameters';
  static const String _selectedModelKey = 'selected_model';

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

  // Model Parameters with optimal defaults
  static Future<void> setTemperature(double temperature) async {
    await _prefs!.setDouble(_temperatureKey, temperature);
  }

  static double getTemperature() {
    return _prefs!.getDouble(_temperatureKey) ?? 0.7; // Optimal default
  }

  static Future<void> setTopP(double topP) async {
    await _prefs!.setDouble(_topPKey, topP);
  }

  static double getTopP() {
    return _prefs!.getDouble(_topPKey) ?? 0.9; // Optimal default
  }

  static Future<void> setTopK(int topK) async {
    await _prefs!.setInt(_topKKey, topK);
  }

  static int getTopK() {
    return _prefs!.getInt(_topKKey) ?? 40; // Optimal default
  }

  static Future<void> setMaxTokens(int maxTokens) async {
    await _prefs!.setInt(_maxTokensKey, maxTokens);
  }

  static int getMaxTokens() {
    return _prefs!.getInt(_maxTokensKey) ?? 2048; // Optimal default
  }

  static Future<void> setUseAdvancedParameters(bool useAdvanced) async {
    await _prefs!.setBool(_useAdvancedParametersKey, useAdvanced);
  }

  static bool getUseAdvancedParameters() {
    return _prefs!.getBool(_useAdvancedParametersKey) ??
        false; // Default to simple mode
  }

  // Selected AI Model
  static Future<void> setSelectedModel(String modelName) async {
    await _prefs!.setString(_selectedModelKey, modelName);
  }

  static String getSelectedModel() {
    return _prefs!.getString(_selectedModelKey) ??
        'Auto'; // Default to auto-select
  }

  // Reset model parameters to optimal defaults
  static Future<void> resetModelParameters() async {
    await setTemperature(0.7);
    await setTopP(0.9);
    await setTopK(40);
    await setMaxTokens(2048);
    await setUseAdvancedParameters(false);
  }

  // Get all model parameters as a map
  static Map<String, dynamic> getModelParameters() {
    return {
      'temperature': getTemperature(),
      'topP': getTopP(),
      'topK': getTopK(),
      'maxTokens': getMaxTokens(),
      'useAdvanced': getUseAdvancedParameters(),
    };
  }
}
