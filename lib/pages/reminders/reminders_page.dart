// lib/pages/reminders/reminders_page.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:auri_app/controllers/reminder/reminder_controller.dart';
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/models/reminder_model.dart';
import 'package:auri_app/services/notification_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _uuid = const Uuid();
  List<ReminderHive> reminders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ReminderController.getAll();
    setState(() {
      reminders = list;
      loading = false;
    });
  }

  // -------------------------------------------------------------
  //   COLORES SEGÚN CATEGORÍA
  // -------------------------------------------------------------
  Color _color(ReminderHive r) {
    if (r.tag == "payment") return const Color(0xFF4A90E2);
    if (r.tag == "birthday") return const Color(0xFFAC6CFF);
    if (r.isAuto) return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  IconData _icon(ReminderHive r) {
    if (r.tag == "payment") return Icons.receipt_long;
    if (r.tag == "birthday") return Icons.cake;
    if (r.isAuto) return Icons.auto_awesome;
    return Icons.alarm;
  }

  // -------------------------------------------------------------
  //   AGRUPAR POR FECHA
  // -------------------------------------------------------------
  Map<String, List<ReminderHive>> _groupByDate() {
    final out = <String, List<ReminderHive>>{};

    for (final r in reminders) {
      final d = DateTime.parse(r.dateIso);
      final key = "${d.year}-${d.month}-${d.day}";

      out.putIfAbsent(key, () => []);
      out[key]!.add(r);
    }

    return out;
  }

  // -------------------------------------------------------------
  //   NUEVO RECORDATORIO MANUAL
  // -------------------------------------------------------------
  void _showAddReminderModal() {
    final titleCtrl = TextEditingController();
    DateTime selected = DateTime.now().add(const Duration(minutes: 5));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Nuevo Recordatorio",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Título",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (_, setStateModal) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${selected.day.toString().padLeft(2, '0')}/"
                          "${selected.month.toString().padLeft(2, '0')} "
                          "${selected.hour.toString().padLeft(2, '0')}:"
                          "${selected.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: selected,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );

                          if (d != null) {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selected),
                            );

                            if (t != null) {
                              setStateModal(() {
                                selected = DateTime(
                                  d.year,
                                  d.month,
                                  d.day,
                                  t.hour,
                                  t.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text("Fecha"),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: const Text("Guardar"),
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;

                    final id = _uuid.v4();

                    final hiveReminder = ReminderHive(
                      id: id,
                      title: titleCtrl.text.trim(),
                      dateIso: selected.toIso8601String(),
                      repeats: "once",
                      tag: "",
                      isAuto: false,
                      jsonPayload: "{}",
                    );

                    // 1) Guardar en Hive
                    await ReminderController.save(hiveReminder);

                    // 2) Programar notificación
                    final reminder = Reminder(
                      id: id,
                      title: hiveReminder.title,
                      description: "",
                      dateTime: selected,
                    );
                    await NotificationService().scheduleReminder(reminder);

                    if (mounted) {
                      Navigator.pop(context);
                      _load();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  //   DELETE
  // -------------------------------------------------------------
  void _delete(ReminderHive r) async {
    // 1) Cancelar notificación asociada
    await NotificationService().cancelByStringId(r.id);

    // 2) Borrar de Hive
    await ReminderController.delete(r.id);
    _load();
  }

  // -------------------------------------------------------------
  //   UI FINAL
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final grouped = _groupByDate();
    final keys = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(title: const Text("Recordatorios"), elevation: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderModal,
        child: const Icon(Icons.add),
      ),
      body: reminders.isEmpty
          ? const Center(
              child: Text(
                "No tienes recordatorios todavía ✨",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: keys.length,
              itemBuilder: (_, i) {
                final key = keys[i];
                final items = grouped[key]!;
                final d = DateTime.parse(items.first.dateIso);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "${d.day}/${d.month}/${d.year}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    ...items.map((r) {
                      final color = _color(r);
                      final icon = _icon(r);
                      final date = DateTime.parse(r.dateIso);

                      return Dismissible(
                        key: Key(r.id),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(r),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              child: Icon(icon, color: Colors.white),
                            ),
                            title: Text(
                              r.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "${date.hour.toString().padLeft(2, '0')}:"
                              "${date.minute.toString().padLeft(2, '0')}",
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
