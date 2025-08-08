import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? primaryColor;
  final Color? backgroundColor;

  const AppLogo({
    super.key,
    this.size = 120,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Theme.of(context).primaryColor;
    final background = backgroundColor ?? Colors.white;

    // Ensure minimum and maximum sizes for better responsiveness
    final logoSize = size.clamp(80.0, 200.0);

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(logoSize * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: logoSize * 0.15,
            offset: Offset(0, logoSize * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Brain/AI icon
          Icon(Icons.psychology_rounded, size: logoSize * 0.5, color: primary),

          // Camera lens overlay
          Positioned(
            bottom: logoSize * 0.15,
            right: logoSize * 0.15,
            child: Container(
              width: logoSize * 0.3,
              height: logoSize * 0.3,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: background,
                  width: (logoSize * 0.02).clamp(1.0, 4.0),
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: logoSize * 0.15,
                color: background,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
