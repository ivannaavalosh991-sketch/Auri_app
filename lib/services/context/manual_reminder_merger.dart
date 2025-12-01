import 'package:auri_app/services/context/context_models.dart';
import 'package:auri_app/services/context/manual_reminder_classifier.dart';
import 'package:auri_app/pages/survey/models/survey_models.dart';

List<AuriContextEvent> mergeAllEvents({
  required List<ExpandedReminder> manual,
  required List<AuriContextEvent> autoEvents,
  required SurveyData? survey,
}) {
  final out = <AuriContextEvent>[];

  // ---------------------------
  // 1) AUTO EVENTS
  // ---------------------------
  out.addAll(autoEvents);

  // ---------------------------
  // 2) MANUAL EXPANDED
  // ---------------------------
  for (final m in manual) {
    out.add(
      AuriContextEvent(
        title: m.base.title,
        urgent: false,
        when: m.date.toIso8601String(),
      ),
    );
  }

  // ---------------------------
  // 3) SURVEY → birthday events
  // ---------------------------
  if (survey != null) {
    final now = DateTime.now();
    for (final b in survey.birthdays) {
      DateTime next = DateTime(now.year, b.month, b.day, 9);
      if (next.isBefore(now)) {
        next = DateTime(now.year + 1, b.month, b.day, 9);
      }

      out.add(
        AuriContextEvent(
          title: "Cumpleaños de ${b.name}",
          urgent: false,
          when: next.toIso8601String(),
        ),
      );
    }
  }

  // ---------------------------
  // 4) DEDUPE POR title + fecha
  // ---------------------------
  final dedup = <String, AuriContextEvent>{};

  for (final e in out) {
    final key = "${e.title}_${e.when}";
    dedup[key] = e;
  }

  final deduped = dedup.values.toList();

  // ---------------------------
  // 5) ORDEN FINAL
  // ---------------------------
  deduped.sort((a, b) {
    final da = DateTime.tryParse(a.when) ?? DateTime(2100);
    final db = DateTime.tryParse(b.when) ?? DateTime(2100);
    return da.compareTo(db);
  });

  return deduped;
}
