import 'package:flutter/material.dart';

class AuriTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onChanged;

  const AuriTimePicker({
    super.key,
    required this.initialTime,
    required this.onChanged,
  });

  @override
  State<AuriTimePicker> createState() => _AuriTimePickerState();
}

class _AuriTimePickerState extends State<AuriTimePicker>
    with SingleTickerProviderStateMixin {
  late TimeOfDay _selected;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTime;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.95,
      upperBound: 1.0,
    );

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    _controller.forward();
  }

  void _tapBounce() {
    _controller.reverse().then((_) => _controller.forward());
  }

  void _updateHour(int h) {
    _tapBounce();
    setState(() {
      _selected = TimeOfDay(hour: h, minute: _selected.minute);
    });
    widget.onChanged(_selected);
  }

  void _updateMinute(int m) {
    _tapBounce();
    setState(() {
      _selected = TimeOfDay(hour: _selected.hour, minute: m);
    });
    widget.onChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    const blobColor = Color(0xFF8A4FFF);

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: blobColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: blobColor.withOpacity(0.45),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
          border: Border.all(color: blobColor.withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          children: [
            const Text(
              "Selecciona la hora",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            // FILA DE PICKERS BLANDITOS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBlobWheel(
                  label: "Hora",
                  values: List.generate(24, (i) => i),
                  selected: _selected.hour,
                  onSelect: _updateHour,
                ),
                const SizedBox(width: 25),
                _buildBlobWheel(
                  label: "Min",
                  values: List.generate(60, (i) => i),
                  selected: _selected.minute,
                  onSelect: _updateMinute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlobWheel({
    required String label,
    required List<int> values,
    required int selected,
    required Function(int) onSelect,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          width: 90,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.4,
            onSelectedItemChanged: onSelect,
            controller: FixedExtentScrollController(
              initialItem: values.indexOf(selected),
            ),
            physics: const BouncingScrollPhysics(),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (_, index) {
                if (index < 0 || index >= values.length) return null;

                final isSelected = values[index] == selected;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      values[index].toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: isSelected ? 24 : 18,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
