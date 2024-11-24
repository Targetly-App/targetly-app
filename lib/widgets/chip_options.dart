import 'package:flutter/material.dart';

class ChipOptionValue {
  final String label;
  final String value;
  final bool selected;

  ChipOptionValue({required this.label, required this.value, this.selected = false});
}

class ChipOptions extends StatefulWidget {
  final String label;
  final List<ChipOptionValue> options;
  final Function(List<String>) onSelect;

  final bool onlyOne;

  const ChipOptions({
    super.key,
    required this.label,
    required this.options,
    required this.onSelect,
    this.onlyOne = false,
  });

  @override
  State<ChipOptions> createState() => _ChipOptionsState();
}

class _ChipOptionsState extends State<ChipOptions> {
  List<String> selectedOptions = [];

  @override
  void initState() {
    // Selected options should be first
    widget.options.sort((a, b) => a.selected ? -1 : 1);

    // Set selected options
    for (var option in widget.options) {
      if (option.selected) {
        selectedOptions.add(option.value);
      }
    }
    super.initState();
  }

  selectOption(ChipOptionValue option) {
    setState(() {
      if (widget.onlyOne) {
        selectedOptions.clear();
      }
      selectedOptions.add(option.value);
    });
    widget.onSelect(selectedOptions);
  }

  deSelectOption(ChipOptionValue option) {
    setState(() {
      selectedOptions.remove(option.value);
    });
    widget.onSelect(selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // alignment: Alignment.topLeft,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: Column(
              children: [
                Wrap(
                  spacing: 8.0,
                  children: widget.options.map(
                    (option) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ChoiceChip(
                          // showCheckmark: false,
                          label: Text(option.label),
                          padding: const EdgeInsets.all(8.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          selected: selectedOptions.contains(option.value),
                          onSelected: (bool selected) {
                            selected ? selectOption(option) : deSelectOption(option);
                          },
                        ),
                      );
                    },
                  ).toList(),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
