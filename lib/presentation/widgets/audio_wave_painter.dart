import 'package:flutter/material.dart';

class AudioWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2.0;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Dibujar ondas de audio
    for (int i = 0; i < 5; i++) {
      final x = (width / 5) * i;
      final amplitude = 10.0 + (i * 3.0); // Amplitud variable
      final y1 = centerY - amplitude;
      final y2 = centerY + amplitude;

      if (i == 0) {
        path.moveTo(x, centerY);
      }
      
      path.quadraticBezierTo(
        x + width / 10,
        y1,
        x + width / 5,
        centerY,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
