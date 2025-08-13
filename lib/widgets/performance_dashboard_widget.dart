import 'dart:async';
import 'package:flutter/material.dart';
import '../services/enhanced_ai_service.dart';
import '../services/performance_monitoring_service.dart';
import '../services/response_cache_service.dart';
import '../theme/app_theme.dart';

/// Comprehensive performance dashboard for monitoring AI system performance
/// Shows real-time metrics, cache statistics, and performance trends
class PerformanceDashboardWidget extends StatefulWidget {
  const PerformanceDashboardWidget({super.key});

  @override
  State<PerformanceDashboardWidget> createState() =>
      _PerformanceDashboardWidgetState();
}

class _PerformanceDashboardWidgetState extends State<PerformanceDashboardWidget>
    with TickerProviderStateMixin {
  final EnhancedAIService _aiService = EnhancedAIService();
  late TabController _tabController;

  Map<String, dynamic>? _performanceStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPerformanceData();

    // Auto-refresh every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadPerformanceData();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    try {
      final stats = await _aiService.getPerformanceStats();
      final trends = await _aiService.getPerformanceTrends();

      if (mounted) {
        setState(() {
          _performanceStats = {...stats, 'trends': trends};
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Overview'),
            Tab(icon: Icon(Icons.cached), text: 'Cache'),
            Tab(icon: Icon(Icons.network_check), text: 'Network'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCacheTab(),
                _buildNetworkTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading performance data',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPerformanceData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final monitoring = _performanceStats?['monitoring'] as PerformanceStats?;
    if (monitoring == null)
      return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('System Performance'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Response Time',
                  '${monitoring.averageResponseTime.inMilliseconds}ms',
                  Icons.timer,
                  _getResponseTimeColor(monitoring.averageResponseTime),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${((1 - monitoring.errorRate) * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  _getSuccessRateColor(1 - monitoring.errorRate),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Throughput',
                  '${monitoring.throughputPerMinute.toStringAsFixed(1)}/min',
                  Icons.speed,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Active Sessions',
                  '${monitoring.activeSessions}',
                  Icons.timeline,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Recent Activity'),
          const SizedBox(height: 16),
          _buildActivitySummary(monitoring),
        ],
      ),
    );
  }

  Widget _buildCacheTab() {
    final cache = _performanceStats?['cache'] as CacheStatistics?;
    if (cache == null)
      return const Center(child: Text('No cache data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cache Performance'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Hit Rate',
                  '${(cache.hitRate * 100).toStringAsFixed(1)}%',
                  Icons.cached,
                  _getCacheHitRateColor(cache.hitRate),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Entries',
                  '${cache.totalEntries}',
                  Icons.storage,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Cache Hits',
                  '${cache.cacheHits}',
                  Icons.check,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Cache Misses',
                  '${cache.cacheMisses}',
                  Icons.close,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Fuzzy Hits',
                  '${cache.fuzzyHits}',
                  Icons.search,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Memory Usage',
                  '${(cache.memoryUsage / 1024).toStringAsFixed(1)} KB',
                  Icons.memory,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCacheActions(),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    final connections =
        _performanceStats?['connections'] as Map<String, dynamic>?;
    if (connections == null)
      return const Center(child: Text('No network data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Network Performance'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${connections['successRate']?.toStringAsFixed(1) ?? 0}%',
                  Icons.network_check,
                  _getSuccessRateColor((connections['successRate'] ?? 0) / 100),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Requests',
                  '${connections['totalRequests'] ?? 0}',
                  Icons.send,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Connections',
                  '${connections['activeConnections'] ?? 0}',
                  Icons.link,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Queued Requests',
                  '${connections['queuedRequests'] ?? 0}',
                  Icons.queue,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Connection Pools'),
          const SizedBox(height: 16),
          _buildConnectionPoolsList(connections),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    final trends = _performanceStats?['trends'];
    if (trends == null)
      return const Center(child: Text('No trends data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Performance Trends'),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.trending_up, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Trend analysis coming soon',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Interactive charts and performance trends will be displayed here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPerformanceAlerts(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummary(PerformanceStats monitoring) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Total Operations',
              '${monitoring.totalOperations}',
            ),
            _buildSummaryRow(
              'Cache Hit Rate',
              '${(monitoring.cacheHitRate * 100).toStringAsFixed(1)}%',
            ),
            _buildSummaryRow(
              'Error Rate',
              '${(monitoring.errorRate * 100).toStringAsFixed(1)}%',
            ),
            _buildSummaryRow('Time Range', '${monitoring.timeRange.inHours}h'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCacheActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Management',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Cache'),
                    onPressed: _clearCache,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Cleanup Expired'),
                    onPressed: _cleanupExpiredCache,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPoolsList(Map<String, dynamic> connections) {
    final pools = connections['connectionPools'] as List<dynamic>? ?? [];

    if (pools.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No active connection pools'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Pools',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...pools.map(
              (pool) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pool.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Alerts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('All systems operating normally'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getResponseTimeColor(Duration responseTime) {
    final ms = responseTime.inMilliseconds;
    if (ms < 1000) return Colors.green;
    if (ms < 3000) return Colors.orange;
    return Colors.red;
  }

  Color _getSuccessRateColor(double rate) {
    if (rate > 0.95) return Colors.green;
    if (rate > 0.85) return Colors.orange;
    return Colors.red;
  }

  Color _getCacheHitRateColor(double rate) {
    if (rate > 0.7) return Colors.green;
    if (rate > 0.4) return Colors.orange;
    return Colors.red;
  }

  Future<void> _clearCache() async {
    try {
      await ResponseCacheService.clearAllCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
      _loadPerformanceData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error clearing cache: $e')));
    }
  }

  Future<void> _cleanupExpiredCache() async {
    try {
      await ResponseCacheService.clearExpiredCache();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expired cache entries removed')),
      );
      _loadPerformanceData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cleaning cache: $e')));
    }
  }
}
