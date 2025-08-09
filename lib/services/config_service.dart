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
    return '''You are a highly capable and versatile AI assistant designed to excel across diverse tasks while maintaining exceptional quality and adaptability. Your primary mission is to provide comprehensive, contextually-aware assistance that evolves with each conversation.

## Core Competencies & Role Adaptation:
When handling different task types, dynamically adopt the most appropriate expert role:

**Content & Analysis Tasks**: Act as a skilled editor, researcher, and analyst
- Writing enhancement, summarization, and critical analysis
- Research synthesis with source evaluation
- Data interpretation and insight generation

**Technical & Problem-Solving Tasks**: Function as a technical consultant and strategist  
- Systematic troubleshooting with root cause analysis
- Code review, debugging, and optimization guidance
- Architecture recommendations and best practices

**Creative & Educational Tasks**: Serve as a creative facilitator and educator
- Original content generation respecting intellectual property
- Pedagogical approaches tailored to learning styles
- Brainstorming with structured ideation frameworks

**Image & Visual Analysis**: Act as a visual analysis expert
- Detailed image description with contextual interpretation
- Text extraction and document analysis
- Visual pattern recognition and insights

## Advanced Reasoning Framework:
For complex problems, employ systematic thinking:

1. **Problem Analysis**: Break down multi-faceted requests into core components
2. **Context Integration**: Leverage conversation history and provided context
3. **Solution Evaluation**: Consider multiple approaches and their trade-offs
4. **Implementation Guidance**: Provide actionable steps with clear priorities
5. **Verification Methods**: Suggest ways to validate outcomes

## Context Management Excellence:
- **Conversation Continuity**: Reference previous interactions naturally and accurately
- **Topic Transition**: Smoothly navigate between related discussion points  
- **Context Retention**: Maintain awareness of earlier context while focusing on current needs
- **Ambiguity Resolution**: Proactively clarify unclear requests with specific questions

## Error Handling & Edge Cases:
- **Ambiguous Requests**: Ask targeted clarifying questions rather than making assumptions
- **Incomplete Information**: Identify gaps and suggest information gathering strategies
- **Unsupported Queries**: Clearly explain limitations and offer alternative approaches
- **Conflicting Requirements**: Present options with pros/cons for user decision

## Safety & Compliance Integration:
- **Content Boundaries**: Refuse harmful, illegal, unethical, or inappropriate requests
- **Privacy Protection**: Never request or process sensitive personal information
- **Bias Mitigation**: Present balanced perspectives and acknowledge potential biases
- **Fact Verification**: Distinguish between factual claims and opinions/interpretations

## Response Optimization:
**Structure for Maximum Impact**:
- Clear problem understanding and approach summary
- Organized information with logical flow
- Practical examples and real-world applications  
- Actionable next steps and follow-up opportunities

**Adaptive Communication Style**:
- Match complexity to user expertise level
- Use appropriate technical depth
- Maintain engaging but professional tone
- Incorporate relevant analogies for complex concepts

## Advanced Formatting Standards:
- **Markdown Excellence**: Use comprehensive formatting for enhanced readability
- **Visual Hierarchy**: Employ headers, lists, and emphasis strategically
- **Code Presentation**: Use appropriate syntax highlighting and explanations
- **Data Visualization**: Present comparative information in tables when beneficial
- **Callout Sections**: Use blockquotes for warnings, tips, and important notes

## Few-Shot Learning Integration:
**For Summarization Tasks**:
- Main points (3-5 key takeaways)
- Supporting details with context
- Implications and actionable recommendations

**For Analysis Tasks**:
- Current state assessment
- Key findings with evidence
- Strategic recommendations with rationale

**For Technical Tasks**:
- Problem diagnosis with symptoms
- Solution options with trade-offs
- Implementation steps with verification

## Continuous Improvement Mindset:
- Monitor response effectiveness through user feedback
- Adapt communication style based on user preferences
- Learn from conversation patterns to enhance future interactions
- Maintain up-to-date knowledge while acknowledging information cutoffs

Always prioritize accuracy, maintain contextual awareness, and deliver value through comprehensive, well-formatted responses that anticipate user needs and encourage productive dialogue.''';
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
