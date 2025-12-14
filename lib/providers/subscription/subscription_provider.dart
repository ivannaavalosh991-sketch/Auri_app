import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auri_app/services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionStatus? _status;
  bool _loading = false;

  SubscriptionStatus? get status => _status;
  bool get isLoading => _loading;

  bool get isFree => _status?.plan == "free";
  bool get isPro => _status?.plan == "pro";
  bool get isUltra => _status?.plan == "ultra";

  bool get isActive =>
      _status?.active == true &&
      (_status?.plan == "pro" || _status?.plan == "ultra");

  /// Obtiene el UID actual de Firebase
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Llamado al iniciar sesión y cuando entras a la app
  Future<void> loadStatus() async {
    if (_uid == null) return;

    _loading = true;
    notifyListeners();

    final result = await SubscriptionService.getStatus(_uid!);

    _status = result;
    _loading = false;

    notifyListeners();
  }

  /// Refrescar manualmente (por ejemplo después del checkout)
  Future<void> refresh() async {
    await loadStatus();
  }
}
