import 'package:flutter/material.dart';
import 'package:auri_app/routes/app_routes.dart';

class UpgradeButton extends StatelessWidget {
  final bool isPro;
  final VoidCallback onTap;

  const UpgradeButton({super.key, required this.isPro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isPro) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.orange.withOpacity(0.45), blurRadius: 12),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star, color: Colors.black),
            SizedBox(width: 8),
            Text(
              "Hazte PRO",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
