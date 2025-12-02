// lib/auri/ui/jarvis_hud.dart
// V5 — HUD inteligente con Hands-Free toggle + LipSync + Thinking

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

  Timer? _throttle;
  String _pendingText = "";
  double _pendingEnergy = 0.0;
  bool _pendingThinking = false;

  bool _handsFree = false;

  @override
  void initState() {
    super.initState();

    final rt = AuriRealtime.instance;

    _handsFree = rt.handsFree;

    rt.addOnPartial((txt) {
      _pendingText = txt;
      _pendingThinking = true;
      _schedule();
    });

    rt.addOnThinking((state) {
      _pendingThinking = state;
      if (!state) _pendingText = "";
      _schedule();
    });

    rt.addOnLip((e) {
      _pendingEnergy = e;
      widget.onLipSync?.call(e);
      _schedule();
    });
  }

  void _schedule() {
    if (_throttle?.isActive ?? false) return;

    _throttle = Timer(const Duration(milliseconds: 66), () {
      if (!mounted) return;
      setState(() {
        _thinkingText = _pendingText;
        _thinking = _pendingThinking;
        _energy = _pendingEnergy;
        _handsFree = AuriRealtime.instance.handsFree;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _thinking ? 1.0 : 0.8,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.3 + _energy * 0.35),
              blurRadius: 20 + (_energy * 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
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

                // 🟣 BOTÓN HANDS-FREE
                GestureDetector(
                  onTap: () async {
                    final val = !AuriRealtime.instance.handsFree;
                    await AuriRealtime.instance.setHandsFree(val);
                    setState(() => _handsFree = val);
                  },
                  child: Icon(
                    _handsFree ? Icons.hearing : Icons.hearing_disabled,
                    color: _handsFree
                        ? cs.primary
                        : cs.onSurface.withOpacity(0.4),
                    size: 20,
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
                  color: cs.onSurface.withOpacity(0.75),
                  fontSize: 12,
                  height: 1.22,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
