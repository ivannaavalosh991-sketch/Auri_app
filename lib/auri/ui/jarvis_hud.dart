import 'package:flutter/material.dart';
import 'package:auri_app/services/realtime/auri_realtime.dart';

class AuriJarvisHud extends StatefulWidget {
  final String ip;

  /// Callback opcional para enviar la energía de la boca (0–1) al HomeScreen
  final ValueChanged<double>? onLipSync;

  const AuriJarvisHud({super.key, required this.ip, this.onLipSync});

  @override
  State<AuriJarvisHud> createState() => _AuriJarvisHudState();
}

class _AuriJarvisHudState extends State<AuriJarvisHud> {
  String _thinkingText = "";
  bool _thinking = false;
  double _energy = 0.0;

  @override
  void initState() {
    super.initState();

    final rt = AuriRealtime.instance;

    // ---------------------------------------
    // PARTIAL → texto mientras piensa
    // ---------------------------------------
    rt.addOnPartial((txt) {
      setState(() {
        _thinkingText = txt;
        _thinking = true;
      });
    });

    // ---------------------------------------
    // THINKING → estado del cerebro
    // ---------------------------------------
    rt.addOnThinking((state) {
      setState(() {
        _thinking = state;
        if (!state) _thinkingText = "";
      });
    });

    // ---------------------------------------
    // LIP SYNC → energía de la boca
    // ---------------------------------------
    rt.addOnLip((e) {
      setState(() => _energy = e);
      widget.onLipSync?.call(e);
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

                // Energía de voz
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
