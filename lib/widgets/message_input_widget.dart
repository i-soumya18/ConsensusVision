import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
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

  List<File> _selectedImages = [];
  String? _selectedPromptTemplate;
  late AnimationController _animationController;
  late AnimationController _promptAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _promptSlideAnimation;
  late Animation<double> _promptFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _promptAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _promptSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _promptAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _promptFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _promptAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add listener to text controller to update send button state
    _textController.addListener(() {
      setState(() {
        // This will trigger a rebuild to update the send button state
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _promptAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected prompt template indicator
          if (_selectedPromptTemplate != null) ...[
            AnimatedBuilder(
              animation: _promptAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _promptSlideAnimation.value),
                  child: FadeTransition(
                    opacity: _promptFadeAnimation,
                    child: _buildPromptIndicator(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // Selected images preview
          if (_selectedImages.isNotEmpty) ...[
            _buildSelectedImagesPreview(),
            const SizedBox(height: 12),
          ],

          // Input row
          Row(
            children: [
              // Prompt library button
              _buildPromptLibraryButton(),
              const SizedBox(width: 8),

              // Attachment button
              _buildAttachmentButton(),
              const SizedBox(width: 8),

              // Text input
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: _selectedPromptTemplate != null
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        )
                      : null,
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: _selectedPromptTemplate != null
                          ? '✨ Enhanced AI prompt active - type your question...'
                          : '🚀 Let\'s take off!',
                      hintStyle: _selectedPromptTemplate != null
                          ? TextStyle(
                              color: AppTheme.primaryColor.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            )
                          : TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withOpacity(0.8),
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _selectedPromptTemplate != null
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : AppTheme.backgroundColor,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledText(
                  '🚀 **Enhanced AI Prompt** Active',
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedPromptTemplate!.length > 50
                      ? '${_selectedPromptTemplate!.substring(0, 50)}...'
                      : _selectedPromptTemplate!,
                  style: TextStyle(
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPromptTemplate = null;
              });
              _promptAnimationController.reverse();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: _buildStyledText(
                    '✨ **Prompt template** cleared',
                    const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagesPreview() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
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
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
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

  Widget _buildAttachmentButton() {
    return GestureDetector(
      onTap: _showAttachmentOptions,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.attach_file,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend =
        _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

    return GestureDetector(
      onTap: canSend && !widget.isLoading ? _sendMessage : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: canSend && !widget.isLoading
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
          boxShadow: canSend && !widget.isLoading
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: widget.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.send, color: Colors.white, size: 20),
      ),
    );
  }

  void _showAttachmentOptions() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStyledText(
                  '📁 **Add Images**',
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                      const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => _pickImageFromCamera(),
                      themeService: themeService,
                    ),
                    _buildAttachmentOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _pickImageFromGallery(),
                      themeService: themeService,
                    ),
                    _buildAttachmentOption(
                      icon: Icons.file_copy,
                      label: 'Files',
                      onTap: () => _pickImageFromFiles(),
                      themeService: themeService,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeService.primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (await _requestCameraPermission()) {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _pickImageFromFiles() async {
    // Temporarily disabled to avoid build issues
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _buildStyledText(
          '⚠️ **Image selection** temporarily disabled',
          const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Helper method to create styled text with markdown-like formatting
  Widget _buildStyledText(String text, TextStyle baseStyle) {
    final parts = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*|_(.*?)_');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        parts.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: baseStyle,
          ),
        );
      }

      // Add styled text
      if (match.group(1) != null) {
        // Bold text (**text**)
        parts.add(
          TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else if (match.group(2) != null) {
        // Italic text (*text*)
        parts.add(
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      } else if (match.group(3) != null) {
        // Underlined text (_text_)
        parts.add(
          TextSpan(
            text: match.group(3),
            style: baseStyle.copyWith(
              fontStyle: FontStyle.italic,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      parts.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }

    return RichText(text: TextSpan(children: parts));
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    // Show sending feedback if prompt is active
    if (_selectedPromptTemplate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 12),
              const Text('✨ *Sending enhanced AI request...*'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Determine the message to send based on what the user provided
    String messageToSend;
    if (text.isNotEmpty) {
      // Use the actual user text when they typed something
      messageToSend = text;
    } else if (_selectedImages.isNotEmpty) {
      // Only use default message when there are images but no text
      messageToSend = 'Please analyze these images.';
    } else {
      // This should never happen due to the check above, but just in case
      return;
    }

    widget.onSendMessage(
      messageToSend,
      _selectedImages.isEmpty ? null : List.from(_selectedImages),
      promptTemplate: _selectedPromptTemplate,
    );

    // Clear with animation
    if (_selectedPromptTemplate != null) {
      _promptAnimationController.reverse();
    }

    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _selectedPromptTemplate = null;
    });
  }

  Widget _buildPromptLibraryButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectedPromptTemplate != null ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: _showPromptLibrary,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _selectedPromptTemplate != null
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withBlue(255),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _selectedPromptTemplate == null
                    ? AppTheme.primaryColor.withOpacity(0.7)
                    : null,
                shape: BoxShape.circle,
                border: _selectedPromptTemplate != null
                    ? Border.all(color: Colors.white.withOpacity(0.3), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: _selectedPromptTemplate != null
                        ? AppTheme.primaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: _selectedPromptTemplate != null ? 12 : 8,
                    offset: const Offset(0, 2),
                    spreadRadius: _selectedPromptTemplate != null ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _selectedPromptTemplate != null
                        ? Icons.auto_awesome
                        : Icons.library_books_outlined,
                    color: Colors.white,
                    size: _selectedPromptTemplate != null ? 22 : 20,
                  ),
                  if (_selectedPromptTemplate != null)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPromptLibrary() async {
    final selectedPrompt = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const PromptLibraryScreen()),
    );

    if (selectedPrompt != null && selectedPrompt.isNotEmpty) {
      setState(() {
        _selectedPromptTemplate = selectedPrompt;
      });

      // Trigger animations
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      _promptAnimationController.forward();

      // Show enhanced feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStyledText(
                      '🚀 **Enhanced AI Prompt** Activated!',
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStyledText(
                      '_Your messages will now use **advanced prompting** for better AI responses_',
                      TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Clear',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _selectedPromptTemplate = null;
              });
              _promptAnimationController.reverse();
            },
          ),
        ),
      );

      // Add haptic feedback
      HapticFeedback.mediumImpact();
    }
  }
}
