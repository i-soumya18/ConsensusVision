import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/config_service.dart';
import '../widgets/app_logo.dart';
import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _logoRotation;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textScale;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor:
            Colors.blue, // Using Colors.blue instead of Theme-dependent color
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo rotation animation
    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Logo scale animation
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Fade animation for text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Text scale animation
    _textScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );
  }

  void _startAnimation() async {
    // Start logo scale animation
    _scaleController.forward();

    // Start logo rotation after a short delay
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Start text fade in
    await Future.delayed(const Duration(milliseconds: 600));
    _fadeController.forward();

    // Navigate after animations complete
    await Future.delayed(const Duration(milliseconds: 2500));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    // Check if setup is required
    final hasApiKeys =
        (ConfigService.getGeminiApiKey()?.isNotEmpty ?? false) ||
        (ConfigService.getHuggingFaceApiKey()?.isNotEmpty ?? false);

    if (!mounted) return;

    // Reset system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    if (hasApiKeys) {
      Navigator.of(context).pushReplacementNamed('/chat');
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenAspectRatio = screenWidth / screenHeight;

    // Responsive sizing based on screen dimensions
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;
    final isLandscape = screenAspectRatio > 1.5;

    // Calculate responsive sizes
    final logoSize = isDesktop
        ? 180.0
        : isTablet
        ? 160.0
        : isLandscape
        ? 100.0
        : 120.0;

    final titleFontSize = isDesktop
        ? 54.0
        : isTablet
        ? 48.0
        : isLandscape
        ? 28.0
        : 36.0;

    final subtitleFontSize = isDesktop
        ? 24.0
        : isTablet
        ? 20.0
        : isLandscape
        ? 14.0
        : 16.0;

    // Responsive padding
    final horizontalPadding = isDesktop
        ? screenWidth * 0.15
        : isTablet
        ? screenWidth * 0.12
        : screenWidth * 0.08;

    final verticalPadding = isLandscape
        ? screenHeight * 0.02
        : screenHeight * 0.05;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withBlue(255),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: isLandscape
                ? _buildLandscapeLayout(
                    logoSize,
                    titleFontSize,
                    subtitleFontSize,
                    isTablet,
                    screenHeight,
                  )
                : _buildPortraitLayout(
                    logoSize,
                    titleFontSize,
                    subtitleFontSize,
                    isTablet,
                    screenHeight,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    double logoSize,
    double titleFontSize,
    double subtitleFontSize,
    bool isTablet,
    double screenHeight,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top spacer - responsive to screen height
        SizedBox(height: screenHeight * 0.08),

        // Logo Animation
        Expanded(
          flex: 3,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _scaleController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.rotate(
                    angle: _logoRotation.value * 0.1, // Subtle rotation
                    child: AppLogo(
                      size: logoSize,
                      backgroundColor: Colors.white,
                      primaryColor: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // App Name Animation
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _textScale.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lumini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'AI-Powered Image Analysis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Loading indicator
        Expanded(
          flex: 2,
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value * 0.7,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: isTablet ? 40 : 30,
                      height: isTablet ? 40 : 30,
                      child: CircularProgressIndicator(
                        strokeWidth: isTablet ? 3 : 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Version info
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * 0.6,
              child: Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    double logoSize,
    double titleFontSize,
    double subtitleFontSize,
    bool isTablet,
    double screenHeight,
  ) {
    return Row(
      children: [
        // Left side - Logo
        Expanded(
          flex: 1,
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoController, _scaleController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.rotate(
                    angle: _logoRotation.value * 0.1,
                    child: AppLogo(
                      size: logoSize,
                      backgroundColor: Colors.white,
                      primaryColor: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Right side - Text and Loading
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Name
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: Column(
                        children: [
                          Text(
                            'ImageQuery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            'AI-Powered Image Analysis',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.06),

              // Loading indicator
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.7,
                    child: Column(
                      children: [
                        SizedBox(
                          width: isTablet ? 35 : 25,
                          height: isTablet ? 35 : 25,
                          child: CircularProgressIndicator(
                            strokeWidth: isTablet ? 3 : 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.04),

              // Version info
              AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.6,
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
