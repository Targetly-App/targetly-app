import 'package:flutter/material.dart';

class WeekDayPicker extends StatefulWidget {
  final Function(List<int>) onChanged;
  final List<int>? initialSelection;

  const WeekDayPicker({
    super.key,
    required this.onChanged,
    this.initialSelection,
  });

  @override
  State<WeekDayPicker> createState() => _WeekDayPickerState();
}

class _WeekDayPickerState extends State<WeekDayPicker> {
  late List<bool> _selectedDays;
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedDays = List.generate(
        7, (index) => widget.initialSelection?.contains(index) ?? false);
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDays[index] = !_selectedDays[index];
      widget.onChanged(
        _selectedDays
            .asMap()
            .entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final isSelected = _selectedDays[index];

          return SizedBox(
            width: 36,
            height: 36,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onDaySelected(index),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: theme.colorScheme.outline.withOpacity(0.12),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _weekDays[index],
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontSize: 15,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
