import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../screens/prompt_library_screen.dart';
import '../providers/context_aware_chat_provider.dart';

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

  // Color getters to replace static AppTheme colors
  Color get primaryColor => Theme.of(context).colorScheme.primary;
  Color get surfaceColor => Theme.of(context).colorScheme.surface;
  Color get onSurfaceColor => Theme.of(context).colorScheme.onSurface;

  final List<File> _selectedImages = [];
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

    // Add focus listener for enhanced animations
    _focusNode.addListener(() {
      setState(() {
        // This will trigger animations when focus changes
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

  // Platform-responsive height calculations
  double _getMinTextFieldHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need more space
      return (screenHeight * 0.06).clamp(48.0, 60.0);
    } else {
      // Desktop platforms (Windows, macOS, Linux)
      return 48.0;
    }
  }

  double _getMaxTextFieldHeight() {
    final screenHeight = MediaQuery.of(context).size.height;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need more expansion space
      return (screenHeight * 0.25).clamp(120.0, 200.0);
    } else {
      // Desktop platforms
      return (screenHeight * 0.2).clamp(120.0, 160.0);
    }
  }

  double _getResponsivePadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need more generous padding
      return screenWidth < 400 ? 12.0 : 16.0;
    } else {
      // Desktop platforms
      return 20.0;
    }
  }

  EdgeInsets _getResponsiveContentPadding() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need optimized padding for touch interaction
      return const EdgeInsets.symmetric(horizontal: 18, vertical: 16);
    } else {
      // Desktop platforms
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  double _getResponsiveButtonSize() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need larger touch targets
      return 52.0;
    } else {
      // Desktop platforms
      return 48.0;
    }
  }

  double _getResponsiveIconSize() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need slightly larger icons
      return 24.0;
    } else {
      // Desktop platforms
      return 22.0;
    }
  }

  double _getResponsiveSpacing() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need more generous spacing
      return 16.0;
    } else {
      // Desktop platforms
      return 12.0;
    }
  }

  int _getMinLines() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need minimum visible lines for better UX
      return 1;
    } else {
      // Desktop platforms
      return 1;
    }
  }

  TextInputAction _getTextInputAction() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms - send on go button
      return TextInputAction.send;
    } else {
      // Desktop platforms - newline for enter, send on ctrl+enter
      return TextInputAction.newline;
    }
  }

  double _getResponsiveFontSize() {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms need slightly larger text for readability
      return 16.0;
    } else {
      // Desktop platforms
      return 15.0;
    }
  }

  void _handleTextSubmission(String value) {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    if (isAndroid || isIOS) {
      // Mobile platforms - send message on submit
      _sendMessage();
    }
    // Desktop platforms don't auto-send on enter, only on button press
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_getResponsivePadding()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Session default prompt indicator (shown when no specific prompt is selected)
              Consumer<ContextAwareChatProvider>(
                builder: (context, chatProvider, child) {
                  final hasDefaultPrompt =
                      chatProvider.currentSessionDefaultPrompt != null;
                  final hasSelectedPrompt = _selectedPromptTemplate != null;

                  if (!hasSelectedPrompt && hasDefaultPrompt) {
                    return Column(
                      children: [
                        _buildDefaultPromptIndicator(
                          chatProvider.currentSessionDefaultPrompt!,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Selected prompt template indicator (overrides default)
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Prompt library button
                  _buildEnhancedPromptLibraryButton(),
                  SizedBox(width: _getResponsiveSpacing()),

                  // Attachment button
                  _buildEnhancedAttachmentButton(),
                  SizedBox(width: _getResponsiveSpacing()),

                  // Text input
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      constraints: BoxConstraints(
                        minHeight: _getMinTextFieldHeight(),
                        maxHeight: _getMaxTextFieldHeight(),
                      ),
                      decoration: _selectedPromptTemplate != null
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            )
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getFillColor(),
                              _getFillColor().withOpacity(0.9),
                            ],
                          ),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? primaryColor.withOpacity(0.3)
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.1),
                            width: _focusNode.hasFocus ? 2 : 1,
                          ),
                          boxShadow: _focusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.1),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          minLines: _getMinLines(),
                          textInputAction: _getTextInputAction(),
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          enableSuggestions: true,
                          autocorrect: true,
                          style: TextStyle(
                            fontSize: _getResponsiveFontSize(),
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: _getHintText(),
                            hintStyle: _getHintStyle().copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding: _getResponsiveContentPadding(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: false,
                            fillColor: Colors.transparent,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _handleTextSubmission,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: _getResponsiveSpacing()),

                  // Send button
                  _buildSendButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.12),
            primaryColor.withOpacity(0.06),
            Colors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledText(
                  '✨ **Enhanced AI Prompt** Active',
                  TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPromptTemplate!.length > 45
                      ? '${_selectedPromptTemplate!.substring(0, 45)}...'
                      : _selectedPromptTemplate!,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
                    backgroundColor: primaryColor,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.red.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultPromptIndicator(String defaultPrompt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.04),
            Colors.amber.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.9),
                  primaryColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStyledText(
                  '⭐ **Default Prompt** for this Chat',
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  defaultPrompt.length > 45
                      ? '${defaultPrompt.substring(0, 45)}...'
                      : defaultPrompt,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
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
            onTap: () async {
              final chatProvider = Provider.of<ContextAwareChatProvider>(
                context,
                listen: false,
              );
              await chatProvider.setDefaultPromptForSession(null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: _buildStyledText(
                    '✨ **Default prompt** cleared for this chat',
                    const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagesPreview() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.file(
                        _selectedImages[index],
                        width: 77,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _removeImage(index),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
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

  Widget _buildEnhancedAttachmentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _showAttachmentOptions,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: _getResponsiveButtonSize(),
                height: _getResponsiveButtonSize(),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.attach_file_rounded,
                      color: Colors.white,
                      size: _getResponsiveIconSize(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend =
        _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    final isActive = canSend && !widget.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: isActive ? _sendMessage : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: _getResponsiveButtonSize(),
          height: _getResponsiveButtonSize(),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.3),
                      primaryColor.withOpacity(0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                )
              else
                AnimatedScale(
                  scale: isActive ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.send_rounded,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withOpacity(0.6),
                    size: _getResponsiveIconSize(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                        Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                const SizedBox(height: 28),
                _buildStyledText(
                  '� **Add Images**',
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: 0.5,
                      ) ??
                      const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose from multiple sources',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEnhancedAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      subtitle: 'Take photo',
                      onTap: () => _pickImageFromCamera(),
                      themeService: themeService,
                    ),
                    _buildEnhancedAttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      subtitle: 'Choose existing',
                      onTap: () => _pickImageFromGallery(),
                      themeService: themeService,
                    ),
                    _buildEnhancedAttachmentOption(
                      icon: Icons.file_copy_rounded,
                      label: 'Files',
                      subtitle: 'Browse files',
                      onTap: () => _pickImageFromFiles(),
                      themeService: themeService,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeService themeService,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeService.primaryColor.withOpacity(0.15),
                      themeService.primaryColor.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.primaryColor.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, color: themeService.primaryColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          backgroundColor: primaryColor,
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

  Widget _buildEnhancedPromptLibraryButton() {
    final bool isSelected = _selectedPromptTemplate != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _showPromptLibrary,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected ? _scaleAnimation.value : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: _getResponsiveButtonSize(),
                height: _getResponsiveButtonSize(),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.7),
                            Colors.deepPurple.withOpacity(0.8),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.8),
                            primaryColor.withOpacity(0.6),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? primaryColor.withOpacity(0.4)
                          : primaryColor.withOpacity(0.25),
                      blurRadius: isSelected ? 16 : 12,
                      offset: const Offset(0, 4),
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                    if (isSelected)
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isSelected
                            ? Icons.auto_awesome_rounded
                            : Icons.library_books_rounded,
                        key: ValueKey(isSelected),
                        color: Colors.white,
                        size: isSelected ? _getResponsiveIconSize() + 2 : _getResponsiveIconSize(),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: AnimatedScale(
                          scale: isSelected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.lightGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

      // Set this prompt as the default for the current chat session
      final chatProvider = Provider.of<ContextAwareChatProvider>(
        context,
        listen: false,
      );
      await chatProvider.setDefaultPromptForSession(selectedPrompt);

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
                      '🚀 **Default Prompt Set** for this Chat!',
                      const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStyledText(
                      '_All future messages in this chat will use this **enhanced prompt** by default_',
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
          backgroundColor: primaryColor,
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

  String _getHintText() {
    if (_selectedPromptTemplate != null) {
      return '✨ Enhanced AI prompt active - type your question...';
    }

    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
    if (chatProvider.currentSessionDefaultPrompt != null) {
      return '⭐ Default prompt active - type your message...';
    }

    return '🚀 Let\'s take off!';
  }

  TextStyle _getHintStyle() {
    if (_selectedPromptTemplate != null) {
      return TextStyle(
        color: primaryColor.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      );
    }

    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
    if (chatProvider.currentSessionDefaultPrompt != null) {
      return TextStyle(
        color: primaryColor.withOpacity(0.6),
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      );
    }

    return TextStyle(
      fontWeight: FontWeight.w600,
      color: primaryColor.withOpacity(0.8),
    );
  }

  Color _getFillColor() {
    final baseColor = Theme.of(context).colorScheme.surface;

    if (_focusNode.hasFocus) {
      if (_selectedPromptTemplate != null) {
        return primaryColor.withOpacity(0.08);
      }

      final chatProvider = Provider.of<ContextAwareChatProvider>(
        context,
        listen: false,
      );
      if (chatProvider.currentSessionDefaultPrompt != null) {
        return primaryColor.withOpacity(0.05);
      }

      return baseColor.withOpacity(0.98);
    }

    // Unfocused states
    if (_selectedPromptTemplate != null) {
      return primaryColor.withOpacity(0.05);
    }

    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
    if (chatProvider.currentSessionDefaultPrompt != null) {
      return primaryColor.withOpacity(0.03);
    }

    return baseColor.withOpacity(0.95);
  }
}
