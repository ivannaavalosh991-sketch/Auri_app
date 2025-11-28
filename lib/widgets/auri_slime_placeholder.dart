import 'package:flutter/material.dart';

class AuriSlimePlaceholder extends StatefulWidget {
  final double mouthEnergy; // 0–1 (PCM → boca)
  final double wobble; // 0–1 (movimiento suave)
  final Color glowColor; // color base del mood

  const AuriSlimePlaceholder({
    super.key,
    this.mouthEnergy = 0.0,
    this.wobble = 0.5,
    this.glowColor = const Color(0xFFB57CFF),
  });

  @override
  State<AuriSlimePlaceholder> createState() => _AuriSlimePlaceholderState();
}

class _AuriSlimePlaceholderState extends State<AuriSlimePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    // Animación cardíaca del slime
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: 0.92,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Glow según energía de voz
    final glow = widget.mouthEnergy * 0.7;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Transform.scale(
          scale: _pulse.value + (widget.wobble * 0.05),
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.glowColor.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withOpacity(
                    0.35 + glow.clamp(0, 0.8),
                  ),
                  blurRadius: 40 + (glow * 55),
                  spreadRadius: 4 + (glow * 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 10 + (widget.mouthEnergy * 25),
                height: (10 + (widget.mouthEnergy * 25)) * 0.5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
