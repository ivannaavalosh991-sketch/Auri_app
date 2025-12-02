// lib/pages/reminders/reminders_page.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:auri_app/controllers/reminder/reminder_controller.dart';
import 'package:auri_app/models/reminder_hive.dart';
import 'package:auri_app/models/reminder_model.dart';
import 'package:auri_app/services/notification_service.dart';

enum ReminderFilter { all, payments, birthdays, manual, auto }

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _uuid = const Uuid();
  List<ReminderHive> reminders = [];
  bool loading = true;

  ReminderFilter _filter = ReminderFilter.all;

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
  //   FILTROS
  // -------------------------------------------------------------
  bool _matchesFilter(ReminderHive r) {
    switch (_filter) {
      case ReminderFilter.all:
        return true;
      case ReminderFilter.payments:
        return r.tag == "payment";
      case ReminderFilter.birthdays:
        return r.tag == "birthday";
      case ReminderFilter.manual:
        return !r.isAuto;
      case ReminderFilter.auto:
        return r.isAuto;
    }
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

  String _categoryLabel(ReminderHive r) {
    if (r.tag == "payment") return "Pago";
    if (r.tag == "birthday") return "Cumpleaños";
    if (r.isAuto) return "Auto";
    return "Manual";
  }

  // -------------------------------------------------------------
  //   AGRUPAR POR FECHA (ya filtrados)
  // -------------------------------------------------------------
  Map<String, List<ReminderHive>> _groupByDate() {
    final out = <String, List<ReminderHive>>{};

    for (final r in reminders.where(_matchesFilter)) {
      final d = DateTime.parse(r.dateIso);
      final key =
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

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

    _showReminderModal(
      title: "Nuevo recordatorio",
      titleController: titleCtrl,
      initialDate: selected,
      onConfirm: (newTitle, newDate) async {
        final id = _uuid.v4();

        final hiveReminder = ReminderHive(
          id: id,
          title: newTitle,
          dateIso: newDate.toIso8601String(),
          repeats: "once",
          tag: "",
          isAuto: false,
          jsonPayload: "{}",
        );

        await ReminderController.save(hiveReminder);

        final reminder = Reminder(
          id: id,
          title: hiveReminder.title,
          description: "",
          dateTime: newDate,
        );
        await NotificationService().scheduleReminder(reminder);

        if (mounted) {
          Navigator.pop(context);
          _load();
        }
      },
    );
  }

  // -------------------------------------------------------------
  //   EDITAR RECORDATORIO
  // -------------------------------------------------------------
  void _showEditReminderModal(ReminderHive r) {
    final titleCtrl = TextEditingController(text: r.title);
    final initialDate =
        DateTime.tryParse(r.dateIso) ??
        DateTime.now().add(const Duration(minutes: 5));

    _showReminderModal(
      title: "Editar recordatorio",
      titleController: titleCtrl,
      initialDate: initialDate,
      onConfirm: (newTitle, newDate) async {
        // Cancelar notificación previa
        await NotificationService().cancelByStringId(r.id);

        // Guardar actualizado
        final updated = ReminderHive(
          id: r.id,
          title: newTitle,
          dateIso: newDate.toIso8601String(),
          repeats: r.repeats,
          tag: r.tag,
          isAuto: r.isAuto,
          jsonPayload: r.jsonPayload,
        );

        await ReminderController.save(updated);

        final reminder = Reminder(
          id: updated.id,
          title: updated.title,
          description: "",
          dateTime: newDate,
        );
        await NotificationService().scheduleReminder(reminder);

        if (mounted) {
          Navigator.pop(context);
          _load();
        }
      },
    );
  }

  // -------------------------------------------------------------
  //   MODAL REUTILIZABLE (CREAR / EDITAR)
  // -------------------------------------------------------------
  void _showReminderModal({
    required String title,
    required TextEditingController titleController,
    required DateTime initialDate,
    required Future<void> Function(String title, DateTime date) onConfirm,
  }) {
    DateTime selected = initialDate;

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
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Título",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
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
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: const Text("Guardar"),
                      onPressed: () async {
                        final txt = titleController.text.trim();
                        if (txt.isEmpty) return;

                        await onConfirm(txt, selected);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  //   DELETE
  // -------------------------------------------------------------
  void _delete(ReminderHive r) async {
    await NotificationService().cancelByStringId(r.id);
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
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFiltersRow(cs),
          const SizedBox(height: 8),
          Expanded(
            child: reminders.isEmpty
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
                              "${d.day.toString().padLeft(2, '0')}/"
                              "${d.month.toString().padLeft(2, '0')}/"
                              "${d.year}",
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
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _delete(r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: color.withOpacity(0.4),
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _showEditReminderModal(r),
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
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        "${date.hour.toString().padLeft(2, '0')}:"
                                        "${date.minute.toString().padLeft(2, '0')}",
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.22),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _categoryLabel(r),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                color.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  //   FILTROS UI (Chips)
  // -------------------------------------------------------------
  Widget _buildFiltersRow(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip("Todos", ReminderFilter.all, cs),
          _buildFilterChip("Pagos", ReminderFilter.payments, cs),
          _buildFilterChip("Cumpleaños", ReminderFilter.birthdays, cs),
          _buildFilterChip("Manual", ReminderFilter.manual, cs),
          _buildFilterChip("Auto", ReminderFilter.auto, cs),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReminderFilter f, ColorScheme cs) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filter = f;
          });
        },
        selectedColor: cs.primary.withOpacity(0.25),
        labelStyle: TextStyle(color: selected ? cs.primary : cs.onSurface),
      ),
    );
  }
}
