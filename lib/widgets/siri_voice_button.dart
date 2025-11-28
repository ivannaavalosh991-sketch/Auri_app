// lib/widgets/siri_voice_button.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auri_app/auri/voice/voice_session_controller.dart';
import 'package:auri_app/auri/voice/stt_whisper_online.dart';

class SiriVoiceButton extends StatefulWidget {
  @override
  State<SiriVoiceButton> createState() => _SiriVoiceButtonState();
}

class _SiriVoiceButtonState extends State<SiriVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double amp = 0.0;
  int _tapCount = 0;
  bool _isHeld = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    /// 🔮 Escuchar amplitud sin timers → ultra responsive
    STTWhisperOnline.instance.amplitude.addListener(() {
      setState(() => amp = STTWhisperOnline.instance.amplitude.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        _tapCount++;
        Future.delayed(const Duration(milliseconds: 250), () {
          if (_tapCount >= 2) {
            VoiceSessionController.cancel();
          } else {
            VoiceSessionController.startRecording();
          }
          _tapCount = 0;
        });
      },

      onLongPressStart: (_) async {
        _isHeld = true;
        await VoiceSessionController.startRecording();
      },

      onLongPressEnd: (_) async {
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
                _wave(amp, 1.10, t, cs.primary.withOpacity(0.20)),
                _wave(amp, 0.95, t + 0.33, cs.primary.withOpacity(0.30)),
                _wave(amp, 0.80, t + 0.66, cs.primary.withOpacity(0.55)),

                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primary.withOpacity(0.85),
                        cs.primary.withOpacity(0.40),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.7),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
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

  Widget _wave(double amp, double base, double anim, Color color) {
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
