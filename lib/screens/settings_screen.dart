import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/theme_service.dart';
import '../services/export_service.dart';
import '../services/model_registry_service.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _geminiApiController = TextEditingController();
  final TextEditingController _huggingFaceApiController =
      TextEditingController();
  final TextEditingController _systemPromptController = TextEditingController();
  String _selectedModel = 'Gemini';
  bool _isLoading = false;

  // API usage tracking
  int _apiCallLimit = 950;
  int _apiCallCount = 0;
  int _apiErrorCount = 0;

  // Model parameters
  double _temperature = 0.7;
  double _topP = 0.9;
  int _topK = 40;
  int _maxTokens = 2048;
  bool _useAdvancedParameters = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final geminiKey = ConfigService.getGeminiApiKey();
    final hfKey = ConfigService.getHuggingFaceApiKey();

    _geminiApiController.text = geminiKey ?? '';
    _huggingFaceApiController.text = hfKey ?? '';
    _systemPromptController.text = ConfigService.getSystemPrompt();

    // Load model parameters
    _temperature = ConfigService.getTemperature();
    _topP = ConfigService.getTopP();
    _topK = ConfigService.getTopK();
    _maxTokens = ConfigService.getMaxTokens();
    _useAdvancedParameters = ConfigService.getUseAdvancedParameters();
    _selectedModel = ConfigService.getSelectedModel();

    // Load API usage data
    _apiCallLimit = ConfigService.getApiCallLimit();
    _apiCallCount = ConfigService.getApiCallCount();
    _apiErrorCount = ConfigService.getApiErrorCount();

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _geminiApiController.dispose();
    _huggingFaceApiController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildApiKeysSection(),
                const SizedBox(height: 24),
                _buildApiUsageSection(),
                const SizedBox(height: 24),
                _buildModelSelectionSection(),
                const SizedBox(height: 24),
                _buildModelParametersSection(),
                const SizedBox(height: 24),
                _buildSystemPromptSection(),
                const SizedBox(height: 24),
                _buildThemeSection(),
                const SizedBox(height: 24),
                _buildDataManagementSection(),
                const SizedBox(height: 24),
                _buildAppInfoSection(),
                const SizedBox(height: 24),
                _buildHelpSection(),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeysSection() {
    return _buildSectionCard(
      title: 'API Configuration',
      icon: Icons.key,
      children: [
        _buildApiKeyField(
          label: 'Gemini API Key',
          controller: _geminiApiController,
          hint: 'Enter your Google Gemini API key',
          onSave: () => _saveApiKey('gemini', _geminiApiController.text),
        ),
        const SizedBox(height: 16),
        _buildApiKeyField(
          label: 'HuggingFace API Key',
          controller: _huggingFaceApiController,
          hint: 'Enter your HuggingFace API key',
          onSave: () =>
              _saveApiKey('huggingface', _huggingFaceApiController.text),
        ),
        const SizedBox(height: 12),
        Text(
          'API keys are stored securely on your device and used only for AI model requests.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required VoidCallback onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApiUsageSection() {
    final usagePercentage = ConfigService.getApiUsagePercentage();
    final remainingCalls = ConfigService.getRemainingApiCalls();
    final isLimitReached = ConfigService.isApiLimitReached();

    return _buildSectionCard(
      title: 'API Usage Monitoring',
      icon: Icons.analytics,
      children: [
        // Daily API Usage Progress
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily API Usage',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: usagePercentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLimitReached
                          ? Colors.red
                          : usagePercentage > 80
                          ? Colors.orange
                          : Colors.green,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_apiCallCount / $_apiCallLimit calls',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${usagePercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLimitReached ? Colors.red : null,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Statistics Cards
        Row(
          children: [
            Expanded(
              child: _buildUsageStatCard(
                'Remaining',
                remainingCalls.toString(),
                Icons.schedule,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildUsageStatCard(
                'Errors',
                _apiErrorCount.toString(),
                Icons.error_outline,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // API Call Limit Setting
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily API Call Limit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _apiCallLimit.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter daily API call limit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onFieldSubmitted: (value) {
                      final limit = int.tryParse(value) ?? 950;
                      _updateApiCallLimit(limit);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _resetApiUsageCounters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Warning or info message
        if (isLimitReached)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily API limit reached! Consider increasing the limit or wait for daily reset.',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else if (usagePercentage > 80)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Approaching daily API limit. $remainingCalls calls remaining.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'API usage is tracked daily and resets automatically at midnight. Default limit is 950 calls per day.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  Widget _buildUsageStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateApiCallLimit(int newLimit) async {
    await ConfigService.setApiCallLimit(newLimit);
    setState(() {
      _apiCallLimit = newLimit;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API call limit updated to $newLimit per day'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetApiUsageCounters() async {
    await ConfigService.resetApiUsageCounters();
    setState(() {
      _apiCallCount = 0;
      _apiErrorCount = 0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API usage counters reset successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildModelSelectionSection() {
    // Get available models based on current API key configuration
    final hasGeminiKey = ConfigService.getGeminiApiKey()?.isNotEmpty ?? false;
    final hasHuggingFaceKey =
        ConfigService.getHuggingFaceApiKey()?.isNotEmpty ?? false;

    final availableModels = ModelRegistryService.getAvailableModels(
      hasGeminiKey: hasGeminiKey,
      hasHuggingFaceKey: hasHuggingFaceKey,
    );

    return _buildSectionCard(
      title: 'AI Model Preferences',
      icon: Icons.psychology,
      children: [
        Text(
          'Default AI Model',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: availableModels.any((model) => model.id == _selectedModel)
              ? _selectedModel
              : 'Auto', // Fallback to Auto if selected model is not available
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          isExpanded: true,
          items: availableModels.map((model) {
            final isAvailable = ModelRegistryService.isModelAvailable(
              model.id,
              hasGeminiKey: hasGeminiKey,
              hasHuggingFaceKey: hasHuggingFaceKey,
            );

            return DropdownMenuItem(
              value: model.id,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isAvailable)
                    Icon(Icons.check_circle, size: 16, color: Colors.green)
                  else
                    Icon(Icons.warning, size: 16, color: Colors.orange),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedModel = value!;
            });
            _saveModelPreference(value!);
          },
        ),
        const SizedBox(height: 12),
        if (availableModels.length < ModelRegistryService.getAllModels().length)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add API keys above to unlock more AI models',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Auto-select uses AI evaluation to choose the best model for each query.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildModelParametersSection() {
    return _buildSectionCard(
      title: 'Model Parameters',
      icon: Icons.tune,
      children: [
        // Advanced parameters toggle
        SwitchListTile(
          title: const Text('Advanced Parameters'),
          subtitle: const Text('Fine-tune AI response generation'),
          value: _useAdvancedParameters,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) async {
            setState(() {
              _useAdvancedParameters = value;
            });
            await ConfigService.setUseAdvancedParameters(value);
            _showSnackBar(
              value
                  ? '🚀 **Advanced parameters** enabled'
                  : '✅ Using **optimal defaults**',
            );
          },
        ),

        if (_useAdvancedParameters) ...[
          const Divider(),

          // Temperature Slider
          _buildParameterSlider(
            label: 'Temperature',
            subtitle: 'Controls randomness (0.0 = focused, 1.0 = creative)',
            value: _temperature,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) async {
              setState(() {
                _temperature = value;
              });
              await ConfigService.setTemperature(value);
            },
          ),

          const SizedBox(height: 16),

          // Top-P Slider
          _buildParameterSlider(
            label: 'Top-P (Nucleus Sampling)',
            subtitle: 'Controls diversity (0.1 = narrow, 1.0 = diverse)',
            value: _topP,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (value) async {
              setState(() {
                _topP = value;
              });
              await ConfigService.setTopP(value);
            },
          ),

          const SizedBox(height: 16),

          // Top-K Slider
          _buildParameterSlider(
            label: 'Top-K',
            subtitle: 'Limits vocabulary (1 = restrictive, 100 = open)',
            value: _topK.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            isInteger: true,
            onChanged: (value) async {
              setState(() {
                _topK = value.round();
              });
              await ConfigService.setTopK(_topK);
            },
          ),

          const SizedBox(height: 16),

          // Max Tokens Slider
          _buildParameterSlider(
            label: 'Max Tokens',
            subtitle: 'Maximum response length (512 = short, 4096 = long)',
            value: _maxTokens.toDouble(),
            min: 512,
            max: 4096,
            divisions: 7,
            isInteger: true,
            onChanged: (value) async {
              setState(() {
                _maxTokens = value.round();
              });
              await ConfigService.setMaxTokens(_maxTokens);
            },
          ),

          const SizedBox(height: 16),

          // Reset to defaults button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ConfigService.resetModelParameters();
                    await _loadSettings();
                    _showSnackBar(
                      '🔄 **Model parameters** reset to optimal defaults',
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Reset to Optimal Defaults'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 **Tip**: Default values are optimized for best results. Experiment carefully!',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '✅ Using optimal parameters for best AI responses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParameterSlider({
    required String label,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isInteger ? value.round().toString() : value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.3),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            valueIndicatorColor: AppTheme.primaryColor,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSystemPromptSection() {
    return _buildSectionCard(
      title: 'System Prompt',
      icon: Icons.psychology,
      children: [
        ListTile(
          leading: Icon(Icons.smart_toy, color: AppTheme.primaryColor),
          title: const Text('AI Assistant Behavior'),
          subtitle: const Text(
            'Configure how the AI assistant responds to queries',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Prompt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _systemPromptController,
                decoration: const InputDecoration(
                  hintText: 'Enter custom system prompt...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 8,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveSystemPrompt,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetSystemPrompt,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset to Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSystemPrompt() async {
    try {
      await ConfigService.setSystemPrompt(_systemPromptController.text);
      _showSnackBar('System prompt saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save system prompt: $e');
    }
  }

  Future<void> _resetSystemPrompt() async {
    try {
      await ConfigService.resetSystemPromptToDefault();
      _systemPromptController.text = ConfigService.getSystemPrompt();
      _showSnackBar('System prompt reset to default');
    } catch (e) {
      _showSnackBar('Failed to reset system prompt: $e');
    }
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) => _buildSectionCard(
        title: 'Appearance',
        icon: Icons.palette,
        children: [
          ListTile(
            leading: Icon(Icons.brightness_6, color: AppTheme.primaryColor),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeModeDescription(themeService.themeMode)),
            trailing: DropdownButton<AppThemeMode>(
              value: themeService.themeMode,
              onChanged: (AppThemeMode? newMode) {
                if (newMode != null) {
                  themeService.setThemeMode(newMode);
                  _showSnackBar(_getThemeModeMessage(newMode));
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AppThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(
                  value: AppThemeMode.system,
                  child: Text('System'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.color_lens, color: AppTheme.primaryColor),
            title: const Text('Primary Color'),
            subtitle: const Text('Choose your preferred app color'),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeService.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            onTap: () => _showColorPicker(themeService),
          ),
        ],
      ),
    );
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system theme settings';
    }
  }

  String _getThemeModeMessage(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return '☀️ Light theme enabled';
      case AppThemeMode.dark:
        return '🌙 Dark theme enabled';
      case AppThemeMode.system:
        return '🔄 System theme enabled - follows your device settings';
    }
  }

  Widget _buildDataManagementSection() {
    return _buildSectionCard(
      title: 'Data Management',
      icon: Icons.storage,
      children: [
        _buildActionTile(
          title: 'Clear Chat History',
          subtitle: 'Delete all chat sessions and messages',
          icon: Icons.delete_outline,
          onTap: _showClearHistoryDialog,
          dangerous: true,
        ),
        const Divider(),
        _buildActionTile(
          title: 'Export Chat Data',
          subtitle: 'Export your chats in JSON, CSV, or text format',
          icon: Icons.download,
          onTap: _exportChatData,
        ),
        const Divider(),
        _buildActionTile(
          title: 'Clear Cache',
          subtitle: 'Clear temporary files and cached data',
          icon: Icons.cleaning_services,
          onTap: _clearCache,
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSectionCard(
      title: 'App Information',
      icon: Icons.info,
      children: [
        _buildInfoRow('Version', '1.0.0'),
        _buildInfoRow('Build', '2025.01.001'),
        _buildInfoRow('Platform', 'Flutter 3.32.1'),
        _buildInfoRow('Developer', 'ImageQuery Team'),
        const SizedBox(height: 16),
        _buildActionTile(
          title: 'Licenses',
          subtitle: 'View open source licenses',
          icon: Icons.article,
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return _buildSectionCard(
      title: 'Help & Support',
      icon: Icons.help,
      children: [
        _buildActionTile(
          title: 'How to Use',
          subtitle: 'Learn how to use ImageQuery effectively',
          icon: Icons.school,
          onTap: _showHowToUse,
        ),
        const Divider(),
        _buildActionTile(
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          icon: Icons.quiz,
          onTap: _showFAQ,
        ),
        const Divider(),
        _buildActionTile(
          title: 'Report Issue',
          subtitle: 'Report bugs or suggest features',
          icon: Icons.bug_report,
          onTap: _reportIssue,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool dangerous = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: dangerous ? Colors.red : AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: dangerous ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _saveApiKey(String type, String key) async {
    if (key.trim().isEmpty) {
      _showSnackBar('Please enter a valid API key');
      return;
    }

    try {
      if (type == 'gemini') {
        await ConfigService.setGeminiApiKey(key.trim());
      } else if (type == 'huggingface') {
        await ConfigService.setHuggingFaceApiKey(key.trim());
      }

      // Refresh the UI to update available models
      setState(() {
        // Check if current selected model is still available
        final hasGeminiKey =
            ConfigService.getGeminiApiKey()?.isNotEmpty ?? false;
        final hasHuggingFaceKey =
            ConfigService.getHuggingFaceApiKey()?.isNotEmpty ?? false;

        if (!ModelRegistryService.isModelAvailable(
          _selectedModel,
          hasGeminiKey: hasGeminiKey,
          hasHuggingFaceKey: hasHuggingFaceKey,
        )) {
          _selectedModel = 'Auto'; // Fallback to auto-select
          ConfigService.setSelectedModel('Auto');
        }
      });

      _showSnackBar('API key saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save API key: $e');
    }
  }

  void _saveModelPreference(String model) async {
    // Save to preferences
    await ConfigService.setSelectedModel(model);
    _showSnackBar(
      'Model preference updated to: ${ModelRegistryService.getModelById(model)?.displayName ?? model}',
    );
  }

  void _showColorPicker(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Primary Color'),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                [
                      const Color(0xFF2563EB), // Blue
                      const Color(0xFFDC2626), // Red
                      const Color(0xFF059669), // Green
                      const Color(0xFF7C3AED), // Purple
                      const Color(0xFFEA580C), // Orange
                      const Color(0xFF0891B2), // Teal
                      const Color(0xFF4338CA), // Indigo
                      const Color(0xFFDB2777), // Pink
                    ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          themeService.setPrimaryColor(color);
                          Navigator.pop(context);
                          _showSnackBar('🎨 Color theme updated');
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeService.primaryColor == color
                                  ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: themeService.primaryColor == color
                              ? Icon(Icons.check, color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text(
          'Are you sure you want to delete all chat sessions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChatHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChatHistory() async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.clearAllChatSessions();
      _showSnackBar('Chat history cleared');
    } catch (e) {
      _showSnackBar('Failed to clear chat history: $e');
    }
  }

  void _exportChatData() async {
    try {
      // Get export statistics
      final stats = await ExportService.getExportStatistics();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Chat Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export Statistics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• Chat Sessions: ${stats['total_sessions']}'),
              Text('• Total Messages: ${stats['total_messages']}'),
              Text('• User Messages: ${stats['user_messages']}'),
              Text('• AI Messages: ${stats['ai_messages']}'),
              Text('• Images: ${stats['total_images']}'),
              const SizedBox(height: 16),
              const Text(
                'Choose export format:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• JSON: Complete data with structure'),
              const Text('• CSV: Spreadsheet-compatible format'),
              const Text('• Text: Human-readable format'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('json');
              },
              child: const Text('JSON'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('csv');
              },
              child: const Text('CSV'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('text');
              },
              child: const Text('Text'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Failed to load export statistics: $e');
    }
  }

  Future<void> _performExport(String format) async {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Exporting chat data as ${format.toUpperCase()}...'),
          ],
        ),
      ),
    );

    try {
      bool success = false;

      switch (format.toLowerCase()) {
        case 'json':
          success = await ExportService.exportChatDataAsJson();
          break;
        case 'csv':
          success = await ExportService.exportChatDataAsCsv();
          break;
        case 'text':
          success = await ExportService.exportChatDataAsText();
          break;
        default:
          throw Exception('Unknown export format: $format');
      }

      // Close progress dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        _showSnackBar(
          'Chat data exported successfully as ${format.toUpperCase()}',
        );
      } else {
        _showSnackBar('Export failed');
      }
    } catch (e) {
      // Close progress dialog
      if (mounted) Navigator.of(context).pop();
      _showSnackBar('Export failed: $e');
    }
  }

  void _clearCache() {
    _showSnackBar('Cache cleared successfully');
  }

  void _showHowToUse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HowToUseScreen()),
    );
  }

  void _showFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQScreen()),
    );
  }

  void _reportIssue() {
    _showSnackBar('Redirecting to issue tracker...');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

// Additional screens for detailed help and information
class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHowToSection(context, 'Getting Started', [
            '1. Set up your API keys in Settings',
            '2. Start a new chat by tapping the + button',
            '3. Type your question or upload an image',
            '4. Send your message and get AI responses',
          ]),
          _buildHowToSection(context, 'Using Prompt Templates', [
            '1. Tap the book icon next to the text input',
            '2. Select a prompt template from the library',
            '3. Type your specific question',
            '4. The template will be applied automatically',
          ]),
          _buildHowToSection(context, 'Image Analysis', [
            '1. Tap the attachment icon',
            '2. Choose Camera, Gallery, or Files',
            '3. Select one or multiple images',
            '4. Add a question about the images',
            '5. Send to get detailed analysis',
          ]),
          _buildHowToSection(context, 'Managing Chats', [
            '1. View all chats by tapping the history icon',
            '2. Rename chats by long-pressing',
            '3. Delete unwanted chats',
            '4. Search through message history',
          ]),
        ],
      ),
    );
  }

  Widget _buildHowToSection(
    BuildContext context,
    String title,
    List<String> steps,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(step),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            context,
            'How do I get API keys?',
            'Visit Google AI Studio for Gemini API keys and HuggingFace.co for HuggingFace keys. Both offer free tiers for testing.',
          ),
          _buildFAQItem(
            context,
            'Why aren\'t my images being analyzed?',
            'Make sure you have a valid Gemini API key set up, as image analysis requires Gemini\'s vision capabilities.',
          ),
          _buildFAQItem(
            context,
            'Can I use this app offline?',
            'No, the app requires internet connection to communicate with AI models. However, your chat history is stored locally.',
          ),
          _buildFAQItem(
            context,
            'Is my data secure?',
            'Yes, all data is stored locally on your device. API keys are securely encrypted, and conversations are not shared.',
          ),
          _buildFAQItem(
            context,
            'How can I improve response quality?',
            'Use specific questions, provide context, and try different prompt templates. The auto-select model feature chooses the best AI for each query.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(answer)),
        ],
      ),
    );
  }
}
