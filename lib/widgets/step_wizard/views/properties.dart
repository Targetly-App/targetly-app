import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:targetly/helpers.dart';

import '../../list_section.dart';
import '../../list_section_tile.dart';
import '../../week_day_picker.dart';

enum StepWizardQuestionType { switcher, select, date, time, weekdays }

// Define dependency condition
class DependencyCondition {
  final String propertyName;
  final dynamic visibleWhen;

  const DependencyCondition({
    required this.propertyName,
    required this.visibleWhen,
  });
}

class StepWizardProperty {
  final String name;
  final Icon? icon;
  final StepWizardQuestionType type;
  final List<dynamic> values;
  final dynamic selectedValue;
  final String? subTitle;
  final List<DependencyCondition> dependencies;
  final bool matchAll;

  StepWizardProperty({
    required this.name,
    this.icon,
    this.type = StepWizardQuestionType.select,
    this.values = const [],
    this.selectedValue,
    this.subTitle,
    this.dependencies = const [],
    this.matchAll = true,
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
    // If property has no dependencies, it's always visible
    if (property.dependencies.isEmpty) return true;

    List<bool> conditionResults = property.dependencies.map((dependency) {
      // Find the dependent property by name (now works with any type)
      final dependentProperty = properties.firstWhere(
        (p) => p.name == dependency.propertyName,
        orElse: () => property,
      );

      // Compare the dependent property's selected value with the required value
      // If visibleWhen is function, call it
      if (dependency.visibleWhen is Function) {
        return (dependency.visibleWhen
            as Function)(dependentProperty.selectedValue) as bool;
      }

      return dependentProperty.selectedValue == dependency.visibleWhen;
    }).toList();

    // If matchAll is true, all conditions must be met (AND)
    // If matchAll is false, any condition can be met (OR)
    return property.matchAll
        ? conditionResults.every((result) => result)
        : conditionResults.any((result) => result);
  }

  @override
  Widget build(BuildContext context) {
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
                            dependencies: p.dependencies,
                            matchAll: p.matchAll,
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
                        if (p.name == property.name) {
                          return StepWizardProperty(
                            name: p.name,
                            icon: p.icon,
                            type: p.type,
                            values: p.values,
                            selectedValue: selectedDays,
                            dependencies: p.dependencies,
                            matchAll: p.matchAll,
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
                    properties = properties.map((p) {
                      if (p.name == propertyName) {
                        return StepWizardProperty(
                          name: propertyName,
                          icon: p.icon,
                          type: p.type,
                          values: p.values,
                          selectedValue: value,
                          dependencies: p.dependencies,
                          matchAll: p.matchAll,
                          subTitle: p.subTitle,
                        );
                      }
                      return p;
                    }).toList();
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
    final property =
        properties.firstWhere((property) => property.name == propertyName);
    String? propertyTime = property.selectedValue;
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
                  properties = properties.map((p) {
                    if (p.name == propertyName) {
                      return StepWizardProperty(
                        name: propertyName,
                        icon: p.icon,
                        type: p.type,
                        values: p.values,
                        selectedValue: time,
                        dependencies: p.dependencies,
                        matchAll: p.matchAll,
                        subTitle: p.subTitle,
                      );
                    }
                    return p;
                  }).toList();
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
    final property =
        properties.firstWhere((property) => property.name == propertyName);
    String? initialDate = property.selectedValue;
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
                    properties = properties.map((p) {
                      if (p.name == propertyName) {
                        return StepWizardProperty(
                          name: propertyName,
                          icon: p.icon,
                          type: p.type,
                          values: p.values,
                          selectedValue: formattedDate,
                          dependencies: p.dependencies,
                          matchAll: p.matchAll,
                          subTitle: p.subTitle,
                        );
                      }
                      return p;
                    }).toList();
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
