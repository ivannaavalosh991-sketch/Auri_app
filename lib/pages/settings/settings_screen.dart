import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import 'package:auri_app/routes/app_routes.dart';
import 'package:auri_app/services/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<String> _getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auri_plan') ?? 'free';
  }

  Future<void> _reset(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (Hive.isBoxOpen('reminders')) {
      await Hive.box('reminders').clear();
    }

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración")),
      body: ListView(
        children: [
          FutureBuilder<String>(
            future: _getPlan(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final plan = snap.data!;

              return Column(
                children: [
                  if (plan == 'free')
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text("Hazte PRO"),
                      subtitle: const Text("Desbloquea funciones premium"),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.subscription),
                    ),
                  if (plan != 'free')
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text("Administrar suscripción"),
                      subtitle: Text("Plan actual: ${plan.toUpperCase()}"),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.subscription),
                    ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Editar mi información"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.survey),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Reiniciar configuración"),
            subtitle: const Text("Borrar todos tus datos"),
            onTap: () => _reset(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () async => AuthService.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
