// lib/auri/ui/jarvis_hud.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

class AuriJarvisHud extends StatefulWidget {
  final ValueChanged<double>? onLipSync;

  const AuriJarvisHud({super.key, this.onLipSync});

  @override
  State<AuriJarvisHud> createState() => _AuriJarvisHudState();
}

class _AuriJarvisHudState extends State<AuriJarvisHud> {
  String _thinkingText = "";
  bool _thinking = false;
  double _energy = 0.0;

  // 🟣 Throttle controller
  Timer? _throttleTimer;
  String _pendingText = "";
  double _pendingEnergy = 0.0;
  bool _pendingThinking = false;

  @override
  void initState() {
    super.initState();

    final rt = AuriRealtime.instance;

    // ---------------------------------------
    rt.addOnPartial((txt) {
      _pendingText = txt;
      _pendingThinking = true;
      _scheduleRebuild();
    });

    rt.addOnThinking((state) {
      _pendingThinking = state;
      if (!state) _pendingText = "";
      _scheduleRebuild();
    });

    rt.addOnLip((e) {
      _pendingEnergy = e;
      _scheduleRebuild();
      widget.onLipSync?.call(e);
    });
  }

  // 🟣 15 FPS throttle
  void _scheduleRebuild() {
    if (_throttleTimer != null && _throttleTimer!.isActive) return;

    _throttleTimer = Timer(const Duration(milliseconds: 66), () {
      if (!mounted) return;

      setState(() {
        _thinkingText = _pendingText;
        _thinking = _pendingThinking;
        _energy = _pendingEnergy;
      });
    });
  }

  Timer? _hudThrottle;

  void _scheduleHudUpdate() {
    if (_hudThrottle?.isActive ?? false) return;

    _hudThrottle = Timer(const Duration(milliseconds: 66), () {
      if (!mounted) return;
      setState(() {
        _thinking = _pendingThinking;
        _thinkingText = _pendingText;
        _energy = _pendingEnergy;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _thinking ? 1.0 : 0.7,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.35 + _energy * 0.3),
              blurRadius: 22 + (_energy * 18),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _thinking ? Icons.sync : Icons.bolt,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _thinking ? "Pensando..." : "Listo ✨",
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),

                // Energy bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: cs.primary.withOpacity(0.18),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (_energy.clamp(0.05, 1.0)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_thinkingText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _thinkingText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface.withOpacity(0.8),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
