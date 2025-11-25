// lib/pages/survey/survey_screen.dart

import 'package:flutter/material.dart';
import 'controllers/survey_controller.dart';
import 'widgets/survey_section.dart';
import 'widgets/survey_text_field.dart';
import 'widgets/survey_multi_text_field.dart';
import 'widgets/survey_switch.dart';
import 'package:auri_app/pages/survey/widgets/survey_time_picker.dart';
import 'models/survey_models.dart';

class SurveyScreen extends StatefulWidget {
  final bool isInitialSetup;

  const SurveyScreen({super.key, required this.isInitialSetup});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyController controller = SurveyController();
  final PageController _pageController = PageController();
  int _page = 0;

  bool loading = true;

  final int totalPages = 5;

  // -------------------------------------------------------
  // PARSE TIME (para transformar "08:30" → TimeOfDay)
  // -------------------------------------------------------
  TimeOfDay _parseTime(String text) {
    try {
      final parts = text.split(":");
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await controller.load();
    setState(() => loading = false);
  }

  void _next() {
    if (_page < totalPages - 1) {
      _pageController.animateToPage(
        _page + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.animateToPage(
        _page - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save() async {
    await controller.save();
    if (!mounted) return;

    if (widget.isInitialSetup) {
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // PROGRESS BAR
  // -------------------------------------------------------
  Widget _buildProgress(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (_page + 1) / totalPages;

    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
          width: MediaQuery.of(context).size.width * progress,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primary.withOpacity(0.9),
                cs.primary.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: cs.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(context),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _pagePerfil(),
                  _pageRutina(),
                  _pagePagos(),
                  _pageCumples(),
                  _pagePreferencias(),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_page > 0)
              TextButton(
                onPressed: _back,
                child: const Text("Atrás", style: TextStyle(fontSize: 18)),
              )
            else
              const SizedBox(width: 70),

            ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                _page < totalPages - 1 ? "Siguiente" : "Finalizar",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // PÁGINAS DEL SURVEY
  // -------------------------------------------------------------

  Widget _pagePerfil() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurveySection(
          title: "Tu Perfil",
          children: [
            SurveyTextField(
              label: "¿Cómo te llamas?",
              controller: controller.name,
            ),
            SurveyTextField(
              label: "¿A qué te dedicas?",
              controller: controller.occupation,
            ),
            SurveyTextField(
              label: "¿En qué ciudad vives?",
              controller: controller.city,
            ),
          ],
        ),
      ],
    );
  }

  Widget _pageRutina() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurveySection(
          title: "Rutina Diaria",
          children: [
            // WAKE UP TIME
            Text(
              "¿A qué hora te despiertas?",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            AuriTimePicker(
              initialTime: _parseTime(controller.wakeUp.text),
              onChanged: (t) {
                controller.wakeUp.text =
                    "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
              },
            ),
            const SizedBox(height: 20),

            // SLEEP TIME
            Text("¿A qué hora duermes?", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            AuriTimePicker(
              initialTime: _parseTime(controller.sleep.text),
              onChanged: (t) {
                controller.sleep.text =
                    "${t.hour}:${t.minute.toString().padLeft(2, '0')}";
              },
            ),
            const SizedBox(height: 20),

            // CLASES
            SurveySwitch(
              text: "¿Tienes clases?",
              value: controller.hasClasses,
              onChanged: (v) => setState(() => controller.hasClasses = v),
            ),
            if (controller.hasClasses)
              SurveyMultiTextField(
                label: "Clases (una por línea)",
                controller: controller.classesInfo,
              ),

            // EXAMENES
            SurveySwitch(
              text: "¿Tienes exámenes?",
              value: controller.hasExams,
              onChanged: (v) => setState(() => controller.hasExams = v),
            ),
            if (controller.hasExams)
              SurveyMultiTextField(
                label: "Exámenes",
                controller: controller.examsInfo,
              ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // PAGOS (con suscripciones adicionales)
  // -------------------------------------------------------------
  Widget _pagePagos() {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurveySection(
          title: "Pagos Mensuales",
          children: [
            SurveySwitch(
              text: "¿Recordar pagos?",
              value: controller.wantsPaymentReminders,
              onChanged: (v) =>
                  setState(() => controller.wantsPaymentReminders = v),
            ),

            if (controller.wantsPaymentReminders) ...[
              const SizedBox(height: 10),

              SurveyTextField(
                label: "Pago del agua (día del mes)",
                controller: controller.waterPayment,
              ),
              SurveyTextField(
                label: "Pago de la luz (día del mes)",
                controller: controller.electricPayment,
              ),
              SurveyTextField(
                label: "Pago del internet (día del mes)",
                controller: controller.internetPayment,
              ),
              SurveyTextField(
                label: "Pago del teléfono (día del mes)",
                controller: controller.phonePayment,
              ),
              SurveyTextField(
                label: "Pago de la renta (día del mes)",
                controller: controller.rentPayment,
              ),

              const SizedBox(height: 20),
              const Text(
                "Pagos adicionales (suscripciones, gimnasio, etc.)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              if (controller.extraPayments.isEmpty)
                Text(
                  "Añade aquí servicios como Netflix, Crunchyroll, Spotify...",
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),

              ...controller.extraPayments.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item.name} – día ${item.day}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: cs.error),
                        onPressed: () {
                          setState(() {
                            controller.extraPayments.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _showAddExtraPaymentDialog,
                icon: const Icon(Icons.add),
                label: const Text("Añadir pago adicional"),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showAddExtraPaymentDialog() {
    final nameCtrl = TextEditingController();
    final dayCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Añadir pago adicional"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nombre (Ej: Netflix, gimnasio...)",
                ),
              ),
              TextField(
                controller: dayCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Día de cobro (1-31)",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final d = int.tryParse(dayCtrl.text) ?? 1;
                final day = d.clamp(1, 31);

                setState(() {
                  controller.extraPayments.add(
                    ExtraPaymentEntry(
                      name: nameCtrl.text.trim(),
                      day: day,
                      time: "09:00",
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // CUMPLEAÑOS (con DatePicker y lista dinámica)
  // -------------------------------------------------------------
  Widget _pageCumples() {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurveySection(
          title: "Cumpleaños",
          children: [
            const Text("Tu cumpleaños", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 6),

            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year - 100),
                  lastDate: DateTime(now.year + 1),
                );
                if (picked != null) {
                  setState(() {
                    controller.userBirthday.text =
                        "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}";
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withOpacity(0.6)),
                ),
                child: Text(
                  controller.userBirthday.text.isEmpty
                      ? "Selecciona tu fecha"
                      : controller.userBirthday.text,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SurveySwitch(
              text: "¿Tienes pareja?",
              value: controller.hasPartner,
              onChanged: (v) => setState(() => controller.hasPartner = v),
            ),

            if (controller.hasPartner) ...[
              const SizedBox(height: 6),
              const Text("Cumpleaños de tu pareja"),
              const SizedBox(height: 6),

              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(now.year - 100),
                    lastDate: DateTime(now.year + 1),
                  );
                  if (picked != null) {
                    setState(() {
                      controller.partnerBirthday.text =
                          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}";
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.primary.withOpacity(0.6)),
                  ),
                  child: Text(
                    controller.partnerBirthday.text.isEmpty
                        ? "Selecciona fecha"
                        : controller.partnerBirthday.text,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            SurveySwitch(
              text: "¿Recordar cumpleaños de más personas?",
              value: controller.wantsFriendBirthdays,
              onChanged: (v) =>
                  setState(() => controller.wantsFriendBirthdays = v),
            ),

            if (controller.wantsFriendBirthdays) ...[
              const SizedBox(height: 12),
              const Text(
                "Cumpleaños adicionales",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              if (controller.extraBirthdays.isEmpty)
                Text(
                  "Añade aquí familia, amigos, etc.",
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),

              ...controller.extraBirthdays.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${item.name} – ${item.day.toString().padLeft(2, '0')}/${item.month.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: cs.error),
                        onPressed: () {
                          setState(() {
                            controller.extraBirthdays.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                onPressed: _showAddBirthdayDialog,
                icon: const Icon(Icons.add),
                label: const Text("Añadir cumpleaños"),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showAddBirthdayDialog() {
    final nameCtrl = TextEditingController();
    DateTime? pickedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text("Añadir cumpleaños"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final d = await showDatePicker(
                        context: context,
                        initialDate: pickedDate ?? now,
                        firstDate: DateTime(now.year - 100),
                        lastDate: DateTime(now.year + 1),
                      );
                      if (d != null) {
                        setInnerState(() {
                          pickedDate = d;
                        });
                      }
                    },
                    child: Text(
                      pickedDate == null
                          ? "Seleccionar fecha"
                          : "${pickedDate!.day.toString().padLeft(2, '0')}/${pickedDate!.month.toString().padLeft(2, '0')}",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty || pickedDate == null) {
                      return;
                    }

                    setState(() {
                      controller.extraBirthdays.add(
                        ExtraBirthdayEntry(
                          name: nameCtrl.text.trim(),
                          day: pickedDate!.day,
                          month: pickedDate!.month,
                        ),
                      );
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _pagePreferencias() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SurveySection(
          title: "Preferencias",
          children: [
            SurveyTextField(
              label: "¿Cuánta anticipación prefieres?",
              controller: controller.reminderAdvance,
              hint: "Ej. 1 día antes",
            ),

            SurveySwitch(
              text: "¿Agenda semanal automática?",
              value: controller.wantsWeeklyAgenda,
              onChanged: (v) =>
                  setState(() => controller.wantsWeeklyAgenda = v),
            ),
          ],
        ),
      ],
    );
  }
}
