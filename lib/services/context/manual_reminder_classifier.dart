import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/pages/survey/models/survey_models.dart';

enum ManualCategory { payment, birthday, general }

class ExpandedReminder {
  final ReminderHive base;
  final DateTime date;
  final ManualCategory category;

  ExpandedReminder({
    required this.base,
    required this.date,
    required this.category,
  });
}

ManualCategory classifyManualReminder(ReminderHive r, SurveyData? survey) {
  final title = r.title.toLowerCase().trim();

  // 1) Si tiene tag directo → respetarlo
  if (r.tag == "payment") return ManualCategory.payment;
  if (r.tag == "birthday") return ManualCategory.birthday;

  // 2) Intento exacto con survey payments
  if (survey != null) {
    for (final p in [...survey.basicPayments, ...survey.extraPayments]) {
      final name = p.name.toLowerCase();
      if (title.contains(name)) {
        return ManualCategory.payment;
      }
    }
  }

  // 3) Detectar cumpleaños
  if (title.contains("cumple")) {
    return ManualCategory.birthday;
  }

  // 4) Detectar pagos pero NO clasificarlos como “payment” si no coinciden
  if (title.startsWith("pago ") || title.startsWith("pagar ")) {
    return ManualCategory.general;
  }

  return ManualCategory.general;
}

List<ExpandedReminder> expandReminder(ReminderHive r, SurveyData? survey) {
  final parsed = DateTime.tryParse(r.dateIso);
  if (parsed == null) return [];

  return [
    ExpandedReminder(
      base: r,
      date: parsed,
      category: classifyManualReminder(r, survey),
    ),
  ];
}
