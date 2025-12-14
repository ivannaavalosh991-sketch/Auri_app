import 'package:flutter/material.dart';
import 'package:auri_app/routes/app_routes.dart';

class ManageSubscriptionButton extends StatelessWidget {
  final String planLabel; // "FREE" | "PRO" | "ULTRA"
  final VoidCallback onTap;

  const ManageSubscriptionButton({
    super.key,
    required this.planLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts, color: cs.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Administrar suscripción",
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Plan actual: $planLabel",
                  style: TextStyle(
                    color: cs.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
