import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/prompt_library_screen.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String message, List<File>? images, {String? promptTemplate})
  onSendMessage;
  final bool isLoading;

  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    required this.isLoading,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  String? _selectedPromptTemplate;
  bool _isExpanded = false;

  late AnimationController _sendButtonAnimationController;
  late AnimationController _expandAnimationController;
  late Animation<double> _sendButtonScaleAnimation;

  @override
  void initState() {
    super.initState();

    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _sendButtonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendButtonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    final hasContent = hasText || _selectedImages.isNotEmpty;

    if (hasContent && !_sendButtonAnimationController.isCompleted) {
      _sendButtonAnimationController.forward();
    } else if (!hasContent && _sendButtonAnimationController.isCompleted) {
      _sendButtonAnimationController.reverse();
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isExpanded = _focusNode.hasFocus;
    });

    if (_isExpanded) {
      _expandAnimationController.forward();
    } else {
      _expandAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonAnimationController.dispose();
    _expandAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected images preview
            if (_selectedImages.isNotEmpty) _buildImagesPreview(),

            // Prompt template indicator
            if (_selectedPromptTemplate != null) _buildPromptIndicator(),

            // Main input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  _buildAttachmentButton(),

                  const SizedBox(width: 8),

                  // Text input field
                  Expanded(child: _buildTextInput()),

                  const SizedBox(width: 8),

                  // Send/Mic button
                  _buildSendButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _showAttachmentOptions,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.attach_file_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focusNode.hasFocus
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Prompt library button
          if (!_focusNode.hasFocus || _selectedPromptTemplate != null)
            _buildPromptLibraryButton(),

          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: _getHintText(),
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 16,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal:
                      _selectedPromptTemplate != null || !_focusNode.hasFocus
                      ? 8
                      : 16,
                  vertical: 12,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptLibraryButton() {
    final isSelected = _selectedPromptTemplate != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _showPromptLibrary,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected
                    ? Icons.auto_awesome_rounded
                    : Icons.library_books_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final hasContent =
        _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

    return AnimatedBuilder(
      animation: _sendButtonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonScaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: hasContent && !widget.isLoading ? _sendMessage : null,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasContent
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        hasContent ? Icons.send_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagesPreview() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          final image = _selectedImages[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image,
                    width: 80,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromptIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Using prompt template',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedPromptTemplate = null),
            child: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    if (_selectedImages.isNotEmpty && _textController.text.isEmpty) {
      return 'Add a caption...';
    }
    return 'Message';
  }

  void _showAttachmentOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    color: Colors.pink,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement document picker
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showPromptLibrary() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromptLibraryScreen(
          onPromptSelected: (promptTemplate) {
            setState(() {
              _selectedPromptTemplate = promptTemplate;
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (status.isDenied) return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
        _onTextChanged(); // Update send button state
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _onTextChanged(); // Update send button state
  }

  void _sendMessage() {
    final text = _textController.text.trim();

    if (text.isEmpty && _selectedImages.isEmpty) return;

    HapticFeedback.lightImpact();

    widget.onSendMessage(
      text,
      _selectedImages.isNotEmpty ? List.from(_selectedImages) : null,
      promptTemplate: _selectedPromptTemplate,
    );

    // Clear input
    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedPromptTemplate = null;
    });

    _onTextChanged(); // Update send button state
  }
}
