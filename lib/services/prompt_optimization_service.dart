import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for A/B testing prompts and tracking performance metrics
/// Implements continuous improvement techniques from prompt engineering best practices
class PromptOptimizationService {
  static const String _metricsKey = 'prompt_performance_metrics';
  static const String _abTestKey = 'ab_test_configurations';
  static const String _feedbackKey = 'user_feedback_data';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Track performance metrics for prompt effectiveness
  static Future<void> trackPromptPerformance({
    required String promptId,
    required String sessionId,
    required double responseTime,
    required bool userSatisfied,
    required String queryType,
    int? tokenCount,
    String? errorType,
  }) async {
    await init();

    final metrics = await _getPerformanceMetrics();
    final timestamp = DateTime.now().toIso8601String();

    final metricEntry = {
      'promptId': promptId,
      'sessionId': sessionId,
      'timestamp': timestamp,
      'responseTime': responseTime,
      'userSatisfied': userSatisfied,
      'queryType': queryType,
      'tokenCount': tokenCount,
      'errorType': errorType,
    };

    metrics.add(metricEntry);

    // Keep only last 1000 entries to prevent storage bloat
    if (metrics.length > 1000) {
      metrics.removeRange(0, metrics.length - 1000);
    }

    await _savePerformanceMetrics(metrics);
  }

  /// Analyze prompt performance and generate optimization recommendations
  static Future<PromptAnalysisReport> analyzePromptPerformance(
    String promptId,
  ) async {
    await init();

    final metrics = await _getPerformanceMetrics();
    final promptMetrics = metrics
        .where((m) => m['promptId'] == promptId)
        .toList();

    if (promptMetrics.isEmpty) {
      return PromptAnalysisReport(
        promptId: promptId,
        totalUsage: 0,
        averageResponseTime: 0,
        satisfactionRate: 0,
        recommendations: ['No usage data available for analysis'],
      );
    }

    final totalUsage = promptMetrics.length;
    final averageResponseTime =
        promptMetrics
            .map((m) => m['responseTime'] as double)
            .reduce((a, b) => a + b) /
        totalUsage;

    final satisfiedCount = promptMetrics
        .where((m) => m['userSatisfied'] as bool)
        .length;
    final satisfactionRate = satisfiedCount / totalUsage;

    final recommendations = _generateOptimizationRecommendations(
      promptMetrics,
      satisfactionRate,
      averageResponseTime,
    );

    return PromptAnalysisReport(
      promptId: promptId,
      totalUsage: totalUsage,
      averageResponseTime: averageResponseTime,
      satisfactionRate: satisfactionRate,
      recommendations: recommendations,
      queryTypeBreakdown: _analyzeQueryTypes(promptMetrics),
      errorAnalysis: _analyzeErrors(promptMetrics),
    );
  }

  /// Set up A/B test for comparing prompt variations
  static Future<void> setupABTest({
    required String testId,
    required String promptAId,
    required String promptBId,
    required String testDescription,
    double splitRatio = 0.5,
  }) async {
    await init();

    final abTests = await _getABTests();

    final testConfig = {
      'testId': testId,
      'promptAId': promptAId,
      'promptBId': promptBId,
      'description': testDescription,
      'splitRatio': splitRatio,
      'startDate': DateTime.now().toIso8601String(),
      'isActive': true,
      'participantCount': 0,
    };

    abTests[testId] = testConfig;
    await _saveABTests(abTests);
  }

  /// Get the prompt ID to use for A/B testing
  static Future<String> getPromptForABTest(
    String testId,
    String defaultPromptId,
  ) async {
    await init();

    final abTests = await _getABTests();
    final testConfig = abTests[testId];

    if (testConfig == null || !(testConfig['isActive'] as bool)) {
      return defaultPromptId;
    }

    final splitRatio = testConfig['splitRatio'] as double;
    final usePromptA = Random().nextDouble() < splitRatio;

    // Update participant count
    testConfig['participantCount'] =
        (testConfig['participantCount'] as int) + 1;
    abTests[testId] = testConfig;
    await _saveABTests(abTests);

    return usePromptA
        ? testConfig['promptAId'] as String
        : testConfig['promptBId'] as String;
  }

  /// Analyze A/B test results
  static Future<ABTestResults> analyzeABTest(String testId) async {
    await init();

    final abTests = await _getABTests();
    final testConfig = abTests[testId];

    if (testConfig == null) {
      throw Exception('A/B test not found: $testId');
    }

    final metrics = await _getPerformanceMetrics();
    final promptAId = testConfig['promptAId'] as String;
    final promptBId = testConfig['promptBId'] as String;

    final promptAMetrics = metrics
        .where((m) => m['promptId'] == promptAId)
        .toList();
    final promptBMetrics = metrics
        .where((m) => m['promptId'] == promptBId)
        .toList();

    return ABTestResults(
      testId: testId,
      promptAResults: _calculatePromptStats(promptAMetrics),
      promptBResults: _calculatePromptStats(promptBMetrics),
      statisticalSignificance: _calculateStatisticalSignificance(
        promptAMetrics,
        promptBMetrics,
      ),
      recommendation: _generateABTestRecommendation(
        promptAMetrics,
        promptBMetrics,
      ),
    );
  }

  /// Record user feedback for continuous improvement
  static Future<void> recordUserFeedback({
    required String sessionId,
    required String promptId,
    required int rating, // 1-5 scale
    String? feedback,
    List<String>? improvementSuggestions,
  }) async {
    await init();

    final feedbackData = await _getUserFeedback();

    final feedbackEntry = {
      'sessionId': sessionId,
      'promptId': promptId,
      'rating': rating,
      'feedback': feedback,
      'improvementSuggestions': improvementSuggestions,
      'timestamp': DateTime.now().toIso8601String(),
    };

    feedbackData.add(feedbackEntry);

    // Keep only last 500 feedback entries
    if (feedbackData.length > 500) {
      feedbackData.removeRange(0, feedbackData.length - 500);
    }

    await _saveFeedbackData(feedbackData);
  }

  // Private helper methods

  static Future<List<Map<String, dynamic>>> _getPerformanceMetrics() async {
    final data = _prefs!.getString(_metricsKey);
    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> _savePerformanceMetrics(
    List<Map<String, dynamic>> metrics,
  ) async {
    await _prefs!.setString(_metricsKey, jsonEncode(metrics));
  }

  static Future<Map<String, dynamic>> _getABTests() async {
    final data = _prefs!.getString(_abTestKey);
    if (data == null) return {};

    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static Future<void> _saveABTests(Map<String, dynamic> abTests) async {
    await _prefs!.setString(_abTestKey, jsonEncode(abTests));
  }

  static Future<List<Map<String, dynamic>>> _getUserFeedback() async {
    final data = _prefs!.getString(_feedbackKey);
    if (data == null) return [];

    final List<dynamic> decoded = jsonDecode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> _saveFeedbackData(
    List<Map<String, dynamic>> feedback,
  ) async {
    await _prefs!.setString(_feedbackKey, jsonEncode(feedback));
  }

  static List<String> _generateOptimizationRecommendations(
    List<Map<String, dynamic>> metrics,
    double satisfactionRate,
    double averageResponseTime,
  ) {
    final recommendations = <String>[];

    if (satisfactionRate < 0.7) {
      recommendations.add(
        'Low satisfaction rate detected. Consider revising prompt clarity and specificity.',
      );
    }

    if (averageResponseTime > 10.0) {
      recommendations.add(
        'High response times. Consider simplifying the prompt or reducing complexity.',
      );
    }

    final errorCount = metrics.where((m) => m['errorType'] != null).length;
    if (errorCount > metrics.length * 0.1) {
      recommendations.add(
        'High error rate detected. Review prompt for potential ambiguities.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Performance is good. Consider minor optimizations for specific use cases.',
      );
    }

    return recommendations;
  }

  static Map<String, int> _analyzeQueryTypes(
    List<Map<String, dynamic>> metrics,
  ) {
    final queryTypes = <String, int>{};

    for (final metric in metrics) {
      final queryType = metric['queryType'] as String;
      queryTypes[queryType] = (queryTypes[queryType] ?? 0) + 1;
    }

    return queryTypes;
  }

  static Map<String, int> _analyzeErrors(List<Map<String, dynamic>> metrics) {
    final errors = <String, int>{};

    for (final metric in metrics) {
      final errorType = metric['errorType'] as String?;
      if (errorType != null) {
        errors[errorType] = (errors[errorType] ?? 0) + 1;
      }
    }

    return errors;
  }

  static PromptStats _calculatePromptStats(List<Map<String, dynamic>> metrics) {
    if (metrics.isEmpty) {
      return PromptStats(
        usageCount: 0,
        averageResponseTime: 0,
        satisfactionRate: 0,
        errorRate: 0,
      );
    }

    final totalUsage = metrics.length;
    final averageResponseTime =
        metrics
            .map((m) => m['responseTime'] as double)
            .reduce((a, b) => a + b) /
        totalUsage;

    final satisfiedCount = metrics
        .where((m) => m['userSatisfied'] as bool)
        .length;
    final satisfactionRate = satisfiedCount / totalUsage;

    final errorCount = metrics.where((m) => m['errorType'] != null).length;
    final errorRate = errorCount / totalUsage;

    return PromptStats(
      usageCount: totalUsage,
      averageResponseTime: averageResponseTime,
      satisfactionRate: satisfactionRate,
      errorRate: errorRate,
    );
  }

  static double _calculateStatisticalSignificance(
    List<Map<String, dynamic>> promptAMetrics,
    List<Map<String, dynamic>> promptBMetrics,
  ) {
    // Simplified chi-square test for statistical significance
    // In a real implementation, you'd use a proper statistical library

    if (promptAMetrics.length < 30 || promptBMetrics.length < 30) {
      return 0.0; // Not enough data for significance
    }

    final aSuccess = promptAMetrics
        .where((m) => m['userSatisfied'] as bool)
        .length;
    final bSuccess = promptBMetrics
        .where((m) => m['userSatisfied'] as bool)
        .length;

    final aTotal = promptAMetrics.length;
    final bTotal = promptBMetrics.length;

    // Simple difference-based significance (not statistically rigorous)
    final aSatisfactionRate = aSuccess / aTotal;
    final bSatisfactionRate = bSuccess / bTotal;

    return (aSatisfactionRate - bSatisfactionRate).abs();
  }

  static String _generateABTestRecommendation(
    List<Map<String, dynamic>> promptAMetrics,
    List<Map<String, dynamic>> promptBMetrics,
  ) {
    final aStats = _calculatePromptStats(promptAMetrics);
    final bStats = _calculatePromptStats(promptBMetrics);

    if (aStats.satisfactionRate > bStats.satisfactionRate + 0.05) {
      return 'Prompt A shows significantly better performance. Consider implementing as default.';
    } else if (bStats.satisfactionRate > aStats.satisfactionRate + 0.05) {
      return 'Prompt B shows significantly better performance. Consider implementing as default.';
    } else {
      return 'No significant difference detected. Continue testing or use user preference.';
    }
  }
}

// Data classes for results

class PromptAnalysisReport {
  final String promptId;
  final int totalUsage;
  final double averageResponseTime;
  final double satisfactionRate;
  final List<String> recommendations;
  final Map<String, int>? queryTypeBreakdown;
  final Map<String, int>? errorAnalysis;

  PromptAnalysisReport({
    required this.promptId,
    required this.totalUsage,
    required this.averageResponseTime,
    required this.satisfactionRate,
    required this.recommendations,
    this.queryTypeBreakdown,
    this.errorAnalysis,
  });
}

class ABTestResults {
  final String testId;
  final PromptStats promptAResults;
  final PromptStats promptBResults;
  final double statisticalSignificance;
  final String recommendation;

  ABTestResults({
    required this.testId,
    required this.promptAResults,
    required this.promptBResults,
    required this.statisticalSignificance,
    required this.recommendation,
  });
}

class PromptStats {
  final int usageCount;
  final double averageResponseTime;
  final double satisfactionRate;
  final double errorRate;

  PromptStats({
    required this.usageCount,
    required this.averageResponseTime,
    required this.satisfactionRate,
    required this.errorRate,
  });
}
