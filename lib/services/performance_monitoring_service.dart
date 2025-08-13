import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Real-time performance monitoring service for AI operations
/// Tracks response times, error rates, and system performance metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  // Performance metrics storage
  static const String _performanceDataKey = 'performance_monitoring_data';
  static const String _thresholdsKey = 'performance_thresholds';

  SharedPreferences? _prefs;
  final Map<String, PerformanceSession> _activeSessions = {};
  final List<PerformanceMetric> _recentMetrics = [];
  PerformanceThresholds _thresholds = PerformanceThresholds.defaults();

  // Real-time statistics
  final MovingAverage _responseTimeAverage = MovingAverage(50);
  final MovingAverage _errorRateAverage = MovingAverage(100);
  final MovingAverage _throughputAverage = MovingAverage(30);

  Timer? _cleanupTimer;
  Timer? _alertTimer;

  /// Initialize the performance monitoring service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadThresholds();
    await _loadHistoricalData();

    // Start periodic cleanup and alerting
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupOldSessions();
      _cleanupOldMetrics();
    });

    _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPerformanceAlerts();
    });
  }

  /// Start tracking a new performance session
  String startSession({
    required String operation,
    String? model,
    Map<String, dynamic>? metadata,
  }) {
    final sessionId = '${operation}_${DateTime.now().millisecondsSinceEpoch}';

    _activeSessions[sessionId] = PerformanceSession(
      id: sessionId,
      operation: operation,
      model: model,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
    );

    return sessionId;
  }

  /// End a performance session and record metrics
  Future<PerformanceMetric> endSession(
    String sessionId, {
    bool success = true,
    String? error,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(session.startTime);

    final metric = PerformanceMetric(
      sessionId: sessionId,
      operation: session.operation,
      model: session.model,
      startTime: session.startTime,
      endTime: endTime,
      duration: duration,
      success: success,
      error: error,
      metadata: {...session.metadata, ...?additionalMetadata},
    );

    // Update real-time averages
    _responseTimeAverage.add(duration.inMilliseconds.toDouble());
    _errorRateAverage.add(success ? 0.0 : 1.0);
    _throughputAverage.add(1.0); // One operation completed

    // Store metric
    _recentMetrics.add(metric);
    if (_recentMetrics.length > 1000) {
      _recentMetrics.removeRange(0, _recentMetrics.length - 1000);
    }

    // Remove from active sessions
    _activeSessions.remove(sessionId);

    // Persist data periodically
    if (_recentMetrics.length % 10 == 0) {
      await _persistMetrics();
    }

    return metric;
  }

  /// Record a cache hit for performance tracking
  void recordCacheHit(String operation, Duration savedTime) {
    final metric = PerformanceMetric(
      sessionId: 'cache_${DateTime.now().millisecondsSinceEpoch}',
      operation: operation,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      duration: Duration.zero,
      success: true,
      metadata: {'cache_hit': true, 'time_saved_ms': savedTime.inMilliseconds},
    );

    _recentMetrics.add(metric);
    _throughputAverage.add(1.0);
  }

  /// Get current performance statistics
  PerformanceStats getCurrentStats() {
    final now = DateTime.now();
    final recentMetrics = _recentMetrics
        .where((m) => now.difference(m.endTime).inMinutes < 60)
        .toList();

    final successfulOps = recentMetrics.where((m) => m.success).length;
    final totalOps = recentMetrics.length;
    final errorRate = totalOps > 0 ? 1.0 - (successfulOps / totalOps) : 0.0;

    final avgResponseTime = _responseTimeAverage.value;
    final throughput = _throughputAverage.value * 60; // Per minute

    final cacheHits = recentMetrics
        .where((m) => m.metadata['cache_hit'] == true)
        .length;
    final cacheHitRate = totalOps > 0 ? cacheHits / totalOps : 0.0;

    return PerformanceStats(
      averageResponseTime: Duration(milliseconds: avgResponseTime.round()),
      errorRate: errorRate,
      throughputPerMinute: throughput,
      cacheHitRate: cacheHitRate,
      activeSessions: _activeSessions.length,
      totalOperations: totalOps,
      timeRange: const Duration(hours: 1),
    );
  }

  /// Get performance trends over time
  Future<PerformanceTrends> getPerformanceTrends({
    Duration period = const Duration(hours: 24),
  }) async {
    final now = DateTime.now();
    final cutoff = now.subtract(period);

    final metrics = _recentMetrics
        .where((m) => m.endTime.isAfter(cutoff))
        .toList();

    if (metrics.isEmpty) {
      return PerformanceTrends.empty();
    }

    // Group metrics by hour
    final hourlyBuckets = <int, List<PerformanceMetric>>{};
    for (final metric in metrics) {
      final hour = metric.endTime.hour;
      hourlyBuckets.putIfAbsent(hour, () => []).add(metric);
    }

    final responseTimeTrend = <DateTime, double>{};
    final errorRateTrend = <DateTime, double>{};
    final throughputTrend = <DateTime, double>{};

    for (final entry in hourlyBuckets.entries) {
      final hour = entry.key;
      final hourMetrics = entry.value;

      final hourTime = DateTime(now.year, now.month, now.day, hour);

      final avgResponseTime =
          hourMetrics
              .map((m) => m.duration.inMilliseconds.toDouble())
              .reduce((a, b) => a + b) /
          hourMetrics.length;

      final errorCount = hourMetrics.where((m) => !m.success).length;
      final errorRate = errorCount / hourMetrics.length;

      final throughput = hourMetrics.length.toDouble();

      responseTimeTrend[hourTime] = avgResponseTime;
      errorRateTrend[hourTime] = errorRate;
      throughputTrend[hourTime] = throughput;
    }

    return PerformanceTrends(
      responseTimeTrend: responseTimeTrend,
      errorRateTrend: errorRateTrend,
      throughputTrend: throughputTrend,
      period: period,
    );
  }

  /// Get performance alerts
  List<PerformanceAlert> getActiveAlerts() {
    final alerts = <PerformanceAlert>[];
    final stats = getCurrentStats();

    // Check response time alert
    if (stats.averageResponseTime.inMilliseconds >
        _thresholds.maxResponseTimeMs) {
      alerts.add(
        PerformanceAlert(
          type: AlertType.highResponseTime,
          severity: AlertSeverity.warning,
          message:
              'Average response time is ${stats.averageResponseTime.inMilliseconds}ms, '
              'exceeding threshold of ${_thresholds.maxResponseTimeMs}ms',
          timestamp: DateTime.now(),
          value: stats.averageResponseTime.inMilliseconds.toDouble(),
          threshold: _thresholds.maxResponseTimeMs.toDouble(),
        ),
      );
    }

    // Check error rate alert
    if (stats.errorRate > _thresholds.maxErrorRate) {
      alerts.add(
        PerformanceAlert(
          type: AlertType.highErrorRate,
          severity: stats.errorRate > 0.2
              ? AlertSeverity.critical
              : AlertSeverity.warning,
          message:
              'Error rate is ${(stats.errorRate * 100).toStringAsFixed(1)}%, '
              'exceeding threshold of ${(_thresholds.maxErrorRate * 100).toStringAsFixed(1)}%',
          timestamp: DateTime.now(),
          value: stats.errorRate,
          threshold: _thresholds.maxErrorRate,
        ),
      );
    }

    // Check low throughput alert
    if (stats.throughputPerMinute < _thresholds.minThroughputPerMinute) {
      alerts.add(
        PerformanceAlert(
          type: AlertType.lowThroughput,
          severity: AlertSeverity.info,
          message:
              'Throughput is ${stats.throughputPerMinute.toStringAsFixed(1)} ops/min, '
              'below threshold of ${_thresholds.minThroughputPerMinute} ops/min',
          timestamp: DateTime.now(),
          value: stats.throughputPerMinute,
          threshold: _thresholds.minThroughputPerMinute,
        ),
      );
    }

    return alerts;
  }

  /// Update performance thresholds
  Future<void> updateThresholds(PerformanceThresholds newThresholds) async {
    _thresholds = newThresholds;
    await _saveThresholds();
  }

  /// Get detailed performance report
  PerformanceReport generateReport({
    Duration period = const Duration(hours: 24),
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(period);

    final metrics = _recentMetrics
        .where((m) => m.endTime.isAfter(cutoff))
        .toList();

    if (metrics.isEmpty) {
      return PerformanceReport.empty(period);
    }

    // Calculate statistics
    final responseTimes = metrics
        .map((m) => m.duration.inMilliseconds)
        .toList();
    responseTimes.sort();

    final p50 = _percentile(responseTimes, 0.5);
    final p95 = _percentile(responseTimes, 0.95);
    final p99 = _percentile(responseTimes, 0.99);

    final operationBreakdown = <String, int>{};
    final modelBreakdown = <String, int>{};
    final errorBreakdown = <String, int>{};

    for (final metric in metrics) {
      operationBreakdown[metric.operation] =
          (operationBreakdown[metric.operation] ?? 0) + 1;

      if (metric.model != null) {
        modelBreakdown[metric.model!] =
            (modelBreakdown[metric.model!] ?? 0) + 1;
      }

      if (!metric.success && metric.error != null) {
        errorBreakdown[metric.error!] =
            (errorBreakdown[metric.error!] ?? 0) + 1;
      }
    }

    return PerformanceReport(
      period: period,
      totalOperations: metrics.length,
      successfulOperations: metrics.where((m) => m.success).length,
      averageResponseTime: Duration(
        milliseconds:
            (responseTimes.reduce((a, b) => a + b) / responseTimes.length)
                .round(),
      ),
      p50ResponseTime: Duration(milliseconds: p50.round()),
      p95ResponseTime: Duration(milliseconds: p95.round()),
      p99ResponseTime: Duration(milliseconds: p99.round()),
      operationBreakdown: operationBreakdown,
      modelBreakdown: modelBreakdown,
      errorBreakdown: errorBreakdown,
      cacheHitRate:
          metrics.where((m) => m.metadata['cache_hit'] == true).length /
          metrics.length,
    );
  }

  /// Cleanup and dispose
  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _alertTimer?.cancel();
    await _persistMetrics();
  }

  // Private helper methods

  void _cleanupOldSessions() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 1));

    _activeSessions.removeWhere(
      (_, session) => session.startTime.isBefore(cutoff),
    );
  }

  void _cleanupOldMetrics() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    _recentMetrics.removeWhere((metric) => metric.endTime.isBefore(cutoff));
  }

  void _checkPerformanceAlerts() {
    final alerts = getActiveAlerts();
    if (alerts.isNotEmpty && kDebugMode) {
      for (final alert in alerts) {
        print('Performance Alert [${alert.severity.name}]: ${alert.message}');
      }
    }
  }

  Future<void> _persistMetrics() async {
    if (_prefs == null) return;

    final metricsData = _recentMetrics.map((m) => m.toJson()).toList();

    await _prefs!.setString(_performanceDataKey, jsonEncode(metricsData));
  }

  Future<void> _loadHistoricalData() async {
    if (_prefs == null) return;

    final data = _prefs!.getString(_performanceDataKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        _recentMetrics.clear();
        _recentMetrics.addAll(
          decoded.map((json) => PerformanceMetric.fromJson(json)),
        );
      } catch (e) {
        if (kDebugMode) {
          print('Error loading performance data: $e');
        }
      }
    }
  }

  Future<void> _saveThresholds() async {
    if (_prefs == null) return;
    await _prefs!.setString(_thresholdsKey, jsonEncode(_thresholds.toJson()));
  }

  Future<void> _loadThresholds() async {
    if (_prefs == null) return;

    final data = _prefs!.getString(_thresholdsKey);
    if (data != null) {
      try {
        _thresholds = PerformanceThresholds.fromJson(jsonDecode(data));
      } catch (e) {
        _thresholds = PerformanceThresholds.defaults();
      }
    }
  }

  double _percentile(List<int> values, double percentile) {
    if (values.isEmpty) return 0.0;

    final index = (values.length * percentile).floor();
    return values[index.clamp(0, values.length - 1)].toDouble();
  }
}

/// Performance session tracking
class PerformanceSession {
  final String id;
  final String operation;
  final String? model;
  final DateTime startTime;
  final Map<String, dynamic> metadata;

  PerformanceSession({
    required this.id,
    required this.operation,
    this.model,
    required this.startTime,
    required this.metadata,
  });
}

/// Performance metric data model
class PerformanceMetric {
  final String sessionId;
  final String operation;
  final String? model;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.sessionId,
    required this.operation,
    this.model,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.success,
    this.error,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'operation': operation,
    'model': model,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'duration': duration.inMilliseconds,
    'success': success,
    'error': error,
    'metadata': metadata,
  };

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) =>
      PerformanceMetric(
        sessionId: json['sessionId'],
        operation: json['operation'],
        model: json['model'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        duration: Duration(milliseconds: json['duration']),
        success: json['success'],
        error: json['error'],
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}

/// Current performance statistics
class PerformanceStats {
  final Duration averageResponseTime;
  final double errorRate;
  final double throughputPerMinute;
  final double cacheHitRate;
  final int activeSessions;
  final int totalOperations;
  final Duration timeRange;

  PerformanceStats({
    required this.averageResponseTime,
    required this.errorRate,
    required this.throughputPerMinute,
    required this.cacheHitRate,
    required this.activeSessions,
    required this.totalOperations,
    required this.timeRange,
  });
}

/// Performance trends over time
class PerformanceTrends {
  final Map<DateTime, double> responseTimeTrend;
  final Map<DateTime, double> errorRateTrend;
  final Map<DateTime, double> throughputTrend;
  final Duration period;

  PerformanceTrends({
    required this.responseTimeTrend,
    required this.errorRateTrend,
    required this.throughputTrend,
    required this.period,
  });

  factory PerformanceTrends.empty() => PerformanceTrends(
    responseTimeTrend: {},
    errorRateTrend: {},
    throughputTrend: {},
    period: Duration.zero,
  );
}

/// Performance alert model
class PerformanceAlert {
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final double value;
  final double threshold;

  PerformanceAlert({
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.value,
    required this.threshold,
  });
}

enum AlertType {
  highResponseTime,
  highErrorRate,
  lowThroughput,
  memoryUsage,
  cachePerformance,
}

enum AlertSeverity { info, warning, critical }

/// Performance thresholds configuration
class PerformanceThresholds {
  final int maxResponseTimeMs;
  final double maxErrorRate;
  final double minThroughputPerMinute;
  final double minCacheHitRate;

  PerformanceThresholds({
    required this.maxResponseTimeMs,
    required this.maxErrorRate,
    required this.minThroughputPerMinute,
    required this.minCacheHitRate,
  });

  factory PerformanceThresholds.defaults() => PerformanceThresholds(
    maxResponseTimeMs: 5000,
    maxErrorRate: 0.05,
    minThroughputPerMinute: 1.0,
    minCacheHitRate: 0.3,
  );

  Map<String, dynamic> toJson() => {
    'maxResponseTimeMs': maxResponseTimeMs,
    'maxErrorRate': maxErrorRate,
    'minThroughputPerMinute': minThroughputPerMinute,
    'minCacheHitRate': minCacheHitRate,
  };

  factory PerformanceThresholds.fromJson(Map<String, dynamic> json) =>
      PerformanceThresholds(
        maxResponseTimeMs: json['maxResponseTimeMs'] ?? 5000,
        maxErrorRate: json['maxErrorRate'] ?? 0.05,
        minThroughputPerMinute: json['minThroughputPerMinute'] ?? 1.0,
        minCacheHitRate: json['minCacheHitRate'] ?? 0.3,
      );
}

/// Comprehensive performance report
class PerformanceReport {
  final Duration period;
  final int totalOperations;
  final int successfulOperations;
  final Duration averageResponseTime;
  final Duration p50ResponseTime;
  final Duration p95ResponseTime;
  final Duration p99ResponseTime;
  final Map<String, int> operationBreakdown;
  final Map<String, int> modelBreakdown;
  final Map<String, int> errorBreakdown;
  final double cacheHitRate;

  PerformanceReport({
    required this.period,
    required this.totalOperations,
    required this.successfulOperations,
    required this.averageResponseTime,
    required this.p50ResponseTime,
    required this.p95ResponseTime,
    required this.p99ResponseTime,
    required this.operationBreakdown,
    required this.modelBreakdown,
    required this.errorBreakdown,
    required this.cacheHitRate,
  });

  factory PerformanceReport.empty(Duration period) => PerformanceReport(
    period: period,
    totalOperations: 0,
    successfulOperations: 0,
    averageResponseTime: Duration.zero,
    p50ResponseTime: Duration.zero,
    p95ResponseTime: Duration.zero,
    p99ResponseTime: Duration.zero,
    operationBreakdown: {},
    modelBreakdown: {},
    errorBreakdown: {},
    cacheHitRate: 0.0,
  );

  double get successRate =>
      totalOperations > 0 ? successfulOperations / totalOperations : 0.0;
}

/// Moving average calculator for real-time metrics
class MovingAverage {
  final int windowSize;
  final List<double> _values = [];
  double _sum = 0.0;

  MovingAverage(this.windowSize);

  void add(double value) {
    _values.add(value);
    _sum += value;

    if (_values.length > windowSize) {
      _sum -= _values.removeAt(0);
    }
  }

  double get value => _values.isNotEmpty ? _sum / _values.length : 0.0;

  int get count => _values.length;

  bool get isFull => _values.length >= windowSize;
}
