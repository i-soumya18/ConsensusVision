import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconGenerator {
  static Future<Uint8List> generateAppIcon({
    double size = 512,
    Color primaryColor = const Color(0xFF6C63FF),
    Color backgroundColor = Colors.white,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
    final backgroundPaint = Paint()..color = primaryColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size, size),
        Radius.circular(size * 0.25),
      ),
      backgroundPaint,
    );

    // Inner circle for contrast
    final innerPaint = Paint()..color = backgroundColor.withOpacity(0.1);
    canvas.drawCircle(Offset(size / 2, size / 2), size * 0.4, innerPaint);

    // Main brain icon (simplified)
    final brainPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Draw a simplified brain shape
    final brainPath = Path();
    final center = Offset(size / 2, size / 2);

    // Brain outline
    brainPath.addOval(
      Rect.fromCenter(center: center, width: size * 0.6, height: size * 0.4),
    );

    canvas.drawPath(brainPath, brainPaint);

    // Camera icon overlay
    final cameraPaint = Paint()..color = primaryColor;
    final cameraCenter = Offset(size * 0.75, size * 0.75);

    // Camera background
    canvas.drawCircle(
      cameraCenter,
      size * 0.12,
      Paint()..color = backgroundColor,
    );
    canvas.drawCircle(cameraCenter, size * 0.1, cameraPaint);

    // Camera lens
    canvas.drawCircle(
      cameraCenter,
      size * 0.06,
      Paint()..color = backgroundColor,
    );
    canvas.drawCircle(cameraCenter, size * 0.03, cameraPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
