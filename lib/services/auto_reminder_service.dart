import 'dart:convert';
import 'package:auri_app/models/reminder_model.dart';
import 'package:auri_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NO declaramos 'notificationService' aquí.
// En su lugar, lo recibiremos en el constructor.

class AutoReminderService {
  // <- CAMBIO: Añadido campo para guardar el servicio
  final NotificationService _notificationService;

  // <- CAMBIO: Añadido constructor para recibir el servicio
  AutoReminderService(this._notificationService);

  ///
  /// Lee los datos de la encuesta desde SharedPreferences
  /// y genera una lista inicial de recordatorios.
  ///
  Future<void> generateAutoReminders() async {
    final prefs = await SharedPreferences.getInstance();
    List<Reminder> autoReminders = [];

    // --- 1. Generar Recordatorios de Pagos ---
    if (prefs.getBool('userWantsPaymentReminders') ?? false) {
      autoReminders.addAll(_createPaymentReminders(prefs));
    }

    // --- 2. Generar Recordatorios de Clases y Rutina ---
    if (prefs.getBool('userHasClasses') ?? false) {
      final classInfo = prefs.getString('userClassesInfo') ?? '';
      if (classInfo.isNotEmpty) {
        // <- CAMBIO: Título más descriptivo
        autoReminders.add(_createSimpleReminder(title: 'Clases: $classInfo'));
      }
    }

    if (prefs.getBool('userHasExams') ?? false) {
      final examInfo = prefs.getString('userExamsInfo') ?? '';
      if (examInfo.isNotEmpty) {
        // <- CAMBIO: Título más descriptivo
        autoReminders.add(_createSimpleReminder(title: 'Exámenes: $examInfo'));
      }
    }

    // --- 3. Generar Recordatorios de Cumpleaños ---
    final partnerBirthday = prefs.getString('userPartnerBirthday') ?? '';
    if (partnerBirthday.isNotEmpty) {
      // <- CAMBIO: Título más descriptivo
      autoReminders.add(
        _createSimpleReminder(title: 'Cumpleaños Pareja: $partnerBirthday'),
      );
    }

    final familyBirthdays = prefs.getString('userFamilyBirthdays') ?? '';
    if (familyBirthdays.isNotEmpty) {
      // <- CAMBIO: Título más descriptivo
      autoReminders.add(
        _createSimpleReminder(title: 'Cumpleaños Familia: $familyBirthdays'),
      );
    }

    final friendBirthdays = prefs.getString('userFriendBirthdays') ?? '';
    if (friendBirthdays.isNotEmpty) {
      // <- CAMBIO: Título más descriptivo
      autoReminders.add(
        _createSimpleReminder(title: 'Cumpleaños Amigos: $friendBirthdays'),
      );
    }

    // --- 4. Guardar y Programar los Recordatorios ---
    if (autoReminders.isNotEmpty) {
      await _saveAndScheduleReminders(autoReminders);
    }
  }

  /// Función auxiliar para crear recordatorios de pago
  List<Reminder> _createPaymentReminders(SharedPreferences prefs) {
    List<Reminder> reminders = [];
    final payments = {
      'Pago de Agua': prefs.getString('userWaterPayment'),
      'Pago de Luz': prefs.getString('userElectricPayment'),
      'Pago de Internet': prefs.getString('userInternetPayment'),
      'Pago de Teléfono': prefs.getString('userPhonePayment'),
      'Pago de Renta/Vivienda': prefs.getString('userRentPayment'),
      'Pago de Tarjeta de Crédito': prefs.getString('userCreditCardPayment'),
      'Otros Pagos/Suscripciones': prefs.getString('userOtherPayments'),
    };

    payments.forEach((title, dateInfo) {
      if (dateInfo != null && dateInfo.isNotEmpty) {
        // <- CAMBIO: Combinamos el título y la info
        reminders.add(
          _createSimpleReminder(title: '$title (Fecha: $dateInfo)'),
        );
      }
    });
    return reminders;
  }

  /// Crea un recordatorio simple con una fecha genérica (ej. 7 días desde hoy).
  // <- CAMBIO: Eliminado el parámetro 'description'
  Reminder _createSimpleReminder({required String title}) {
    final reminderTime = DateTime.now().add(const Duration(days: 7));

    return Reminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID único
      title: title, // La descripción ahora es parte del título
      dateTime: reminderTime,
      isCompleted: false,
      // <- CAMBIO: Eliminada la línea 'description: description'
    );
  }

  /// Guarda la lista de recordatorios en SharedPreferences y
  /// le pide al NotificationService que programe las notificaciones.
  Future<void> _saveAndScheduleReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();

    final List<Map<String, dynamic>> jsonList = reminders
        .map((r) => r.toJson())
        .toList();
    //await prefs.setString('reminders', json.encode(jsonList));

    // Volvemos a programar todas las notificaciones
    // <- CAMBIO: Usamos la instancia inyectada '_notificationService'
    await _notificationService.cancelAllNotifications();
    for (var reminder in reminders) {
      await _notificationService.scheduleReminderNotification(reminder);
    }
  }
}
