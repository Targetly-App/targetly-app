import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../helpers.dart';
import '../models/target.dart';
import 'color_checkbox.dart';
import 'list_section.dart';
import 'list_section_tile.dart';

class TargetWidget extends StatelessWidget {
  final Target target;
  final Function()? onTap;
  final double completedPercent;

  const TargetWidget(
    this.target, {
    super.key,
    this.onTap,
    this.completedPercent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    String percent = (completedPercent * 100).toInt().toString();

    return ListSection(
      children: [
        ListSectionTile(
          onTap: onTap,
          leading: ColorCheckbox(
            progress: completedPercent,
            variant: completedPercent >= 1
                ? ColorCheckboxVariant.check
                : ColorCheckboxVariant.color,
            color: generateColorFromText(target.id!),
            checked: true,
          ),
          title: target.title,
          subtitle: "$percent% done",
        ),
      ],
    );
  }
}
