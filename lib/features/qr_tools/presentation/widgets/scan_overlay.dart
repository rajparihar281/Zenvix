import 'package:flutter/material.dart';
import 'package:zenvix/core/theme/app_colors.dart';

/// Animated corner-bracket scan frame drawn over the camera preview.
class ScanOverlay extends StatefulWidget {
  const ScanOverlay({super.key});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scanLine;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLine = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _OverlayPainter(scanProgress: _scanLine),
    child: const SizedBox.expand(),
  );
}

class _OverlayPainter extends CustomPainter {
  _OverlayPainter({required this.scanProgress}) : super(repaint: scanProgress);

  final Animation<double> scanProgress;

  static const double _frameSize = 240;
  static const double _cornerLen = 28;
  static const double _cornerWidth = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - _frameSize / 2;
    final top = cy - _frameSize / 2;
    final right = cx + _frameSize / 2;
    final bottom = cy + _frameSize / 2;

    // Dim overlay outside the frame.
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
    final framePath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          const Radius.circular(4),
        ),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(framePath, dimPaint);

    // Corner brackets.
    final cornerPaint = Paint()
      ..color = AppColors.accentCyan
      ..strokeWidth = _cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawCorners(canvas, left, top, right, bottom, cornerPaint);

    // Animated scan line.
    final scanY = top + (_frameSize * scanProgress.value);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.accentCyan.withValues(alpha: 0),
          AppColors.accentCyan,
          AppColors.accentCyan.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(left, scanY, right, scanY));
    canvas.drawLine(Offset(left, scanY), Offset(right, scanY), linePaint);
  }

  void _drawCorners(
    Canvas canvas,
    double l,
    double t,
    double r,
    double b,
    Paint paint,
  ) {
    const cl = _cornerLen;
    // Top-left
    canvas
      ..drawLine(Offset(l, t + cl), Offset(l, t), paint)
      ..drawLine(Offset(l, t), Offset(l + cl, t), paint)
      // Top-right
      ..drawLine(Offset(r - cl, t), Offset(r, t), paint)
      ..drawLine(Offset(r, t), Offset(r, t + cl), paint)
      // Bottom-left
      ..drawLine(Offset(l, b - cl), Offset(l, b), paint)
      ..drawLine(Offset(l, b), Offset(l + cl, b), paint)
      // Bottom-right
      ..drawLine(Offset(r - cl, b), Offset(r, b), paint)
      ..drawLine(Offset(r, b), Offset(r, b - cl), paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter oldDelegate) => false;
}
