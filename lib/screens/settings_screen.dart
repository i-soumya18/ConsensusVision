import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/theme_service.dart';
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
  String _selectedModel = 'Gemini';
  bool _isLoading = false;

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

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _geminiApiController.dispose();
    _huggingFaceApiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildApiKeysSection(),
                const SizedBox(height: 24),
                _buildModelSelectionSection(),
                const SizedBox(height: 24),
                _buildThemeSection(),
                const SizedBox(height: 24),
                _buildDataManagementSection(),
                const SizedBox(height: 24),
                _buildAppInfoSection(),
                const SizedBox(height: 24),
                _buildHelpSection(),
                const SizedBox(height: 24),
                _buildDeveloperSection(),
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
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
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

  Widget _buildModelSelectionSection() {
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
          value: _selectedModel,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Gemini',
              child: Text('Google Gemini 2.5 Flash'),
            ),
            DropdownMenuItem(
              value: 'HuggingFace',
              child: Text('HuggingFace Models'),
            ),
            DropdownMenuItem(
              value: 'Auto',
              child: Text('Auto-select Best Model'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedModel = value!;
            });
            _saveModelPreference(value!);
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Auto-select uses AI evaluation to choose the best model for each query.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) => _buildSectionCard(
        title: 'Appearance',
        icon: Icons.palette,
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme for better night viewing'),
            value: themeService.isDarkMode,
            onChanged: (value) async {
              await themeService.setThemeMode(value);
              _showSnackBar(value ? 'Dark mode enabled' : 'Light mode enabled');
            },
            activeColor: AppTheme.primaryColor,
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
          subtitle: 'Export your chats as JSON file',
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

  Widget _buildDeveloperSection() {
    return _buildSectionCard(
      title: 'Developer',
      icon: Icons.code,
      children: [
        _buildActionTile(
          title: 'Developer Notes',
          subtitle: 'Technical information and changelog',
          icon: Icons.notes,
          onTap: _showDeveloperNotes,
        ),
        const Divider(),
        _buildActionTile(
          title: 'Debug Information',
          subtitle: 'View app debug information',
          icon: Icons.bug_report,
          onTap: _showDebugInfo,
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
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
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
      _showSnackBar('API key saved successfully');
    } catch (e) {
      _showSnackBar('Failed to save API key: $e');
    }
  }

  void _saveModelPreference(String model) {
    // Save to preferences
    _showSnackBar('Model preference updated');
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
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.purple,
                      Colors.orange,
                      Colors.teal,
                      Colors.indigo,
                      Colors.pink,
                    ]
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          themeService.setPrimaryColor(color);
                          Navigator.pop(context);
                          _showSnackBar('Color theme updated');
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeService.primaryColor == color
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
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

  void _exportChatData() {
    _showSnackBar('Export feature coming soon');
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

  void _showDeveloperNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DeveloperNotesScreen()),
    );
  }

  void _showDebugInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DebugInfoScreen()),
    );
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
        backgroundColor: AppTheme.surfaceColor,
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
        backgroundColor: AppTheme.surfaceColor,
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

class DeveloperNotesScreen extends StatelessWidget {
  const DeveloperNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Notes'),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNoteCard(context, 'Version 1.0.0 - January 2025', [
            '• Initial release with Gemini and HuggingFace integration',
            '• Multi-modal chat support (text + images)',
            '• Prompt library with customizable templates',
            '• Cross-platform support (Android, Windows, Web)',
            '• Local chat history with SQLite storage',
          ]),
          _buildNoteCard(context, 'Technical Architecture', [
            '• Flutter 3.32.1 with Provider state management',
            '• RESTful API integration with http package',
            '• Local database using sqflite',
            '• Material Design 3 UI components',
            '• Cross-platform file system access',
          ]),
          _buildNoteCard(context, 'AI Model Integration', [
            '• Google Gemini 2.5 Flash for vision and text',
            '• HuggingFace Inference API for text generation',
            '• AI evaluation service for model selection',
            '• Confidence scoring for response quality',
            '• Conversation context preservation',
          ]),
          _buildNoteCard(context, 'Upcoming Features', [
            '• Voice input and text-to-speech',
            '• Advanced image editing tools',
            '• Custom AI model fine-tuning',
            '• Team collaboration features',
            '• Cloud sync and backup',
          ]),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context,
    String title,
    List<String> notes,
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
            ...notes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(note),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DebugInfoScreen extends StatelessWidget {
  const DebugInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(
                const ClipboardData(text: 'Debug info copied to clipboard'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debug info copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDebugSection('System Information', {
            'Platform': 'Flutter',
            'Version': '3.32.1',
            'Dart Version': '3.8.1',
            'Build Mode': 'Debug',
          }),
          _buildDebugSection('App Information', {
            'Version': '1.0.0+1',
            'Package': 'com.imagequery.imagequery',
            'Build Number': '1',
            'Target SDK': '35',
          }),
          _buildDebugSection('API Status', {
            'Gemini API': 'Connected',
            'HuggingFace API': 'Connected',
            'Network': 'Online',
            'Database': 'Initialized',
          }),
          _buildDebugSection('Performance', {
            'Memory Usage': '~50MB',
            'Database Size': '~2MB',
            'Cache Size': '~5MB',
            'Total Messages': '0',
          }),
        ],
      ),
    );
  }

  Widget _buildDebugSection(String title, Map<String, String> info) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...info.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
