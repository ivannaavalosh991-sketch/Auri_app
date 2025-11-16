import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Necesario para codificar/decodificar JSON
import '../models/reminder_model.dart'; // Importamos el modelo
import '../main.dart'; // Importamos la instancia de notificationService

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // --- LÓGICA DE PERSISTENCIA ---

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('remindersList');

    if (remindersJson != null) {
      setState(() {
        _reminders = remindersJson.map((jsonString) {
          return Reminder.fromJson(json.decode(jsonString));
        }).toList();

        _reminders
            .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
            .forEach(
              (r) => notificationService.scheduleReminderNotification(r),
            );
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders
        .map((r) => json.encode(r.toJson()))
        .toList();
    await prefs.setStringList('remindersList', remindersJson);
  }

  void _addReminder(Reminder newReminder) {
    setState(() {
      _reminders.add(newReminder);
    });
    notificationService.scheduleReminderNotification(newReminder);
    _saveReminders();
  }

  void _toggleReminderCompletion(Reminder reminder) {
    setState(() {
      reminder.isCompleted = !reminder.isCompleted;

      if (reminder.isCompleted) {
        notificationService.cancelReminderNotification(reminder);
      } else {
        if (reminder.dateTime.isAfter(DateTime.now())) {
          notificationService.scheduleReminderNotification(reminder);
        }
      }

      _reminders.sort((a, b) {
        if (a.isCompleted && !b.isCompleted) return 1;
        if (!a.isCompleted && b.isCompleted) return -1;
        return a.dateTime.compareTo(b.dateTime);
      });
    });
    _saveReminders();
  }

  void _deleteReminder(Reminder reminder) {
    notificationService.cancelReminderNotification(reminder);

    setState(() {
      _reminders.removeWhere((r) => r.id == reminder.id);
    });
    _saveReminders();
  }

  // --- AGREGAR RECORDATORIO MODAL ---

  void _showAddReminderModal() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(minutes: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Nuevo Recordatorio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Título del Recordatorio',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fecha/Hora: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day} '
                          '${selectedDate.hour}:${selectedDate.minute.toString().padLeft(2, '0')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (time != null) {
                              setModalState(() {
                                selectedDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        selectedDate.isAfter(DateTime.now())) {
                      final newReminder = Reminder(
                        id: UniqueKey().toString(),
                        title: titleController.text,
                        dateTime: selectedDate,
                      );
                      _addReminder(newReminder);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar Recordatorio'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final formattedDate =
        '${reminder.dateTime.hour}:${reminder.dateTime.minute.toString().padLeft(2, '0')} - ${reminder.dateTime.day}/${reminder.dateTime.month}';

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteReminder(reminder),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        color: reminder.isCompleted
            ? Colors.grey.withOpacity(0.2)
            : (reminder.dateTime.isBefore(DateTime.now())
                  ? Colors.red.withOpacity(0.1)
                  : null),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: IconButton(
            icon: Icon(
              reminder.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: reminder.isCompleted ? Colors.tealAccent : Colors.white,
            ),
            onPressed: () => _toggleReminderCompletion(reminder),
          ),
          title: Text(
            reminder.title,
            style: TextStyle(
              decoration: reminder.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
              color: reminder.isCompleted ? Colors.white54 : Colors.white,
            ),
          ),
          subtitle: Text(
            formattedDate,
            style: TextStyle(
              color: reminder.isCompleted
                  ? Colors.white38
                  : Colors.purpleAccent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios de Auri')),
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_add, size: 80, color: Colors.white54),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Sin recordatorios! Toca el "+" para empezar.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  // 🔔 BOTÓN DE PRUEBA DE NOTIFICACIÓN
                  ElevatedButton(
                    onPressed: () async {
                      await notificationService.flutterLocalNotificationsPlugin
                          .show(
                            99,
                            "Prueba instantánea",
                            "Si ves esto, Auri ya puede notificar",
                            notificationService.notificationDetails(),
                          );
                    },
                    child: const Text("🔔 Probar notificación ahora"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderTile(_reminders[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
