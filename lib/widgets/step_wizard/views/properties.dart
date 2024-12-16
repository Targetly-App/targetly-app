import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:targetly/helpers.dart';

import '../../list_section.dart';
import '../../list_section_tile.dart';
import '../../week_day_picker.dart';

enum StepWizardQuestionType { switcher, select, date, time, weekdays }

class StepWizardProperty {
  final String name;
  final Icon? icon;
  final StepWizardQuestionType type;
  final List<dynamic> values;
  final dynamic selectedValue;
  final String? subTitle;
  final String? dependsOn; // Name of the switcher property this depends on
  final bool
      visibleWhen; // Value of the switcher that makes this property visible

  StepWizardProperty({
    required this.name,
    this.icon,
    this.type = StepWizardQuestionType.select,
    this.values = const [],
    this.selectedValue,
    this.subTitle,
    this.dependsOn,
    this.visibleWhen = true,
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

  bool isPropertyVisible(StepWizardProperty property) {
    // If property doesn't depend on any switcher, it's always visible
    if (property.dependsOn == null) return true;

    // Find the switcher property this depends on
    final switcherProperty = properties.firstWhere(
      (p) =>
          p.name == property.dependsOn &&
          p.type == StepWizardQuestionType.switcher,
      orElse: () =>
          property, // Return the original property if dependency not found
    );

    // Show the property if the switcher value matches visibleWhen
    return switcherProperty.selectedValue == property.visibleWhen;
  }

  @override
  Widget build(BuildContext context) {
    // Filter visible properties
    final visibleProperties = properties.where(isPropertyVisible).toList();

    return ListSection(
      title: widget.title,
      children: visibleProperties.map((property) {
        return ListSectionTile(
          title: property.name,
          leading: property.icon,
          trailing: property.type == StepWizardQuestionType.switcher
              ? Switch.adaptive(
                  value: property.selectedValue,
                  onChanged: (newValue) {
                    setState(() {
                      properties = properties.map((p) {
                        if (p.name == property.name) {
                          return StepWizardProperty(
                            name: p.name,
                            icon: p.icon,
                            type: p.type,
                            values: p.values,
                            selectedValue: newValue,
                            dependsOn: p.dependsOn,
                            visibleWhen: p.visibleWhen,
                            subTitle: p.subTitle,
                          );
                        }
                        return p;
                      }).toList();
                    });
                    onPropertySelected?.call(property.name, newValue);
                  })
              : null,
          bottom: property.type == StepWizardQuestionType.weekdays
              ? WeekDayPicker(
                  onChanged: (List<int> selectedDays) {
                    setState(() {
                      properties = properties.map((p) {
                        if (p.type == StepWizardQuestionType.weekdays) {
                          return StepWizardProperty(
                            name: p.name,
                            icon: p.icon,
                            type: p.type,
                            values: p.values,
                            selectedValue: selectedDays,
                            dependsOn: p.dependsOn,
                            visibleWhen: p.visibleWhen,
                            subTitle: p.subTitle,
                          );
                        }
                        return p;
                      }).toList();
                    });
                    onPropertySelected?.call(property.name, selectedDays);
                  },
                  initialSelection: property.selectedValue,
                )
              : null,
          subtitle: ![
            StepWizardQuestionType.weekdays,
            StepWizardQuestionType.switcher
          ].contains(property.type)
              ? (property.selectedValue.toString() != 'null'
                  ? property.selectedValue.toString()
                  : 'Not set')
              : property.subTitle,
          onTap: ![
            StepWizardQuestionType.weekdays,
            StepWizardQuestionType.switcher
          ].contains(property.type)
              ? () {
                  switch (property.type) {
                    case StepWizardQuestionType.select:
                      _showPicker(context, property.name, property.values);
                      break;
                    case StepWizardQuestionType.date:
                      _showDatePicker(context, property.name);
                      break;
                    case StepWizardQuestionType.time:
                      _showTimePicker(context, property.name);
                      break;
                    case StepWizardQuestionType.weekdays:
                    case StepWizardQuestionType.switcher:
                      break;
                  }
                }
              : null,
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
                                icon: property.icon,
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

  void _showTimePicker(BuildContext context, String propertyName) {
    // Convert "2021-01-01 10:30 AM" to DateTime
    DateFormat format = DateFormat("h:mm a");
    String? propertyTime = properties
        .firstWhere((property) => property.name == propertyName)
        .selectedValue;
    DateTime currentValue = format.parse(propertyTime ?? '8:00 AM');
    var selectedTime = currentValue;
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
                mode: CupertinoDatePickerMode.time,
                use24hFormat: false,
                minuteInterval: 30,
                initialDateTime: currentValue,
                onDateTimeChanged: (value) {
                  selectedTime = value;
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Done'),
              onPressed: () {
                // Getting date string as 'HH a'
                String time = getFormattedDate(selectedTime, format: 'h:mm a');
                setState(() {
                  properties = properties
                      .map((property) => property.name == propertyName
                          ? StepWizardProperty(
                              name: propertyName,
                              icon: property.icon,
                              type: property.type,
                              values: property.values,
                              selectedValue: time,
                            )
                          : property)
                      .toList();
                });
                onPropertySelected?.call(propertyName, time);

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
                                icon: property.icon,
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
