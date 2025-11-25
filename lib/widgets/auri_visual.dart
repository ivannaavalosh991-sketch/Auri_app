import 'package:flutter/material.dart';
import 'dart:math';

class AuriVisual extends StatefulWidget {
  const AuriVisual({super.key});

  @override
  State<AuriVisual> createState() => _AuriVisualState();
}

class _AuriVisualState extends State<AuriVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✨ Auri reacciona a tu toque."),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Colors.purpleAccent.withOpacity(0.8);

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _pulse,
        child: CustomPaint(
          size: const Size(120, 120),
          painter: _AuriPainter(color),
        ),
      ),
    );
  }
}

class _AuriPainter extends CustomPainter {
  final Color color;
  _AuriPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Dibuja una forma orgánica tipo slime/onda
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.25, h * 0.3, w * 0.5, h * 0.5);
    path.quadraticBezierTo(w * 0.75, h * 0.7, w, h * 0.5);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
