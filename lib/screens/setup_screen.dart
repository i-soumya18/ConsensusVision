import 'package:flutter/material.dart';
import '../services/config_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _geminiController = TextEditingController();
  final _huggingFaceController = TextEditingController();
  bool _isLoading = false;
  bool _obscureGemini = true;
  bool _obscureHuggingFace = true;

  @override
  void initState() {
    super.initState();
    _loadExistingKeys();
  }

  void _loadExistingKeys() {
    _geminiController.text = ConfigService.getGeminiApiKey() ?? '';
    _huggingFaceController.text = ConfigService.getHuggingFaceApiKey() ?? '';
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _huggingFaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildApiKeySection(),
                        const SizedBox(height: 32),
                        _buildInstructionsSection(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.smart_toy,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to ImageQuery AI',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'To get started, please provide your API keys for Gemini AI and Hugging Face.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Configuration',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),

        // Gemini API Key
        _buildApiKeyField(
          controller: _geminiController,
          label: 'Gemini AI API Key',
          obscure: _obscureGemini,
          onToggleObscure: () =>
              setState(() => _obscureGemini = !_obscureGemini),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Gemini API key';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Hugging Face API Key
        _buildApiKeyField(
          controller: _huggingFaceController,
          label: 'Hugging Face API Key',
          obscure: _obscureHuggingFace,
          onToggleObscure: () =>
              setState(() => _obscureHuggingFace = !_obscureHuggingFace),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your Hugging Face API key';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggleObscure,
        ),
        prefixIcon: const Icon(Icons.key),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to get API keys',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(
            '1. Gemini AI',
            'Visit ai.google.dev → Get API key → Create new project → Generate key',
          ),
          const SizedBox(height: 8),
          _buildInstructionItem(
            '2. Hugging Face',
            'Visit huggingface.co → Settings → Access Tokens → New token',
          ),
          const SizedBox(height: 12),
          Text(
            'Your API keys are stored locally and never shared.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveConfiguration,
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save & Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ConfigService.setGeminiApiKey(_geminiController.text.trim());
      await ConfigService.setHuggingFaceApiKey(
        _huggingFaceController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving configuration: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
