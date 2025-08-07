import 'package:flutter/material.dart';
import '../services/prompt_library_service.dart';
import '../models/prompt.dart';
import '../theme/app_theme.dart';

class AddEditPromptScreen extends StatefulWidget {
  final Prompt? prompt;

  const AddEditPromptScreen({super.key, this.prompt});

  @override
  State<AddEditPromptScreen> createState() => _AddEditPromptScreenState();
}

class _AddEditPromptScreenState extends State<AddEditPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prompt != null) {
      _titleController.text = widget.prompt!.title;
      _contentController.text = widget.prompt!.content;
      _descriptionController.text = widget.prompt!.description;
      _selectedCategory = widget.prompt!.category;
      _tagsController.text = widget.prompt!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.prompt != null;

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_isEditing) {
        final updatedPrompt = widget.prompt!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          tags: tags,
        );
        await PromptLibraryService.updatePrompt(updatedPrompt);
      } else {
        await PromptLibraryService.addPrompt(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          tags: tags,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Prompt updated successfully'
                  : 'Prompt created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Prompt' : 'Add New Prompt'),
        backgroundColor: AppTheme.surfaceColor,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePrompt,
              child: Text(
                _isEditing ? 'Update' : 'Save',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a descriptive title for your prompt',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: PromptLibraryService.getCategories()
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Briefly describe what this prompt does',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Content field
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Prompt Content',
                hintText:
                    'Enter your prompt. Use {input} as a placeholder for user input',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note),
                helperText:
                    'Tip: Use {input} where you want user input to be inserted',
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Prompt content is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tags field
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (optional)',
                hintText: 'Enter tags separated by commas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.tag),
                helperText: 'Use tags to make your prompt easier to find',
              ),
            ),
            const SizedBox(height: 24),

            // Help card
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for creating effective prompts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use clear and specific instructions\n'
                      '• Include {input} where user text should be inserted\n'
                      '• Provide context and examples when helpful\n'
                      '• Be specific about the desired output format\n'
                      '• Test your prompt to ensure it works as expected',
                      style: TextStyle(
                        color: AppTheme.onSurfaceColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview card if editing
            if (_isEditing) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Prompt',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.onSurfaceColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          widget.prompt!.content,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.onSurfaceColor.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
