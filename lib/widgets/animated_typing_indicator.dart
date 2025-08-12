import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator({super.key});

  @override
  State<AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _waveAnimations;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400), // Slower for premium feel
      vsync: this,
    );

    // Create wave animations for each bar with staggered timing
    _waveAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.12, // More subtle stagger
            (index * 0.12) + 0.6, // Longer animation duration
            curve: Curves.elasticOut, // More premium elastic curve
          ),
        ),
      );
    });

    // Shimmer effect for premium feel
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOutQuart),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Wave pattern with 5 bars
              ...List.generate(5, (index) {
                final waveValue = _waveAnimations[index].value;
                final baseHeight = 4.0;
                final maxHeight = 16.0;
                final waveHeight = baseHeight + (maxHeight - baseHeight) * 
                  (0.3 + 0.7 * (0.5 + 0.5 * math.sin(waveValue * math.pi)));
                
                return AnimatedBuilder(
                  animation: _waveAnimations[index],
                  builder: (context, child) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 3.5,
                        height: waveHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.4 + 0.4 * waveValue),
                              AppTheme.primaryColor.withOpacity(0.7 + 0.3 * waveValue),
                              AppTheme.primaryColor.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.2 * waveValue),
                              blurRadius: 3 * waveValue,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              
              // Shimmer effect for premium touch
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [
                          0.0,
                          math.max(0.0, _shimmerAnimation.value - 0.15),
                          _shimmerAnimation.value,
                          math.min(1.0, _shimmerAnimation.value + 0.15),
                          1.0,
                        ],
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppTheme.primaryColor.withOpacity(0.8),
                          AppTheme.primaryColor.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3 * _shimmerAnimation.value),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
