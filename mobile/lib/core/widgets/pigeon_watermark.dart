import 'package:flutter/material.dart';

class PigeonWatermarkPainter extends CustomPainter {
  final Color color;

  const PigeonWatermarkPainter({
    this.color = const Color(0x29FFFFFF), // ~16% white
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // SVG path viewBox is 24x24:
    // M2.6 13.4c4.7.5 8.2-1 10.6-4.5.7-1 2.2-.8 2.3.5.1 1-.5 1.9-1.4 2.6 1.9.2 3.5-.5 5-1.9-.2 3.3-2.6 6-6.1 6.8l.9 3.3-4.4-2.3c-3.3-.3-6-2.2-6.9-4.6Z
    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    final path = Path();
    path.moveTo(2.6 * scaleX, 13.4 * scaleY);
    path.cubicTo(
      (2.6 + 4.7) * scaleX, (13.4 + 0.5) * scaleY,
      (2.6 + 8.2) * scaleX, (13.4 - 1.0) * scaleY,
      (2.6 + 10.6) * scaleX, (13.4 - 4.5) * scaleY,
    );
    path.cubicTo(
      (13.2 + 0.7) * scaleX, (8.9 - 1.0) * scaleY,
      (13.2 + 2.2) * scaleX, (8.9 - 0.8) * scaleY,
      (13.2 + 2.3) * scaleX, (8.9 + 0.5) * scaleY,
    );
    path.cubicTo(
      (15.5 + 0.1) * scaleX, (9.4 + 1.0) * scaleY,
      (15.5 - 0.5) * scaleX, (9.4 + 1.9) * scaleY,
      (15.5 - 1.4) * scaleX, (9.4 + 2.6) * scaleY,
    );
    path.cubicTo(
      (14.1 + 1.9) * scaleX, (12.0 + 0.2) * scaleY,
      (14.1 + 3.5) * scaleX, (12.0 - 0.5) * scaleY,
      (14.1 + 5.0) * scaleX, (12.0 - 1.9) * scaleY,
    );
    path.cubicTo(
      (19.1 - 0.2) * scaleX, (10.1 + 3.3) * scaleY,
      (19.1 - 2.6) * scaleX, (10.1 + 6.0) * scaleY,
      (19.1 - 6.1) * scaleX, (10.1 + 6.8) * scaleY,
    );
    path.lineTo((13.0 + 0.9) * scaleX, (16.9 + 3.3) * scaleY);
    path.lineTo((13.9 - 4.4) * scaleX, (20.2 - 2.3) * scaleY);
    path.cubicTo(
      (9.5 - 3.3) * scaleX, (17.9 - 0.3) * scaleY,
      (9.5 - 6.0) * scaleX, (17.9 - 2.2) * scaleY,
      (9.5 - 6.9) * scaleX, (17.9 - 4.6) * scaleY,
    );
    path.close();

    canvas.drawPath(path, paint);

    // Eye circle cx=14.4, cy=8.1, r=0.7
    final eyePaint = Paint()
      ..color = const Color(0x181E49B8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(14.4 * scaleX, 8.1 * scaleY),
      0.7 * scaleX,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PigeonWatermarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class PigeonWatermark extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;

  const PigeonWatermark({
    super.key,
    this.width = 230,
    this.height = 230,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: PigeonWatermarkPainter(
        color: color ?? const Color(0x29FFFFFF),
      ),
    );
  }
}
