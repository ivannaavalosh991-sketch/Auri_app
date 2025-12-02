// lib/widgets/siri_voice_button.dart
// V5 — Push-to-Talk + Hands-Free aware

import 'package:flutter/material.dart';
import 'package:auri_app/auri/voice/voice_session_controller.dart';
import 'package:auri_app/auri/voice/stt_whisper_online.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

class SiriVoiceButton extends StatefulWidget {
  @override
  State<SiriVoiceButton> createState() => _SiriVoiceButtonState();
}

class _SiriVoiceButtonState extends State<SiriVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double amp = 0.0;
  bool _isHeld = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    STTWhisperOnline.instance.amplitude.addListener(() {
      if (mounted)
        setState(() => amp = STTWhisperOnline.instance.amplitude.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _handsFree => AuriRealtime.instance.handsFree;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        if (_handsFree) {
          // 🟣 HF activo → Tap desactiva HF
          await AuriRealtime.instance.setHandsFree(false);
          return;
        }
        // Push-to-Talk
        await VoiceSessionController.startRecording();
      },

      onLongPressStart: (_) async {
        if (_handsFree) return;
        _isHeld = true;
        await VoiceSessionController.startRecording();
      },

      onLongPressEnd: (_) async {
        if (_handsFree) return;
        if (_isHeld) {
          _isHeld = false;
          await VoiceSessionController.stopRecording();
        }
      },

      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;

          return SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                _ring(
                  amp,
                  1.15,
                  t,
                  _handsFree
                      ? Colors.greenAccent.withOpacity(0.35)
                      : cs.primary.withOpacity(0.30),
                ),
                _ring(amp, 0.95, t + 0.33, cs.primary.withOpacity(0.22)),
                _ring(amp, 0.80, t + 0.66, cs.primary.withOpacity(0.45)),

                // Main button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _handsFree
                            ? Colors.greenAccent.withOpacity(0.85)
                            : cs.primary.withOpacity(0.85),
                        _handsFree
                            ? Colors.greenAccent.withOpacity(0.45)
                            : cs.primary.withOpacity(0.40),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _handsFree
                            ? Colors.greenAccent.withOpacity(0.7)
                            : cs.primary.withOpacity(0.7),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _handsFree ? Icons.hearing : Icons.mic_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ring(double amp, double base, double anim, Color color) {
    return Transform.scale(
      scale: base + (amp * 0.45) + (anim * 0.05),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
