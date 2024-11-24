import 'package:flutter/cupertino.dart';
import 'package:targetly/helpers.dart';

import '../../list_section.dart';
import '../../list_section_tile.dart';

enum StepWizardQuestionType { select, date }

class StepWizardProperty {
  final String name;
  final StepWizardQuestionType type;
  final List<dynamic> values;
  final dynamic selectedValue;

  StepWizardProperty({
    required this.name,
    this.type = StepWizardQuestionType.select,
    this.values = const [],
    this.selectedValue,
  });
}

class StepWizardPropertiesView extends StatefulWidget {
  final String? title;
  final List<StepWizardProperty> properties;
  final Function(String, dynamic)? onPropertySelected;

  const StepWizardPropertiesView({
    super.key,
    this.title,
    required this.properties,
    this.onPropertySelected,
  });

  @override
  _StepWizardPropertiesViewState createState() =>
      _StepWizardPropertiesViewState();
}

class _StepWizardPropertiesViewState extends State<StepWizardPropertiesView> {
  List<StepWizardProperty> properties = [];
  Function(String, dynamic)? get onPropertySelected =>
      widget.onPropertySelected;

  @override
  void initState() {
    properties = widget.properties;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListSection(
      title: widget.title,
      children: properties.map((property) {
        return ListSectionTile(
          title: property.name,
          subtitle: property.selectedValue.toString() != 'null'
              ? property.selectedValue.toString()
              : 'Not set',
          onTap: () {
            switch (property.type) {
              case StepWizardQuestionType.select:
                _showPicker(context, property.name, property.values);
                break;
              case StepWizardQuestionType.date:
                _showDatePicker(context, property.name);
                break;
            }
          },
        );
      }).toList(),
    );
  }

  void _showPicker(
      BuildContext context, String propertyName, List<dynamic> values) {
    FixedExtentScrollController scrollController = FixedExtentScrollController(
        initialItem: values.indexOf(properties
            .firstWhere((property) => property.name == propertyName)
            .selectedValue));
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: CupertinoColors.darkBackgroundGray,
        height: 270,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController: scrollController,
                itemExtent: 32.0,
                children: [
                  for (dynamic value in values) Text(value.toString()),
                ],
                onSelectedItemChanged: (int index) {
                  var value = values[index];
                  setState(() {
                    properties = properties
                        .map((property) => property.name == propertyName
                            ? StepWizardProperty(
                                name: propertyName,
                                type: property.type,
                                values: property.values,
                                selectedValue: value,
                              )
                            : property)
                        .toList();
                  });
                  onPropertySelected?.call(propertyName, value);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, String propertyName) {
    String? initialDate = properties
        .firstWhere((property) => property.name == propertyName)
        .selectedValue;
    DateTime initialDateTime;
    DateTime minimumDate = DateTime.now();
    if (initialDate == null) {
      initialDateTime = DateTime.now();
    } else {
      initialDateTime = getDateTimeFromString(initialDate);
      if (initialDateTime.isBefore(DateTime.now())) {
        minimumDate = initialDateTime;
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: CupertinoColors.darkBackgroundGray,
        height: 270,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                minimumDate: minimumDate,
                initialDateTime: initialDateTime,
                onDateTimeChanged: (DateTime value) {
                  setState(() {
                    // Format date to better for user understanding
                    String formattedDate = getFormattedDate(value);
                    properties = properties
                        .map((property) => property.name == propertyName
                            ? StepWizardProperty(
                                name: propertyName,
                                type: property.type,
                                values: property.values,
                                selectedValue: formattedDate,
                              )
                            : property)
                        .toList();
                  });
                  onPropertySelected?.call(propertyName, value);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
