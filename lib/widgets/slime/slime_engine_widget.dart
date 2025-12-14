// -------------------------------------------------------------
// SLIME ENGINE — GEL FIX V4 (forma corregida + ojos centrados)
// -------------------------------------------------------------

import 'dart:math';
import 'package:flutter/material.dart';

enum _SlimeExpression {
  greet,
  neutral,
  listening,
  speaking,
  sad,
  thinking,
  confused,
  angry,
  laughing,
}

class SlimeEngineWidget extends StatefulWidget {
  final Color color;
  final String emotion;
  final double moodWobble;
  final double voiceEnergy;

  final bool isListening;
  final bool isThinking;

  const SlimeEngineWidget({
    super.key,
    required this.color,
    required this.emotion,
    required this.moodWobble,
    required this.voiceEnergy,
    this.isListening = false,
    this.isThinking = false,
  });

  @override
  State<SlimeEngineWidget> createState() => _SlimeEngineWidgetState();
}

class _SlimeEngineWidgetState extends State<SlimeEngineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _bounceHeight = 12;
  double _bounceSpeed = 1.0;
  _SlimeExpression _expression = _SlimeExpression.neutral;

  @override
  void initState() {
    super.initState();
    _expression = _resolveExpression();
    _configurePhysics();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (850 ~/ _bounceSpeed)),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant SlimeEngineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final prev = _expression;
    _expression = _resolveExpression();

    if (prev != _expression || oldWidget.moodWobble != widget.moodWobble) {
      _configurePhysics();
      _controller.duration = Duration(
        milliseconds: max(180, (850 ~/ _bounceSpeed)),
      );
      _controller.forward(from: _controller.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _SlimeExpression _resolveExpression() {
    if (widget.voiceEnergy > 0.45) return _SlimeExpression.speaking;
    if (widget.isListening) return _SlimeExpression.listening;
    if (widget.isThinking) return _SlimeExpression.thinking;

    final emo = widget.emotion;

    if (["✨", "😊", "😎", "💖"].contains(emo)) return _SlimeExpression.greet;
    if (["🥺", "😢", "🥶"].contains(emo)) return _SlimeExpression.sad;
    if (["😡", "⚡", "⛈️"].contains(emo)) return _SlimeExpression.angry;
    if (["😴", "🌙"].contains(emo)) return _SlimeExpression.thinking;
    if (["🤔", "❓"].contains(emo)) return _SlimeExpression.confused;
    if (["😂", "🤣"].contains(emo)) return _SlimeExpression.laughing;

    return _SlimeExpression.neutral;
  }

  void _configurePhysics() {
    switch (_expression) {
      case _SlimeExpression.greet:
      case _SlimeExpression.laughing:
        _bounceHeight = 18;
        _bounceSpeed = 1.8;
        break;

      case _SlimeExpression.sad:
        _bounceHeight = 6;
        _bounceSpeed = 0.6;
        break;

      case _SlimeExpression.angry:
        _bounceHeight = 10;
        _bounceSpeed = 1.4;
        break;

      case _SlimeExpression.listening:
      case _SlimeExpression.thinking:
        _bounceHeight = 7;
        _bounceSpeed = 0.9;
        break;

      case _SlimeExpression.speaking:
        _bounceHeight = 12;
        _bounceSpeed = 1.4;
        break;

      case _SlimeExpression.confused:
        _bounceHeight = 9;
        _bounceSpeed = 1.2;
        break;

      default:
        _bounceHeight = 10;
        _bounceSpeed = 1.0;
    }

    _bounceHeight *= (0.7 + widget.moodWobble * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = sin(_controller.value * pi * 2);
        final wobbleBounce = -t * _bounceHeight;

        return Transform.translate(
          offset: Offset(0, wobbleBounce),
          child: CustomPaint(
            painter: _SlimePainter(
              color: widget.color,
              expression: _expression,
              voiceEnergy: widget.voiceEnergy,
              wobble: widget.moodWobble,
              bouncePhase: t,
            ),
            child: const SizedBox(width: 160, height: 160),
          ),
        );
      },
    );
  }
}

class _SlimePainter extends CustomPainter {
  final Color color;
  final _SlimeExpression expression;
  final double wobble;
  final double voiceEnergy;
  final double bouncePhase;

  _SlimePainter({
    required this.color,
    required this.expression,
    required this.wobble,
    required this.voiceEnergy,
    required this.bouncePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.55);

    // ----- SOMBRA -----
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.95),
        width: 110 - bouncePhase * 8,
        height: 26 - bouncePhase * 3,
      ),
      shadowPaint,
    );

    // ---------- ESCALA SUAVE ----------
    final scaleX = 1 + wobble * 0.15 + voiceEnergy * 0.10;
    final scaleY = 1 - wobble * 0.20 - voiceEnergy * 0.15;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scaleX, scaleY);

    // ---------- CUERPO (más redondo) ----------
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.95), color.withOpacity(0.60)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 80));

    final body = RRect.fromLTRBR(-75, -65, 75, 75, const Radius.circular(70));

    canvas.drawRRect(body, bodyPaint);

    // ---------- HIGHLIGHT ----------
    canvas.drawCircle(
      const Offset(-30, -40),
      55,
      Paint()
        ..shader =
            RadialGradient(
              colors: [Colors.white.withOpacity(0.65), Colors.transparent],
            ).createShader(
              Rect.fromCircle(center: const Offset(-30, -40), radius: 55),
            ),
    );

    // ---------- OJOS ----------
    _drawEyes(canvas);

    canvas.restore();
  }

  void _drawEyes(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final bodyWidth = 150.0;

    final leftX = -bodyWidth * 0.22;
    final rightX = bodyWidth * 0.22;

    final eyeY = -10 + (bouncePhase * 4) + (voiceEnergy * 4);

    Path left = Path();
    Path right = Path();

    switch (expression) {
      case _SlimeExpression.neutral:
        left.moveTo(leftX - 8, eyeY);
        left.lineTo(leftX + 8, eyeY);

        right.moveTo(rightX - 8, eyeY);
        right.lineTo(rightX + 8, eyeY);
        break;

      case _SlimeExpression.greet:
        left.moveTo(leftX - 8, eyeY - 3);
        left.lineTo(leftX, eyeY + 4);
        left.lineTo(leftX + 8, eyeY - 3);

        right.moveTo(rightX - 8, eyeY - 3);
        right.lineTo(rightX, eyeY + 4);
        right.lineTo(rightX + 8, eyeY - 3);
        break;

      case _SlimeExpression.listening:
        canvas.drawCircle(Offset(leftX, eyeY), 6, paint);
        canvas.drawCircle(Offset(rightX, eyeY), 6, paint);
        return;

      case _SlimeExpression.speaking:
        left.moveTo(leftX - 8, eyeY + 1);
        left.lineTo(leftX + 6, eyeY - 2);

        right.moveTo(rightX - 6, eyeY - 2);
        right.lineTo(rightX + 8, eyeY + 1);
        break;

      case _SlimeExpression.sad:
        left.moveTo(leftX - 7, eyeY + 3);
        left.lineTo(leftX + 7, eyeY - 2);

        right.moveTo(rightX - 7, eyeY - 2);
        right.lineTo(rightX + 7, eyeY + 3);
        break;

      case _SlimeExpression.thinking:
        left.moveTo(leftX - 8, eyeY + 1);
        left.lineTo(leftX + 8, eyeY - 1);

        right.moveTo(rightX - 8, eyeY - 1);
        right.lineTo(rightX + 8, eyeY + 1);
        break;

      case _SlimeExpression.confused:
        canvas.drawCircle(Offset(leftX, eyeY), 6, paint);

        right.moveTo(rightX - 8, eyeY);
        right.lineTo(rightX + 8, eyeY);
        break;

      case _SlimeExpression.angry:
        left.moveTo(leftX - 8, eyeY - 2);
        left.lineTo(leftX + 7, eyeY + 3);

        right.moveTo(rightX - 7, eyeY + 3);
        right.lineTo(rightX + 8, eyeY - 2);
        break;

      case _SlimeExpression.laughing:
        left.moveTo(leftX - 8, eyeY + 4);
        left.lineTo(leftX, eyeY - 3);
        left.lineTo(leftX + 8, eyeY + 4);

        right.moveTo(rightX - 8, eyeY + 4);
        right.lineTo(rightX, eyeY - 3);
        right.lineTo(rightX + 8, eyeY + 4);
        break;
    }

    canvas.drawPath(left, paint);
    canvas.drawPath(right, paint);
  }

  @override
  bool shouldRepaint(covariant _SlimePainter old) =>
      old.color != color ||
      old.expression != expression ||
      old.wobble != wobble ||
      old.voiceEnergy != voiceEnergy ||
      old.bouncePhase != bouncePhase;
}
