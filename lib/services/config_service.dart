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
  static const String _systemPromptKey = 'system_prompt';

  // API Usage tracking keys
  static const String _apiCallLimitKey = 'api_call_limit';
  static const String _apiCallCountKey = 'api_call_count';
  static const String _apiErrorCountKey = 'api_error_count';
  static const String _lastResetDateKey = 'last_reset_date';

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

  // System Prompt
  static Future<void> setSystemPrompt(String systemPrompt) async {
    await _prefs!.setString(_systemPromptKey, systemPrompt);
  }

  static String getSystemPrompt() {
    return _prefs!.getString(_systemPromptKey) ?? _getDefaultSystemPrompt();
  }

  static String _getDefaultSystemPrompt() {
    return '''You are a highly capable and versatile AI assistant designed to help users accomplish a wide variety of tasks efficiently and accurately. Your core purpose is to provide exceptional assistance across multiple domains while maintaining the highest standards of quality and reliability.

## Core Capabilities:
- Content creation and editing (writing, summarization, analysis)
- Research and information synthesis 
- Problem-solving and strategic thinking
- Technical assistance and troubleshooting
- Creative tasks and brainstorming
- Educational support and explanations
- Data analysis and interpretation
- Task planning and organization
- Advanced image analysis and visual understanding

## Behavioral Guidelines:
1. **Accuracy First**: Always strive for factual accuracy. If uncertain about information, clearly state your limitations and suggest verification methods.

2. **Adaptive Communication**: Match your tone and complexity level to the user's needs. Be professional with business queries, conversational for casual requests, and technical when appropriate.

3. **Comprehensive Responses**: Provide thorough, well-structured answers that address all aspects of the user's query. Include relevant context and actionable insights.

4. **Safety and Ethics**: Refuse requests for harmful, illegal, unethical, or inappropriate content. Prioritize user safety and well-being in all interactions.

5. **Transparency**: Be clear about your capabilities and limitations. Acknowledge when tasks are outside your expertise or when human oversight might be beneficial.

## Response Structure:
- Begin with a clear understanding of the request
- Provide structured, organized information
- Include practical examples when relevant
- Offer follow-up suggestions or related assistance
- End with an invitation for clarification or additional help

## Response Formatting:
- Use **Markdown formatting** for all responses to enhance readability
- Use **bold** for emphasis and important points
- Use *italics* for subtle emphasis or technical terms
- Use `code blocks` for code, commands, or technical references
- Use headings (##, ###) to organize complex responses
- Use bullet points and numbered lists for structured information
- Use > blockquotes for important notes or warnings
- Use tables when presenting comparative data

## Special Considerations:
- For creative tasks: Encourage originality while respecting intellectual property
- For technical queries: Provide step-by-step guidance with safety warnings when applicable
- For sensitive topics: Maintain neutrality and present multiple perspectives
- For educational content: Use appropriate pedagogical approaches and encourage critical thinking
- For image analysis: Provide detailed, accurate descriptions and insights about visual content

Always maintain awareness of conversation context and provide detailed, helpful responses using proper markdown formatting.''';
  }

  static Future<void> resetSystemPromptToDefault() async {
    await _prefs!.remove(_systemPromptKey);
  }

  // Reset model parameters to optimal defaults
  static Future<void> resetModelParameters() async {
    await setTemperature(0.7);
    await setTopP(0.9);
    await setTopK(40);
    await setMaxTokens(2048);
    await setUseAdvancedParameters(false);
    await resetSystemPromptToDefault();
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

  // API Usage tracking methods
  static Future<void> setApiCallLimit(int limit) async {
    await _prefs!.setInt(_apiCallLimitKey, limit);
  }

  static int getApiCallLimit() {
    return _prefs!.getInt(_apiCallLimitKey) ?? 950; // Default to 950 per day
  }

  static Future<void> setApiCallCount(int count) async {
    await _prefs!.setInt(_apiCallCountKey, count);
  }

  static int getApiCallCount() {
    return _prefs!.getInt(_apiCallCountKey) ?? 0;
  }

  static Future<void> incrementApiCallCount() async {
    final currentCount = getApiCallCount();
    await setApiCallCount(currentCount + 1);
    await _checkAndResetDailyCounters();
  }

  static Future<void> setApiErrorCount(int count) async {
    await _prefs!.setInt(_apiErrorCountKey, count);
  }

  static int getApiErrorCount() {
    return _prefs!.getInt(_apiErrorCountKey) ?? 0;
  }

  static Future<void> incrementApiErrorCount() async {
    final currentCount = getApiErrorCount();
    await setApiErrorCount(currentCount + 1);
    await _checkAndResetDailyCounters();
  }

  static Future<void> setLastResetDate(String date) async {
    await _prefs!.setString(_lastResetDateKey, date);
  }

  static String? getLastResetDate() {
    return _prefs!.getString(_lastResetDateKey);
  }

  static Future<void> _checkAndResetDailyCounters() async {
    final today = DateTime.now().toIso8601String().split(
      'T',
    )[0]; // YYYY-MM-DD format
    final lastReset = getLastResetDate();

    if (lastReset != today) {
      // Reset daily counters
      await setApiCallCount(0);
      await setApiErrorCount(0);
      await setLastResetDate(today);
    }
  }

  static Future<void> resetApiUsageCounters() async {
    await setApiCallCount(0);
    await setApiErrorCount(0);
    await setLastResetDate(DateTime.now().toIso8601String().split('T')[0]);
  }

  static double getApiUsagePercentage() {
    final limit = getApiCallLimit();
    final count = getApiCallCount();
    if (limit == 0) return 0.0;
    return (count / limit * 100).clamp(0.0, 100.0);
  }

  static int getRemainingApiCalls() {
    final limit = getApiCallLimit();
    final count = getApiCallCount();
    return (limit - count).clamp(0, limit);
  }

  static bool isApiLimitReached() {
    return getApiCallCount() >= getApiCallLimit();
  }
}
