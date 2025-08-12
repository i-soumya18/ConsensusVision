import 'package:flutter/material.dart';
import '../services/prompt_optimization_service.dart';
import '../theme/app_theme.dart';

/// Widget for managing prompt optimization settings and viewing analytics
class PromptOptimizationWidget extends StatefulWidget {
  const PromptOptimizationWidget({super.key});

  @override
  State<PromptOptimizationWidget> createState() =>
      _PromptOptimizationWidgetState();
}

class _PromptOptimizationWidgetState extends State<PromptOptimizationWidget> {
  bool _optimizationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadOptimizationData();
  }

  Future<void> _loadOptimizationData() async {
    try {
      await PromptOptimizationService.init();
      // Load recent performance data here
      // This would be implemented based on your specific prompt IDs
    } catch (e) {
      print('Error loading optimization data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildOptimizationToggle(),
            const SizedBox(height: 16),
            if (_optimizationEnabled) ...[
              _buildPerformanceSection(),
              const SizedBox(height: 16),
              _buildABTestingSection(),
              const SizedBox(height: 16),
              _buildAnalyticsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prompt Optimization',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'AI performance monitoring and continuous improvement',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Optimization',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                Text(
                  'Collect performance data and run A/B tests for better AI responses',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _optimizationEnabled,
            onChanged: (value) {
              setState(() => _optimizationEnabled = value);
              // Save preference to storage
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return _buildSection(
      title: 'Performance Metrics',
      icon: Icons.analytics,
      children: [
        _buildMetricCard(
          'Response Quality',
          '87%',
          'Average user satisfaction',
          Colors.green,
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          'Response Time',
          '2.3s',
          'Average processing time',
          Colors.blue,
        ),
        const SizedBox(height: 8),
        _buildMetricCard(
          'Error Rate',
          '3.2%',
          'Errors per 100 requests',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildABTestingSection() {
    return _buildSection(
      title: 'A/B Testing',
      icon: Icons.compare_arrows,
      children: [
        _buildABTestCard(
          'Image Analysis Prompt',
          'Testing enhanced analysis vs. standard',
          'Active',
          Colors.green,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _showCreateABTestDialog,
          icon: const Icon(Icons.add),
          label: const Text('Create New A/B Test'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return _buildSection(
      title: 'Analytics Dashboard',
      icon: Icons.dashboard,
      children: [
        _buildAnalyticsCard('Query Types', {
          'Image Analysis': 45,
          'Text Processing': 30,
          'Creative Tasks': 15,
          'Technical Help': 10,
        }),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showDetailedAnalytics,
          icon: const Icon(Icons.bar_chart),
          label: const Text('View Detailed Analytics'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.onSurfaceColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildABTestCard(
    String title,
    String description,
    String status,
    Color statusColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, Map<String, int> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 8),
          ...data.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateABTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create A/B Test'),
        content: const Text('A/B testing setup dialog would go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDetailedAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Analytics'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Detailed analytics dashboard would go here.'),
                const SizedBox(height: 16),
                // Add charts, graphs, and detailed metrics here
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
