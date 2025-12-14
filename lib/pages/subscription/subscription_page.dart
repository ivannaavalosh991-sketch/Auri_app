// lib/pages/subscription/subscription_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auri_app/widgets/subscription/plan_card.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'free';

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();
  }

  Future<void> _loadSavedPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('auri_plan') ?? 'free';
    setState(() => _selectedPlan = saved);
  }

  Future<void> _applyPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auri_plan', _selectedPlan);

    debugPrint("✅ PLAN GUARDADO Y DEVUELTO: $_selectedPlan");

    if (!mounted) return;

    // 🔥 DEVOLVEMOS EL PLAN AL HOME
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mi Suscripción")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            PlanCard(
              title: "FREE",
              price: "Gratis",
              features: const [
                "Funciones básicas",
                "Recordatorios",
                "Clima y agenda",
              ],
              selected: _selectedPlan == 'free',
              onTap: () => setState(() => _selectedPlan = 'free'),
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            PlanCard(
              title: "PRO ⭐",
              price: "\$4.99 / mes",
              features: const [
                "Voz avanzada",
                "Respuestas largas",
                "Mejor memoria",
              ],
              selected: _selectedPlan == 'pro',
              onTap: () => setState(() => _selectedPlan = 'pro'),
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            PlanCard(
              title: "ULTRA 🚀",
              price: "\$9.99 / mes",
              features: const [
                "Voz personalizada",
                "Modelos premium",
                "Funciones experimentales",
              ],
              selected: _selectedPlan == 'ultra',
              onTap: () => setState(() => _selectedPlan = 'ultra'),
              color: Colors.deepPurpleAccent,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _applyPlan,
              child: const Text("Aplicar plan"),
            ),
          ],
        ),
      ),
    );
  }
}
